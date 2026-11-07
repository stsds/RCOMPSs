#!/usr/bin/env python3
"""Measure fresh-process wall time, summed PSS and per-device GPU memory.

Worker processes may be launched through ssh, so ancestry alone is insufficient.
An inherited per-case environment token also identifies COMPSs workers. Only
processes owned by this uid are inspected. PSS is sampled every0.5s and NVML
device memory every0.05s target interval (plus query overhead).
"""
import argparse, csv, json, os, pathlib, subprocess, time

p=argparse.ArgumentParser()
p.add_argument('--output',required=True)
p.add_argument('--token',required=True)
p.add_argument('command',nargs=argparse.REMAINDER)
a=p.parse_args();command=a.command
if command and command[0]=='--':command=command[1:]
if not command:raise SystemExit('missing command')
env=os.environ.copy();env['CAMPAIGN_CASE']=a.token
nv=None;devices=[]
try:
    import pynvml as nv
    nv.nvmlInit()
    devices=[nv.nvmlDeviceGetHandleByIndex(i) for i in range(nv.nvmlDeviceGetCount())]
except Exception as error:
    nv=None
    if env.get('CAMPAIGN_REQUIRE_NVML')=='1':raise RuntimeError('NVML initialization required') from error
base=pathlib.Path(a.output);base.parent.mkdir(parents=True,exist_ok=True)
start=time.monotonic();proc=subprocess.Popen(command,env=env)
uid=os.getuid();known={proc.pid};peak_pss=0;gpu_peaks={};samples=0;gpu_peak_total=0
marker=('CAMPAIGN_CASE='+a.token).encode()

def process_memory():
    total=0;live=set()
    for d in pathlib.Path('/proc').iterdir():
        if not d.name.isdigit():continue
        try:
            pid=int(d.name)
            if pid==os.getpid() or d.stat().st_uid!=uid:continue
            if pid not in known:
                if marker not in (d/'environ').read_bytes().split(b'\0'):continue
                known.add(pid)
            live.add(pid)
            for line in (d/'smaps_rollup').read_text().splitlines():
                if line.startswith('Pss:'):total+=int(line.split()[1])*1024;break
        except (OSError,ValueError):continue
    return total,live

pss=0;last_host=-1;live=set()
with base.with_suffix('.samples.csv').open('w') as f:
    w=csv.writer(f);w.writerow(['elapsed','host_pss_bytes','host_sampled','gpu_uuid','gpu_bytes'])
    while True:
        now=time.monotonic();host_sampled=last_host<0 or now-last_host>=.5
        if host_sampled:
            pss,live=process_memory();peak_pss=max(peak_pss,pss);last_host=now
        per_gpu={}
        if nv:
            for device in devices:
                uuid=nv.nvmlDeviceGetUUID(device)
                if isinstance(uuid,bytes):uuid=uuid.decode()
                try:apps=nv.nvmlDeviceGetComputeRunningProcesses(device)
                except nv.NVMLError_FunctionNotFound:apps=nv.nvmlDeviceGetComputeRunningProcesses_v2(device)
                for app in apps:
                    if app.pid in known:
                        if app.usedGpuMemory is None:raise RuntimeError('NVML process memory unavailable')
                        per_gpu[uuid]=per_gpu.get(uuid,0)+int(app.usedGpuMemory)
        else:
            query=subprocess.run(['nvidia-smi','--query-compute-apps=pid,gpu_uuid,used_gpu_memory',
                                   '--format=csv,noheader,nounits'],capture_output=True,text=True)
            if query.returncode:raise RuntimeError(query.stderr)
            for fields in csv.reader(query.stdout.splitlines()):
                try:
                    pid=int(fields[0]);uuid=fields[1].strip();value=int(fields[2])*1024**2
                    if pid in known:per_gpu[uuid]=per_gpu.get(uuid,0)+value
                except (ValueError,IndexError):continue
        elapsed=time.monotonic()-start
        gpu_peak_total=max(gpu_peak_total,sum(per_gpu.values()))
        if per_gpu:
            for uuid,value in per_gpu.items():
                gpu_peaks[uuid]=max(gpu_peaks.get(uuid,0),value)
                w.writerow([elapsed,pss,host_sampled,uuid,value])
        else:w.writerow([elapsed,pss,host_sampled,'',0])
        f.flush();samples+=1
        if proc.poll() is not None:break
        time.sleep(.05 if nv else .5)
code=proc.wait()
base.with_suffix('.json').write_text(json.dumps(dict(command=command,returncode=code,
    wall_seconds=time.monotonic()-start,host_peak_pss_bytes=peak_pss,
    gpu_peak_bytes=gpu_peaks,gpu_peak_total_bytes=gpu_peak_total,
    observed_pids=sorted(known),
    code_hash=env.get('CAMPAIGN_CODE_HASH'),
    host_interval_seconds=.5,gpu_target_interval_seconds=.05 if nv else .5,
    gpu_backend='NVML' if nv else 'CLI test fallback',samples=samples),indent=2)+'\n')
raise SystemExit(code)
