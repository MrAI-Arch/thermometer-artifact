#!/usr/bin/env python3
"""Exercise policy chain, memory hierarchy, stores, and default DDR4 rate."""
import gzip, json, os, pathlib, re, struct, subprocess, sys
repo = pathlib.Path(__file__).resolve().parents[1]
root = repo / 'runs/smoke-lion-cove'
subprocess.run([sys.executable, str(repo/'scripts/smoke_xeon6.py'),
    '--configs', 'lion_cove_ddr4', '--build-dir', 'build-lion-cove',
    '--run-dir', str(root)], check=True)
exe = repo/'build-lion-cove/ChampSim_lion_cove_ddr4_lru'
record = struct.Struct('<Q8B6Q')  # input_instr layout on the x86-64 build host
assert record.size == 64
results = []
for name, lines, stores in [('l0-resident',256,False), ('l1-resident',2048,False),
                            ('l2-resident',8192,False), ('dram-stream',131072,False),
                            ('dirty-evictions',8192,True)]:
    data = root/name
    (data/'btb_record_insert_taken').mkdir(parents=True, exist_ok=True)
    trace = data/'memory.champsimtrace.gz'
    with gzip.open(trace,'wb') as f:
        for n in range(250000):
            address = 0x10000000 + (n % lines)*64
            f.write(record.pack(0x400000+(n%256)*4,0,0,0,0,0,0,0,0,
                address if stores else 0,0,0 if stores else address,0,0,0))
    env = dict(os.environ, THERMOMETER_DATA_ROOT=str(data))
    cmd = [str(exe),'--warmup_instructions','20000','--simulation_instructions','180000',
           '--hide_heartbeat','-traces',str(trace)] # Deliberately NO --high_bandwidth, NO --pt
    # The artifact requires access records even for LRU on binary traces.
    generate_cmd = list(cmd)
    generate_cmd[0] = str(repo/'build-lion-cove/ChampSim_lion_cove_ddr4_opt_generate')
    with (data/'opt_generate.log').open('w') as f:
        subprocess.run(generate_cmd,cwd=repo,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=180,check=True)
    log = data/'lru.log'
    with log.open('w') as f:
        proc = subprocess.run(cmd,cwd=repo,env=env,stdout=f,stderr=subprocess.STDOUT,timeout=180)
    text = log.read_text()
    assert proc.returncode == 0 and 'Finished CPU 0' in text, (name,proc.returncode,text[-2000:])
    assert 'Data Rate: 3200 MT/s' in text, name
    assert 'DRAM tRP/tRCD/tCAS cycles: 40/40/40 Burst cycles: 8' in text, name
    stats = {}
    for cache in ['L0D','L1D_MID','L2C','LLC']:
        m = re.search(r'^'+cache+r' TOTAL\s+ACCESS:\s+(\d+)\s+HIT:\s+(\d+)\s+MISS:\s+(\d+)',text,re.M)
        assert m, (name,cache)
        stats[cache] = dict(zip(['access','hit','miss'], map(int,m.groups())))
    if name == 'l0-resident':
        assert stats['L0D']['hit'] > stats['L0D']['miss'], stats
    if name == 'l1-resident':
        assert stats['L0D']['miss'] > 1000 and stats['L1D_MID']['hit'] > stats['L1D_MID']['miss'], stats
    if name == 'l2-resident':
        assert stats['L1D_MID']['miss'] > 1000 and stats['L2C']['hit'] > stats['L2C']['miss'], stats
    if name == 'dram-stream':
        assert stats['LLC']['miss'] > 50000, stats
    if stores:
        for cache in ['L1D_MID','L2C']:
            m = re.search(r'^'+cache+r' WRITEBACK ACCESS:\s+(\d+)',text,re.M)
            assert m and int(m.group(1)) > 1000, (name,cache)
    results.append(dict(case=name,stats=stats,log=str(log)))
    print('PASS memory/'+name,flush=True)
(root/'memory-summary.json').write_text(json.dumps(results,indent=2)+'\n')
