#!/usr/bin/env python3
"""Synthetic PT smoke only; verifies executable/data flow, not CPU accuracy."""
import argparse, gzip, json, os, pathlib, re, struct, subprocess
repo = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--configs", nargs="+", default=["fdip", "xeon6_granite_rapids"])
parser.add_argument("--build-dir", default="build-xeon6")
parser.add_argument("--run-dir", default="runs/smoke")
args = parser.parse_args()
root = repo / args.run_dir
trace = root / "synthetic" / "trace.gz"
trace.parent.mkdir(parents=True, exist_ok=True)
with gzip.open(trace, "wt") as f:
    for k in range(12000):
        j = k % 128
        pc = 0x400000 + j * 64
        for off in range(4):
            f.write(f"{pc+off:x} 1 90\n")
        target = 0x400000 + ((j+1) % 128)*64
        data = b"\xe9" + struct.pack("<i", target-(pc+9))
        f.write(f"{pc+4:x} 5 " + " ".join(f"{b:02x}" for b in data) + "\n")
results=[]
for config in args.configs:
    data = root / config
    (data / "btb_record_insert_taken").mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["THERMOMETER_DATA_ROOT"] = str(data)
    for target in ["opt_generate", "lru", "opt", "hot_warm_cold_80_50_f_keep_curr_hotter_lru"]:
        exe = repo / args.build_dir / f"ChampSim_{config}_{target}"
        cmd = [str(exe), "--warmup_instructions", "5000", "--simulation_instructions", "20000",
               "--hide_heartbeat", "--high_bandwidth", "--pt", "--total_btb_entries", "8192",
               "--total_btb_ways", "4", "-traces", str(trace)]
        log = data / f"{target}.log"
        with log.open("w") as f:
            proc = subprocess.run(cmd, cwd=repo, env=env, stdout=f, stderr=subprocess.STDOUT, timeout=120)
        text=log.read_text()
        if proc.returncode or "Finished CPU 0" not in text:
            raise RuntimeError(f"Failed {config}/{target}: {proc.returncode}; see {log}\n{text[-2000:]}")
        ipc=re.search(r"CPU 0 cumulative IPC: ([0-9.]+)",text)
        results.append(dict(config=config,target=target,returncode=proc.returncode,ipc=ipc.group(1) if ipc else None,log=str(log)))
        print(f"PASS {config}/{target}",flush=True)
(root / "summary.json").write_text(json.dumps(results,indent=2)+"\n")
