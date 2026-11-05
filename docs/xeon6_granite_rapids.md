# Xeon 6 / Granite Rapids experiment configuration

Current requested main experiment: [Lion Cove + DDR4](lion_cove_ddr4.md). This Xeon configuration is retained as a control.

Created 2026-11-06. Upstream Thermometer: `af065f183d14bedfade969f59310fac0ecce5a12`.
Branch: `codex/xeon6-granite-rapids`. Directory: `/scratch/ningzhiai/thermometer-artifact`.

This is a **single-core, single-thread Redwood Cove-inspired configuration** of
Thermometer's abstract ChampSim model, not a cycle-accurate model of a specific
Intel SKU. The original `fdip` configuration is unchanged and is built alongside it.

## Parameters and provenance

| Parameter | Original fdip | New configuration | Basis |
|---|---:|---:|---|
| Clock | 4 GHz | 3.2 GHz | Chosen modeling point; avoids fractional legacy DRAM bus clock ratio |
| Fetch slots | 6 | 6 | Retained artifact assumption; not a disclosed Intel byte-fetch bandwidth |
| Decode slots | 6 | 6 | Retained modeling assumption; public server slide says 8, client comparison says 6; see source caveat below |
| Dispatch/allocation slots | 6 | 6 | Intel server presentation states 6-wide allocate; simulator instructions approximate uops |
| Execute slots | 6 | 6 | Abstract artifact execution throughput, not hardware issue-port count |
| Retirement slots | 5 | 8 | Redwood Cove comparison in Intel Tech Tour, slide 14 |
| ROB entries | 352 | 512 | Same Intel slide; simulator instruction entries approximate uop window |
| Decode buffer | 60 | 192 | Approximation of single-thread 192-uop IDQ in Intel manual section 2.1.1 |
| Scheduler, LQ, SQ entries | 128,128,72 | unchanged | Artifact assumptions, not claimed Intel measurements |
| Load/store issue | 2/2 | 3/2 | Aggregate throughput approximation; no execution-port model |
| I-fetch buffer | 192 instructions | unchanged | Artifact FDIP bound, not a measured Intel FTQ size |
| L1I | 32 KiB, 8 way | 64 KiB, 16 way | Capacity from Intel manual; associativity is model choice |
| L1D | 48 KiB, 12 way | unchanged | Redwood Cove capacity; 4 hit + 1 fill cycles retained |
| L2 | 512 KiB, 8 way | 2 MiB, 16 way | Capacity from Intel; associativity is model choice |
| L2 hit/fill latency | 9+1 | 15+1 | Inspired by Intel's 16-cycle L2; not an exact end-to-end latency mapping |
| L2 MSHRs | 32 | 64 | Approximation of Intel's 64 outstanding MLC misses |
| LLC | 2 MiB, 16 way | 4 MiB, 16 way | Assumed effective per-core allocation, NOT full-socket LLC |
| LLC hit/fill latency | 19+1 | 39+1 | Explicit assumption, no mesh modeled |
| Main BTB | 8192 entries, 4 way | unchanged; runtime configurable | Thermometer baseline, NOT disclosed Intel BTB organization |
| Direction predictor | TAGE-SC-L | unchanged | Research predictor, not Intel proprietary predictor |
| Indirect target table / RAS | 4096 / 32 | unchanged | Artifact assumptions |
| DIB / DRAM / data prefetchers | artifact baseline | unchanged | No claim to model Intel DSB, DDR5 socket, or Intel prefetch algorithms |

Cache line size remains 64 bytes. L1I latency remains 3 hit + 1 fill cycles.
The legacy memory model uses one channel and `DRAM_IO_FREQ=3200`; pass
`--high_bandwidth` to avoid upstream's default divide-by-four bandwidth mode.
This is intentionally not advertised as a DDR5 or 8/12-channel socket model.

Sources:
- Intel Optimization Reference Manual v050, section 2.1.1 (Redwood Cove), 2.1.1.4:
  https://cdrdv2-public.intel.com/821612/248966-Optimization-Reference-Manual-V1-050.pdf
- Intel Tech Tour 2024 Lion Cove comparison, slides 14 and 17 (previous Redwood Cove values):
  https://cdrdv2-public.intel.com/824430/2024_Intel_Tech%20Tour%20TW_Next%20Gen%20P-core%20The%20Lion%20Cove%20Architecture-4.pdf
- Original Thermometer Table 1:
  https://www.pdl.cmu.edu/ftp/associated/song-thermometer-isca-2022.pdf

### Width provenance clarification (2026-11-06)

The original summary incorrectly collapsed fetch, decode and allocation into a
single hardware width. Only the six-wide allocation has direct server-slide
support. Fetch and execution widths remain simulator assumptions.

Intel's Hot Chips 2024 Xeon 6 SoC presentation, slide 7, explicitly lists
8-wide decode, 6-wide allocate, 8-wide retire, a 512-entry window, 64/48 KiB
L1I/L1D and 2 MiB L2:
https://hc2024.hotchips.org/assets/program/conference/day1/14_HC2024.Intel.Xeon_6_SoC.Praveen.Mosur.pdf

The decode figure conflicts with the six-wide client Redwood Cove comparison.
In the September 2024 first-person interview, Intel Senior Fellow Ronak Singhal
says the client and server cores share most IP, with AMX and AVX-512 the largest
changes. He does NOT explicitly settle decode width or label the slide a typo:
https://old.chipsandcheese.com/2024/09/30/chips-and-cheese-interviews-ronak-singhal/

Therefore this configuration retains six decode slots as a documented model
choice, not a verified server hardware fact. An eight-slot decode/fetch variant
would be a useful sensitivity experiment. Do not silently label that variant
as proven Granite Rapids hardware either.

Lion Cove is a distinct generation: Intel Tech Tour slide 14 specifies 8-wide
allocation, 12-wide retirement, a 576-entry window and 18 execution ports. The
current 512-entry/6-allocation model is not a Lion Cove configuration.

The Intel manual and extracted text are saved under `/scratch/ningzhiai/thermometer-deps/`.

## Build

Dependencies are installed without root under `/scratch/ningzhiai/thermometer-deps`:
- Conda Boost C++ 1.78 environment: `env/`
- Intel XED commit `0bcb6237345c5066726dcc08b3d87928df3b5b26` (v2026.08.23)
- mbuild commit `1b437e409221a2b5703b4d8896baa20d43e4ba1a`
- XED shared install: `xed-install/`
- Host GCC 11.5, CMake 3.31.8, system zlib-devel.

```bash
cd /scratch/ningzhiai/thermometer-artifact
BUILD_JOBS=4 scripts/build_xeon6.sh
python3 scripts/smoke_xeon6.py
```

The build produces 8 binaries: two configurations (`fdip`,
`xeon6_granite_rapids`) times four policies (`opt_generate`, `lru`, `opt`,
`hot_warm_cold_80_50_f_keep_curr_hotter_lru`). Build output:
`/scratch/ningzhiai/thermometer-deps/thermometer-build.log`.

`THERMOMETER_CONFIGS` and `THERMOMETER_TARGETS` CMake filters avoid compiling the
entire upstream configuration matrix. If empty, upstream matrix behavior is retained.

## Run a PT trace

Keep separate data roots for different configurations / BTB sizes / experiments.
The artifact identifies a PT trace by its parent directory name; use distinct
parent names for distinct traces to avoid record collisions.

```bash
cd /scratch/ningzhiai/thermometer-artifact
export THERMOMETER_DATA_ROOT="$PWD/runs/gnr-8k4way-myexperiment"
mkdir -p "$THERMOMETER_DATA_ROOT/btb_record_insert_taken"
trace=/absolute/path/myapp/trace.gz
config=xeon6_granite_rapids
for policy in opt_generate lru opt hot_warm_cold_80_50_f_keep_curr_hotter_lru; do
  "build-xeon6/ChampSim_${config}_${policy}" \
    --warmup_instructions 1000000 --simulation_instructions 10000000 \
    --high_bandwidth --pt --total_btb_entries 8192 --total_btb_ways 4 \
    --train_total_btb_entries 8192 --train_total_btb_ways 4 \
    -traces "$trace" > "$THERMOMETER_DATA_ROOT/${policy}.log" 2>&1
done
```

This sequence runs the original profile-guided Thermometer on the same trace for
pipeline verification. It is NOT the train/test protocol for profile-free LLM hints.
The LLM must later get frozen hints from static code only, with separate training
programs. No LLM hint model has been integrated in this setup task.

The `THERMOMETER_DATA_ROOT` override relocates BTB access records and temperature
profiles from the author's hardcoded `/mnt/storage/shixins/champsim_pt` directory.
Without the variable, original paths are retained. Optional Twig-specific paths
remain upstream and are not part of the built targets.

## Scope of validation

The smoke script generates a deterministic synthetic x86 PT stream of NOPs and
direct jumps and runs the complete record -> LRU -> OPT -> Thermometer chain for
both configurations. Results are in `runs/smoke/summary.json` with individual logs.
These tests verify build/link/runtime/configuration plumbing, not benchmark speedup
or Intel hardware fidelity. PT traces model instruction-side cache accesses;
this reader does not supply actual data load/store addresses. For full backend
memory behavior use a suitable address-bearing trace and its reader.

FDIP, taken-branch throughput and DIB semantics remain upstream. This setup does
not add 2-taken prediction, an Intel DSB, or an exact hardware FTQ implementation.
