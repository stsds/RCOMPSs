#!/usr/bin/env python3
import csv,json,pathlib,re,statistics,sys
root=pathlib.Path(sys.argv[1]);groups={}
if not (root/'COMPLETE').exists():raise SystemExit('Campaign incomplete: no paper figures generated')
for folder in (root/'results').iterdir():
    m=re.fullmatch(r'(size|cpu)-(rcompss|parsec)-n(\d+)-g(\d+)-c(\d+)-r(\d+)',folder.name)
    if not m:continue
    study,runtime,n,g,c,trial=m.groups()
    if int(trial)==0:continue
    data=json.loads((folder/'measurement.json').read_text())
    if data['returncode']!=0:raise RuntimeError('Failed case '+folder.name)
    groups.setdefault((study,runtime,int(n),int(g),int(c)),[]).append(data)
rows=[]
for key,samples in sorted(groups.items()):
    if len(samples)!=3:raise RuntimeError('Expected3 measured repetitions: '+str(key))
    row=dict(zip(['study','runtime','n','gpus','cpus'],key))
    for metric in ['wall_seconds','host_peak_pss_bytes','gpu_peak_total_bytes']:
        values=[s[metric] for s in samples]
        row.update({metric:statistics.median(values),metric+'_min':min(values),metric+'_max':max(values)})
    row['max_device_peak_bytes']=statistics.median(max(s['gpu_peak_bytes'].values(),default=0) for s in samples)
    row['repetitions']=3;rows.append(row)
with (root/'summary.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=rows[0],lineterminator='\n');w.writeheader();w.writerows(rows)
