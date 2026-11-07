#!/usr/bin/env python3
import csv,json,re,statistics,sys
from pathlib import Path
root=Path(sys.argv[1]);assert (root/'COMPLETE').exists(),'Campaign not complete'
plan=json.loads((root/'plan.json').read_text());rows=[];hashes=set()
for n in plan['sizes']:
 for runtime,g in [('rcompss',1),('rcompss',2),('parsec',1),('parsec',2),('mkl',0)]:
  for trial in range(4):
   case=root/'results'/f'size-{runtime}-n{n}-g{g}-c40-r{trial}'
   meta=json.loads((case/'measurement.json').read_text());assert meta['returncode']==0
   hashes.add(meta['code_hash']);active=g;error=''
   if runtime=='rcompss':
    z=list(csv.DictReader((case/'timing.csv').open()))[0]
    error=float(z['max_error']);assert error<1e-10 and int(z['gpus'])==g
   elif runtime=='parsec':
    usage=json.loads((case/'gpu-usage.json').read_text());assert len(usage['reported'])==g;active=len(usage['active'])
   else:
    log=(case/'stdout.log').read_text();match=re.search(r'n,operation_seconds,error,threads\n([^\n]+)',log)
    assert match;error=float(match[1].split(',')[2]);assert error<1e-10
   rows.append(dict(runtime=runtime,n=n,gpus=g,cpus=40,trial=trial,measured=trial>0,wall_seconds=meta['wall_seconds'],active_gpus=active,sampled_error=error,host_pss_bytes=meta['host_peak_pss_bytes'],gpu_peak_bytes=meta['gpu_peak_total_bytes']))
assert len(hashes)==1,'Mixed measurement code'
out=root/'figures';out.mkdir(exist_ok=True)
with (out/'rooster_v100_gemm_raw.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
summary=[]
for n in plan['sizes']:
 for runtime,g in [('rcompss',1),('rcompss',2),('parsec',1),('parsec',2),('mkl',0)]:
  selected=[x for x in rows if x['n']==n and x['runtime']==runtime and x['gpus']==g and x['measured']]
  assert len(selected)==3
  times=[x['wall_seconds'] for x in selected]
  summary.append(dict(runtime=runtime,n=n,gpus=g,median=statistics.median(times),minimum=min(times),maximum=max(times),active_min=min(x['active_gpus'] for x in selected)))
with (out/'rooster_v100_gemm_summary.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=summary[0].keys());w.writeheader();w.writerows(summary)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':9,'pdf.fonttype':42})
fig,axes=plt.subplots(1,2,figsize=(7.2,3.2),sharey=True,layout='constrained')
for ax,g in zip(axes,[1,2]):
 for runtime,label,color,marker in [('rcompss','RCOMPSs','#0072B2','o'),('parsec','PaRSEC','#D55E00','s'),('mkl','MKL (CPU only, 40 threads)','#444444','^')]:
  z=[x for x in summary if x['runtime']==runtime and x['gpus']==(0 if runtime=='mkl' else g)]
  ax.errorbar([x['n']/1000 for x in z],[x['median'] for x in z],yerr=[[x['median']-x['minimum'] for x in z],[x['maximum']-x['median'] for x in z]],label=label,color=color,marker=marker,capsize=3,lw=1.3,ms=4)
  for x in z:
   if runtime!='mkl' and x['active_min']<g:ax.annotate(f"{x['active_min']}/{g} active",(x['n']/1000,x['median']),xytext=(0,7),textcoords='offset points',fontsize=6)
 ax.set_title(f'({"a" if g==1 else "b"}) {g} V100 GPU'+('s' if g>1 else '')+' + 40 CPU cores')
 ax.set_xlabel('Matrix order N (thousands)');ax.grid(axis='y',alpha=.25);ax.set_ylim(bottom=0)
axes[0].set_ylabel('Fresh-process completion time (s)')
handles,labels=axes[0].get_legend_handles_labels();fig.legend(handles,labels,loc='outside lower center',ncol=3,frameon=False,fontsize=8)
fig.savefig(out/'rooster_v100_gemm_sizes.pdf');fig.savefig(out/'rooster_v100_gemm_sizes.png',dpi=180)
(root/'FIGURE_READY').write_text('All cases audited for repetition counts, exit status, code hash, sample errors and GPU reporting. Visual and paper review still required.\n')
