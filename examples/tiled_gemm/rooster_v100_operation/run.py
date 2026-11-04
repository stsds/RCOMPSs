import campaign as c
import csv,json,statistics,os,pathlib,subprocess,hashlib
r=c.ROOT
c.BASE['CAMPAIGN_CODE_HASH']=hashlib.sha256((c.BASE['CAMPAIGN_CODE_HASH']+(r/'run.py').read_text()+(r/'mkl.cpp').read_text()+(r/'prepare_helpers.R').read_text()).encode()).hexdigest()
# Refuse accidental use of the RTX or a different host.
assert os.uname().nodename=='rooster' and c.ALLOC==['1','2']
(r/'hardware.txt').write_text(subprocess.check_output(['nvidia-smi','--query-gpu=index,name,uuid,memory.total,driver_version','--format=csv'],text=True))
c.rcase('binding-preflight',512,4,2,'probe')
# Full-output R validation and PaRSEC's numerical checker precede timings.
c.rcase('small-full-check',128,4,1,rates=(0,1))
for g in [1,2]:
 env=c.BASE.copy();env['CUDA_VISIBLE_DEVICES']=','.join(c.ALLOC[:g]);env['LD_PRELOAD']='/lib/x86_64-linux-gnu/libopenblas.so.0'
 with (r/f'parsec-check-g{g}.log').open('w') as f:
  subprocess.run(['timeout','300',c.PARSEC,'-N','2048','-t','512','-T','512','-c','40','-g',str(g),'-x'],env=env,stdout=f,stderr=subprocess.STDOUT,check=True)
cal=c.rcase('calibration',8192,2,1,'calibrate')
rows=list(csv.DictReader((cal/'timing.csv').open()))[2:]
rates=tuple(statistics.median(float(x['flops'])/float(x['body_seconds']) for x in rows if (x['gpu']=='TRUE')==gpu) for gpu in [False,True])
(r/'calibration.json').write_text(json.dumps(rates))
sizes=[4096,8192,16384,24576,32768,40000]
(r/'plan.json').write_text(json.dumps(dict(sizes=sizes,gpus=[1,2],cores=40,trials=[0,1,2,3],primary='GEMM operation on prepared host inputs through full host output; scheduling, packing and transfers included; validation excluded',mkl='CPU-only 40 threads',validation='full small R check; sampled R/MKL production checks; PaRSEC small numerical preflight only'),indent=2))
for n in sizes:
 for trial in range(4):
  actions=[('rcompss',g) for g in [1,2]]+[('parsec',g) for g in [1,2]]+[('mkl',0)]
  if trial%2:actions.reverse()
  for runtime,g in actions:
   name=f'size-{runtime}-n{n}-g{g}-c40-r{trial}'
   print(name,flush=True)
   if runtime=='rcompss':c.rcase(name,n,40,g,rates=rates)
   elif runtime=='parsec':c.pcase(name,n,40,g)
   else:
    folder=c.RESULTS/name;folder.mkdir(exist_ok=True)
    env=c.BASE.copy();env.update(CAMPAIGN_CASE=name,CUDA_VISIBLE_DEVICES='',MKL_NUM_THREADS='40',OMP_NUM_THREADS='40',MKL_DYNAMIC='FALSE')
    env.pop('LD_PRELOAD',None)
    c.measure(folder,name,['taskset','-c',','.join(map(str,c.CPUS)),str(r/'mkl_gemm'),str(n)],env)
(r/'COMPLETE').write_text('All planned processes exited successfully. Audit before paper publication.\n')
