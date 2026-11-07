import csv,json,re,collections,sys
from pathlib import Path
root=Path(sys.argv[1]); hashes=set();counts=collections.Counter();maxerr=0;device_sets=set()
for case in sorted((root/'results').glob('size-*')):
 m=json.loads((case/'measurement.json').read_text());assert m['returncode']==0;hashes.add(m['code_hash']);counts[case.name.split('-')[1]]+=1
 assert m['wall_seconds']>0 and m['host_peak_pss_bytes']>0
 assert 'has failed' not in (case/'stdout.log').read_text()
 if '-rcompss-' in case.name:
  t=list(csv.DictReader((case/'timing.csv').open()))[0]; n=int(t['n']);g=int(t['gpus'])
  tasks=list(csv.DictReader((case/'timing.csv-tasks.csv').open()));assert len(tasks)==int(t['tasks'])
  assert sum(int(float(x['flops'])) for x in tasks)==2*n**3
  assert sum(int(x['rows'])*int(x['cols']) for x in tasks)==n*n
  # Each output column strip has exactly one nonoverlapping cover of rows.
  strips=collections.defaultdict(list)
  for x in tasks:strips[(int(x['col']),int(x['cols']))].append((int(x['row']),int(x['rows'])))
  # CPU/GPU column partitions can differ; verify arbitrary rectangles by sweep.
  cuts=sorted({0,n}|{int(x['col']) for x in tasks}|{int(x['col'])+int(x['cols']) for x in tasks})
  for left,right in zip(cuts,cuts[1:]):
   intervals=sorted((int(x['row']),int(x['rows'])) for x in tasks if int(x['col'])<=left and int(x['col'])+int(x['cols'])>=right)
   pos=0
   for start,size in intervals:assert start==pos;pos+=size
   assert pos==n
  bus={x['bus'] for x in tasks if x['gpu']=='TRUE'};assert len(bus)==g;device_sets.add(tuple(sorted(bus)))
  for x in tasks:
   assert set(map(int,x['cpu_mask'].split(';'))).issubset(set(range(40)))
   maxerr=max(maxerr,float(x['error']));assert float(x['error'])<1e-10
  assert float(t['operation_seconds'])<m['wall_seconds']
 elif '-parsec-' in case.name:
  u=json.loads((case/'gpu-usage.json').read_text());g=int(re.search('-g([12])-',case.name)[1]);assert len(u['reported'])==len(u['active'])==g
for g in (1,2):
 s=(root/f'parsec-check-g{g}.log').read_text();assert s.count('PASSED')==4 and 'FAILED' not in s
s=json.loads((root/'results/small-full-check/measurement.json').read_text());assert s['returncode']==0
for k in (1,2,3):
 rows=list(csv.DictReader((root/f'results/binding-preflight/timing.csv-{k}.csv').open()));assert len({x['bus'] for x in rows})==2
assert len(hashes)==1 and counts=={'rcompss':48,'parsec':48,'mkl':24}
result=dict(cases=dict(counts),code_hash=next(iter(hashes)),max_R_sample_error=maxerr,GPU_bus_sets=[list(x) for x in sorted(device_sets)],audit='120 cases, warmup plus three measured repetitions; no retries; complete disjoint R output cover; configured GPUs participated; physical CPU masks <=39; small numerical/binding gates passed. PaRSEC production lacks independent numerical validation. PSS includes shared prepared inputs, not sum of process RSS.')
(root/'audit.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
