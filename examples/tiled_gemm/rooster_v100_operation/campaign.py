#!/usr/bin/env python3
"""Single-node campaign. Primary comparison is prepared-input GEMM operation time.

Fail closed on binding/correctness errors. Resume skips only successful cases.
"""
import csv, hashlib, json, os, pathlib, re, shlex, shutil, socket, statistics, subprocess, sys
from xml.etree.ElementTree import Element,SubElement,ElementTree

ROOT=pathlib.Path(os.environ['CAMPAIGN_ROOT']).resolve()
CPUS=sorted(os.sched_getaffinity(0))
REQUESTED=int(os.environ.get('SLURM_CPUS_PER_TASK',len(CPUS)))
if os.environ.get('SLURM_JOB_ID'):
    details=subprocess.check_output(['scontrol','show','job','-dd',os.environ['SLURM_JOB_ID']],text=True)
    match=re.search(r'CPU_IDs=([0-9,\-]+)',details)
    if match:
        assigned=[]
        for span in match.group(1).split(','):
            bounds=list(map(int,span.split('-')))
            assigned.extend(range(bounds[0],bounds[-1]+1))
        if not set(assigned).issubset(CPUS):raise RuntimeError('Slurm CPU IDs differ from process affinity')
        CPUS=sorted(assigned)
CPUS=CPUS[:REQUESTED]
if len(CPUS)!=REQUESTED:raise RuntimeError('Allocation CPU mask is smaller than requested')
ALLOC=os.environ.get('CUDA_VISIBLE_DEVICES','').split(',')
BASE=os.environ.copy();BASE['CAMPAIGN_GPUS']=','.join(ALLOC)
BASE['CAMPAIGN_CODE_HASH']=hashlib.sha256(b''.join((ROOT/name).read_bytes() for name in
    ['inputs.cpp','tasks.R','benchmark.R','campaign.py','measure.py','env.sh'])).hexdigest()
BASE['PKG_CPPFLAGS']='-I'+BASE['CUDA_HOME']+'/include'
BASE['PKG_LIBS']='-L'+BASE['CUDA_HOME']+'/lib64 -Wl,-rpath,'+BASE['CUDA_HOME']+'/lib64 -lcudart'
PARSEC=os.environ['PARSEC_GEMM']
RESULTS=ROOT/'results';RESULTS.mkdir(exist_ok=True)

def configure(folder,c,g,token):
    folder.mkdir(parents=True,exist_ok=True)
    old=folder/'measurement.json'
    if old.exists() and json.loads(old.read_text())['returncode']==0:return
    shutil.copy2(ROOT/'tasks.R',folder/'tasks.R')
    sockets=[socket.socket() for _ in range(3)]
    try:
        for sock in sockets:sock.bind(('',0))
        ports=[sock.getsockname()[1] for sock in sockets]
    finally:
        for sock in sockets:sock.close()
    worker_min,worker_max=sorted(ports[1:])
    (folder/'network.json').write_text(json.dumps(dict(master=ports[0],worker_min=worker_min,worker_max=worker_max)))
    script='source '+shlex.quote(str(ROOT/'env.sh'))+'\n'
    for k,v in dict(CAMPAIGN_ROOT=str(ROOT),CAMPAIGN_GPUS=','.join(ALLOC),CAMPAIGN_CASE=token,
                    PKG_CPPFLAGS=BASE['PKG_CPPFLAGS'],PKG_LIBS=BASE['PKG_LIBS'],
                    RCOMPSs_SERIALIZATION='cpp').items():script+='export '+k+'='+shlex.quote(v)+'\n'
    (folder/'worker-env.sh').write_text(script)
    project=Element('Project');master=SubElement(project,'MasterNode')
    disk=SubElement(SubElement(master,'SharedDisks'),'AttachedDisk',Name='IbexHome')
    SubElement(disk,'MountPoint').text=str(pathlib.Path.home())+'/'
    node=SubElement(project,'ComputeNode',Name=os.uname().nodename)
    SubElement(node,'InstallDir').text=BASE['COMPSS_HOME']
    SubElement(node,'WorkingDir').text=str(folder/'worker')+'/'
    SubElement(SubElement(node,'Application'),'EnvironmentScript').text=str(folder/'worker-env.sh')
    ElementTree(project).write(folder/'project.xml')
    resources=Element('ResourcesList');SubElement(resources,'SharedDisk',Name='IbexHome')
    node=SubElement(resources,'ComputeNode',Name=os.uname().nodename)
    SubElement(SubElement(node,'Processor',Name='CPUs'),'ComputingUnits').text=str(c)
    if g:
        p=SubElement(node,'Processor',Name='A100');SubElement(p,'ComputingUnits').text=str(g)
        SubElement(p,'Type').text='GPU'
    adaptor=SubElement(SubElement(node,'Adaptors'),'Adaptor',Name='es.bsc.compss.nio.master.NIOAdaptor')
    SubElement(SubElement(adaptor,'SubmissionSystem'),'Interactive')
    port_xml=SubElement(adaptor,'Ports')
    SubElement(port_xml,'MinPort').text=str(worker_min);SubElement(port_xml,'MaxPort').text=str(worker_max)
    disk=SubElement(SubElement(node,'SharedDisks'),'AttachedDisk',Name='IbexHome')
    SubElement(disk,'MountPoint').text=str(pathlib.Path.home())+'/'
    ElementTree(resources).write(folder/'resources.xml')

def measure(folder,token,command,env):
    meta=folder/'measurement.json'
    if meta.exists() and json.loads(meta.read_text())['returncode']==0:
        if json.loads(meta.read_text()).get('code_hash')!=env['CAMPAIGN_CODE_HASH']:
            raise RuntimeError('Scripts changed; preserve and archive old cases before rerunning')
        return
    with (folder/'stdout.log').open('w') as log:
        result=subprocess.run([sys.executable,str(ROOT/'measure.py'),'--output',str(folder/'measurement'),
             '--token',token,'--']+['timeout','1200']+command,cwd=folder,env=env,stdout=log,stderr=subprocess.STDOUT)
    if result.returncode:raise RuntimeError('Case failed; inspect '+str(folder/'stdout.log'))

def rcase(name,n,c,g,mode='hybrid',rates=None):
    folder=RESULTS/name;configure(folder,c,g,name)
    env=BASE.copy();env.update(CASE_N=str(n),CASE_CPUS=str(c),CASE_GPUS=str(g),CASE_MODE=mode,
        CASE_OUTPUT=str(folder/'timing.csv'),CAMPAIGN_CASE=name)
    env['CUDA_VISIBLE_DEVICES']=','.join(ALLOC) if g else ''
    if rates:env.update(CPU_RATE=str(rates[0]),GPU_RATE=str(rates[1]))
    command=['taskset','-c',','.join(map(str,CPUS[:c])),'runcompss','--lang=r',
       '--project='+str(folder/'project.xml'),'--resources='+str(folder/'resources.xml'),
       '--cpu_affinity='+'/'.join(map(str,CPUS[:c])),
       '--gpu_affinity='+('/'.join(map(str,range(g))) if g else 'disabled'),str(ROOT/'benchmark.R')]
    network=folder/'network.json'
    if network.exists():command.insert(-1,'--master_port='+str(json.loads(network.read_text())['master']))
    if name.startswith('smoke') or mode=='probe':command.insert(-1,'--keep_workingdir')
    measure(folder,name,command,env)
    if mode not in ['probe'] and not (folder/'timing.csv').exists():
        raise RuntimeError('RCOMPSs produced no validated result: '+name)
    return folder

def pcase(name,n,c,g):
    folder=RESULTS/name;folder.mkdir(exist_ok=True)
    env=BASE.copy();env['CUDA_VISIBLE_DEVICES']=','.join(ALLOC[:g]) if g else ''
    # Match R's CPU BLAS, keep each BLAS call single-threaded; task parallelism
    # belongs to the runtimes. Required MKL libraries remain available for ABI.
    env['LD_PRELOAD']='/lib/x86_64-linux-gnu/libopenblas.so.0'
    command=['taskset','-c',','.join(map(str,CPUS[:c])),PARSEC,'-N',str(n),'-t','2048',
       '-T','2048','-c',str(c),'-g',str(g),'--nruns','1','-v=3','--',
       '--mca','device_show_statistics','1','--mca','bind_threads','0']
    measure(folder,name,command,env)
    active=set();reported=set()
    if g:
        text=(folder/'stdout.log').read_text()
        observed=re.findall(r'\|\s*Dev\s+\d+\s*\|\s*(\d+).*cuda\((\d+)',text,re.I)
        reported={int(device) for kernels,device in observed}
        active={int(device) for kernels,device in observed if int(kernels)>0}
        if len(reported)!=g:raise RuntimeError('PaRSEC did not discover all configured GPUs: '+name)
    (folder/'gpu-usage.json').write_text(json.dumps(dict(configured=g,reported=sorted(reported),
                                                       active=sorted(active)),indent=2))

