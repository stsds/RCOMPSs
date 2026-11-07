#!/usr/bin/env bash
set -euo pipefail
src=$(cd "$(dirname "$0")" && pwd)
benchdir=${BENCHDIR:-$HOME/software/rcompss-20261029/tiled-gemm-20261029}
export RCOMPSS_LIBRARY=${RCOMPSS_LIBRARY:-$HOME/software/rcompss-20261029/tiled-gemm-optimization/library-after}
gpu_ordinal=${GPU_ORDINAL:-2}
shared_data=${RCOMPSS_SHARED_DATA:-1}
mkdir -p "$benchdir/logs" "$benchdir/results"
cp "$src/tasks.R" "$src/tiled_gemm.R" "$src/benchmark.R" "$benchdir/"
cat > "$benchdir/cases.csv" <<'CSV'
n,tile
2048,512
2048,1024
4096,512
4096,1024
CSV
# Generate an environment script because workers start in a separate shell.
python3 - "$benchdir" "$RCOMPSS_LIBRARY" "$shared_data" <<'PY'
import pathlib,sys,shlex
p=pathlib.Path(sys.argv[1]); library=sys.argv[2]; shared=sys.argv[3]=="1"
env='source "$HOME/software/rcompss-20261029/env.sh"\n'
env+='export R_LIBS='+shlex.quote(library)+':"$COMPSS_HOME/Bindings/RCOMPSs/user_libs"\n'
env+='export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1\nexport CUDA_DEVICE_ORDER=PCI_BUS_ID RCOMPSs_SERIALIZATION=cpp\n'
(p/'rcompss-env.sh').write_text(env)
from xml.etree.ElementTree import Element,SubElement,ElementTree
project=Element('Project');SubElement(project,'MasterNode');node=SubElement(project,'ComputeNode',Name='localhost')
SubElement(node,'InstallDir').text=str(pathlib.Path.home()/'software/rcompss-20261029/COMPSs')
SubElement(node,'WorkingDir').text=str(p/'worker')+'/' if shared else '/tmp/COMPSsWorker/'
SubElement(SubElement(node,'Application'),'EnvironmentScript').text=str(p/'rcompss-env.sh')
if shared:
 disks=SubElement(project.find('MasterNode'),'SharedDisks')
 SubElement(SubElement(disks,'AttachedDisk',Name='RoosterHome'),'MountPoint').text=str(pathlib.Path.home())+'/'
ElementTree(project).write(p/'project.xml')
for mode,cores in [('CPU',4),('GPU',1)]:
 root=Element('ResourcesList')
 if shared: SubElement(root,'SharedDisk',Name='RoosterHome')
 node=SubElement(root,'ComputeNode',Name='localhost')
 SubElement(SubElement(node,'Processor',Name='MainProcessor'),'ComputingUnits').text=str(cores)
 if mode=='GPU':
  gpu=SubElement(node,'Processor',Name='NVIDIA_GPUs');SubElement(gpu,'ComputingUnits').text='1';SubElement(gpu,'Type').text='GPU'
 adaptor=SubElement(SubElement(node,'Adaptors'),'Adaptor',Name='es.bsc.compss.nio.master.NIOAdaptor')
 SubElement(SubElement(adaptor,'SubmissionSystem'),'Interactive')
 ports=SubElement(adaptor,'Ports');SubElement(ports,'MinPort').text='44121';SubElement(ports,'MaxPort').text='44122'
 if shared:
  disks=SubElement(node,'SharedDisks')
  SubElement(SubElement(disks,'AttachedDisk',Name='RoosterHome'),'MountPoint').text=str(pathlib.Path.home())+'/'
 ElementTree(root).write(p/('resources-'+mode+'.xml'))
PY
cd "$benchdir"
source rcompss-env.sh
for mode in CPU GPU; do
 export GEMM_MODE=$mode GEMM_OUTPUT="$benchdir/results/rcompss-$mode.csv"
 if [[ $mode == CPU ]]; then
  export CUDA_VISIBLE_DEVICES=''
  taskset -c 0-3 runcompss --lang=r --project=project.xml --resources=resources-CPU.xml --keep_workingdir benchmark.R > logs/rcompss-CPU.log 2>&1
 else
  unset CUDA_VISIBLE_DEVICES
  taskset -c 0 runcompss --lang=r --project=project.xml --resources=resources-GPU.xml --gpu_affinity="$gpu_ordinal" --keep_workingdir benchmark.R > logs/rcompss-GPU.log 2>&1
 fi
done
