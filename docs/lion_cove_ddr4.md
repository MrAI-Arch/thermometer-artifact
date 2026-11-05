# Lion Cove-inspired core + classic DDR4 experiment

This is the primary configuration requested on 2026-11-06:
`cmake_configs/lion_cove_ddr4.cmake`. Repository:
`/scratch/ningzhiai/thermometer-artifact`. Original `fdip` and the previous
`xeon6_granite_rapids` configuration remain available as controls.

The combination intentionally uses a Lion Cove-inspired core with a classic
ChampSim DDR4 memory model. It is an experimental machine, not a named Intel SKU.
Single core, single hardware thread. BTB hints remain a separate experiment;
no LLM or target-program profiling dependency has been added here.

## Parameters and provenance

| Parameter | Value | Basis |
|---|---|---|
| CPU clock | 3.2 GHz | Chosen experimental point; exact CPU/DDR data-rate ratio |
| Fetch slots | 8 instructions/cycle | Simulator assumption; not hardware byte-fetch bandwidth |
| Decode / allocation | 8 / 8 instruction slots/cycle | Intel's 8-wide decode and 8-wide allocation mapped to the trace abstraction |
| Execution | 8 instruction slots/cycle | Abstract backend budget; does not model 18 heterogeneous execution ports |
| Retirement | 12 instruction slots/cycle | Intel's 12-wide retirement mapped to trace instructions |
| ROB | 576 entries | Intel's 576-entry instruction window, approximated at instruction granularity |
| Decode buffer / fetch buffer | 192 / 192 instructions | Model choices, not a verified Lion Cove IDQ/FTQ implementation |
| Scheduler / LQ / SQ | 128 / 128 / 72 | Retained artifact assumptions |
| Load / store throughput | 3 / 2 | Aggregate model; three store-address AGUs do not mean three stores/cycle |
| DTLB | 128 entries, 4 ways | Capacity from Intel slide 18; organization is a model choice |
| L1I | 64 KiB, 16 ways | Lion Cove-sized instruction cache; 64 sets, 64-byte lines |
| L0D (code object `L1D`) | 48 KiB, 12 ways | Intel's fast data-cache capacity |
| Intermediate L1D (code object `L1M`) | 192 KiB, 12 ways | Intel's intermediate data-cache capacity; 256 sets |
| Unified L2 | 3 MiB, 12 ways | Intel's 3 MiB Lion Cove option; 4096 sets chosen for this model |
| L2 MSHRs | 64 | Modeling assumption; not independently verified Lion Cove hardware |
| LLC | 4 MiB, 16 ways | Effective single-core capacity assumption |
| BTB | 8192 entries, 4 ways, adjustable | Thermometer research baseline, not Intel BTB organization |
| Direction predictor / FDIP / DIB | Artifact baseline | TAGE-SC-L and simplified frontend retained |

Primary Intel source, slides 12, 14, 17, 18:
https://cdrdv2-public.intel.com/824430/2024_Intel_Tech%20Tour%20TW_Next%20Gen%20P-core%20The%20Lion%20Cove%20Architecture-4.pdf

The Intel deck specifies 8-wide decode, 8-wide allocation, 12-wide retirement,
576 window entries and 18 execution ports. Its memory table gives 48 KiB / 192 KiB /
2.5 or 3 MiB with load-to-use latencies 4 / 9 / 17 cycles. We choose the 3 MiB
option; the simulator's cache queue delays are NOT those end-to-end load latencies.

The new optional data path is:

```
loads/stores -> L0D 48 KiB -> L1D_MID 192 KiB -> L2C 3 MiB -> LLC 4 MiB -> DDR4
instructions -> L1I 64 KiB --------------------> L2C
```

`L1M` is a physically addressed, write-back, write-allocate generic cache with
LRU replacement and no additional prefetcher. Cache request-hit/fill queue budgets
are L1I 3/1, L0D 3/1, intermediate L1D 4/1, L2 16/1, LLC 39/1 cycles. These are
serial simulator stage delays, not a claim that measured load-to-use is 4/9/17.
The intermediate stage uses the 9-4 difference to select its 4+1 budget. L2 remains
a shared instruction/data stage; a full timing calibration is outside this setup.
The extra cache has separate ROI statistics (`L1D_MID`) and propagates dirty
writebacks. Fill-depth values are expanded only when this extra cache is enabled.
Old configurations compile with the original topology and fill depths.

DIB is not an Intel DSB: this change does not implement the hardware's 12-wide
uop-cache delivery, byte alignment, uop expansion/fusion, or multi-taken prediction.
The core width parameters measure trace instructions, not exact x86 micro-ops.

## Classic DDR4 settings

| Parameter | Value |
|---|---|
| Transfer rate | DDR4-3200, 3200 MT/s |
| Channels / width | 1 / 64 bits |
| Peak transfer bandwidth | 25.6 GB/s |
| Rank / flat banks | 1 / 8 |
| Rows / columns / row size | 65536 / 128 cache lines / 8 KiB |
| Physical memory | 4 GiB; physical-page allocator also set to 4 GiB |
| Read / write queue | 64 / 64 |
| tRP / tRCD / tCAS | 12.5 / 12.5 / 12.5 ns |
| Read/write turnaround | 7.5 ns |
| At 3.2 GHz | 40 / 40 / 40 CPU cycles; 64-byte burst takes 8 CPU cycles |

These are explicitly the classic ChampSim/Thermometer flat-bank settings from
`default_config.cmake`, not a JEDEC timing-accurate DDR4 device model. Bank groups,
refresh and the full DDR command timing constraints are not added. The new config
sets `DRAM_DEFAULT_FULL_BANDWIDTH=1`, so omission of `--high_bandwidth` no longer
silently turns 3200 MT/s into 800 MT/s. Old configs keep their original default.

## Build, validate and run

```bash
cd /scratch/ningzhiai/thermometer-artifact
BUILD_JOBS=4 scripts/build_lion_cove.sh
python3 scripts/smoke_lion_cove.py
python3 scripts/check_lion_cove_width.py
```

Four binaries are under `build-lion-cove/`:
`ChampSim_lion_cove_ddr4_{opt_generate,lru,opt,hot_warm_cold_80_50_f_keep_curr_hotter_lru}`.
Dependencies remain under `/scratch/ningzhiai/thermometer-deps`; see the previous
Xeon setup document for pinned Boost/XED versions. Build log: `lion-cove-build.log`
in the dependencies directory.

Example for a PT trace (use a different data root for each experiment):

```bash
export THERMOMETER_DATA_ROOT="$PWD/runs/lion-cove-myapp-8k4way"
trace=/absolute/path/myapp/trace.gz
scripts/run_lion_cove.sh opt_generate "$trace"
scripts/run_lion_cove.sh lru "$trace"
scripts/run_lion_cove.sh opt "$trace"
scripts/run_lion_cove.sh hot_warm_cold_80_50_f_keep_curr_hotter_lru "$trace"
```

The wrapper defaults to 1M warmup / 10M measured instructions. Override with
`WARMUP_INSTRUCTIONS`, `SIMULATION_INSTRUCTIONS`, `BTB_ENTRIES`, `BTB_WAYS`.
Set `TRACE_FORMAT=champsim` for binary address-bearing traces. This artifact's LRU
also opens access records; run `opt_generate` first. PT traces are identified by
parent-directory name, so use distinct parent names for distinct traces.

The sequence above validates the original offline Thermometer pipeline. It is
not the training/testing procedure for static-only LLM hints: the LLM must get
only code/disassembly, with frozen hints and separate programs for evaluation.

## Validation

`scripts/smoke_lion_cove.py` runs the four-policy PT pipeline and five independent
address-bearing binary trace cases: 16 KiB L0-resident reads, 128 KiB intermediate
L1-resident reads, 512 KiB L2-resident reads, 8 MiB DRAM streaming, and dirty
writeback propagation. The memory cases intentionally omit `--high_bandwidth`
and check the actual reported rate and timing, plus cache hit/miss/writeback
behavior. Results and individual logs are in `runs/smoke-lion-cove/`.

`scripts/smoke_xeon6.py` retains the previous two-config, four-policy regression.
These synthetic tests validate functional wiring and basic capacity behavior;
they do not establish application speedup or cycle accuracy against a real CPU.

The separate long-basic-block PT check (`scripts/check_lion_cove_width.py`)
uses the public run wrapper and verifies that the pipeline sustains more than
7 instructions/cycle without exceeding its 8-wide allocation bound.

Validation completed 2026-11-06: four Lion Cove policy runs, five memory
cases, the long-block check (IPC 8.0), and all eight previous-control policy
runs passed. The DRAM-stream case produced 192530 LLC misses.
Machine-readable manifest: `runs/smoke-lion-cove/validation.json`.
