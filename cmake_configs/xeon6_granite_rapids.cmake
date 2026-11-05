# Single-core, single-thread Granite Rapids / Redwood Cove-inspired model.
# Sources and approximations: docs/xeon6_granite_rapids.md.
# This file is applied after default_config.cmake. Keep fdip.cmake unchanged.
include(${CMAKE_CURRENT_LIST_DIR}/fdip.cmake)

set(CPU_FREQ 3200)             # Modeling point, not a particular SKU/turbo clock
set(DECODE_BUFFER_SIZE 192)   # Approximate single-thread IDQ capacity; instructions, not uops
set(ROB_SIZE 512)             # Redwood Cove instruction window
set(FETCH_WIDTH 6)            # Simulator instruction slots; not x86 byte bandwidth
set(DECODE_WIDTH 6)           # Model choice; conflicting public decode figures documented in docs
set(DISPATCH_WIDTH 6)          # Allocation-width approximation
set(EXEC_WIDTH 6)             # Abstract execution model, not 12 execution ports
set(RETIRE_WIDTH 8)
set(LQ_WIDTH 3)               # Aggregate load-throughput approximation
set(SQ_WIDTH 2)

set(L1I_SET 64)
set(L1I_WAY 16)               # 64 KiB
set(L1I_HIT_LATENCY 3)        # Inherited modeling assumption, not a measured Xeon latency
set(L1I_FILL_LATENCY 1)
set(L1D_SET 64)
set(L1D_WAY 12)               # 48 KiB
set(L1D_HIT_LATENCY 4)
set(L1D_FILL_LATENCY 1)
set(L1D_MAX_READ 3)
set(L1D_MAX_WRITE 2)
set(L2C_SET 2048)
set(L2C_WAY 16)               # 2 MiB private L2
set(L2C_HIT_LATENCY 15)       # Local model budget: 15+1, inspired by 16-cycle L2
set(L2C_FILL_LATENCY 1)
set(L2C_MAX_READ 2)
set(L2C_MSHR_SIZE 64)         # Redwood Cove outstanding MLC miss capacity
set(LLC_SET 4096)
set(LLC_WAY 16)               # 4 MiB effective per-core allocation, NOT entire socket
set(LLC_HIT_LATENCY 39)       # Assumed; mesh/slice latency not explicitly modeled
set(LLC_FILL_LATENCY 1)

# Keep queue sizes, BTB/FDIP, DIB and legacy DRAM model at artifact baseline.
# BTB capacity/ways remain runtime flags (--total_btb_entries/--total_btb_ways).
# Deliberately do not equate this old DRAM controller with a DDR5 socket model.
