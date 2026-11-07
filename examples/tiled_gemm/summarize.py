import csv,re,pathlib,statistics,sys
root=pathlib.Path(sys.argv[1]).resolve() if len(sys.argv)>1 else pathlib.Path(__file__).resolve().parent
out=[]
for mode in ('CPU','GPU'):
 for n in (2048,4096):
  for tile in (512,1024):
   f=root/'logs'/f'parsec-{mode}-{n}-{tile}.log'
   text=f.read_text()
   times=re.findall(r'TIME\(s\)\s+([\d.]+).*?ENQ&PROG&DEST\s+([\d.]+)',text)
   assert len(times)==4,(f,len(times))
   for trial,(progress,total) in enumerate(times):
    out.append(dict(runtime='PaRSEC/DPLASMA',mode=mode,n=n,tile=tile,trial=trial,seconds=float(total),progress_seconds=float(progress),gflops=2*n**3/float(total)/1e9))
with (root/'results'/'parsec.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=out[0]);w.writeheader();w.writerows(out)
rows=out[:]
for mode in ('CPU','GPU'):
 rows+=list(csv.DictReader((root/'results'/f'rcompss-{mode}.csv').open()))
summary=[]
for mode in ('CPU','GPU'):
 for n in (2048,4096):
  for tile in (512,1024):
   entry=dict(mode=mode,n=n,tile=tile)
   for runtime,key in [('RCOMPSs','rcompss'),('PaRSEC/DPLASMA','parsec')]:
    ts=[float(r['seconds']) for r in rows if r['runtime']==runtime and r['mode']==mode and int(r['n'])==n and int(r['tile'])==tile and int(r['trial'])>0]
    assert len(ts)==3
    entry[key+'_median_seconds']=statistics.median(ts)
    entry[key+'_min_seconds']=min(ts)
    entry[key+'_max_seconds']=max(ts)
   entry['rcompss_over_parsec']=entry['rcompss_median_seconds']/entry['parsec_median_seconds']
   summary.append(entry)
with (root/'results'/'comparison.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=summary[0]);w.writeheader();w.writerows(summary)
for r in summary: print(r)
