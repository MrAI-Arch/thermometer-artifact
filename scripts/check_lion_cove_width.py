#!/usr/bin/env python3
"""Check sustained width on long basic blocks using the public run wrapper."""
import gzip, json, os, pathlib, re, struct, subprocess
repo=pathlib.Path(__file__).resolve().parents[1]
data=repo/'runs/smoke-lion-cove/wide-block'
data.mkdir(parents=True,exist_ok=True)
trace=data/'trace.gz'
base=0x500000
with gzip.open(trace,'wt') as f:
    for _ in range(250):
        for n in range(1023):
            f.write(f'{base+n:x} 1 90\n')
        op=b'\xe9'+struct.pack('<i',-1028)
        f.write(f'{base+1023:x} 5 '+' '.join(f'{x:02x}' for x in op)+'\n')
env=dict(os.environ,THERMOMETER_DATA_ROOT=str(data),WARMUP_INSTRUCTIONS='20000',SIMULATION_INSTRUCTIONS='180000')
for policy in ['opt_generate','lru']:
    with (data/f'{policy}.log').open('w') as f:
        subprocess.run([str(repo/'scripts/run_lion_cove.sh'),policy,str(trace),'--hide_heartbeat'],
                       cwd=repo,env=env,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=120)
text=(data/'lru.log').read_text()
m=re.search(r'CPU 0 cumulative IPC: ([0-9.]+)',text)
assert m and 7.0<float(m.group(1))<=8.1, text[-2500:]
(data/'summary.json').write_text(json.dumps(dict(ipc=float(m.group(1)),log=str(data/'lru.log')),indent=2)+'\n')
print('PASS long-block 8-wide throughput: IPC '+m.group(1))
