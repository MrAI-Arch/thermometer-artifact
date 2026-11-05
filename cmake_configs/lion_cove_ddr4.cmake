# Single-core Lion Cove-inspired research model with classic ChampSim DDR4.
# Parameter provenance and remaining abstractions: docs/lion_cove_ddr4.md.
include(${CMAKE_CURRENT_LIST_DIR}/fdip.cmake)
set(CPU_FREQ 3200)                # Experimental operating point; exact DRAM ratio
set(FETCH_WIDTH 8)                # Instruction slots, not 64-byte hardware fetch
set(DECODE_WIDTH 8)               # Hardware decoder width mapped to instructions
set(DISPATCH_WIDTH 8)             # Hardware allocation width mapped to instructions
set(EXEC_WIDTH 8)                 # Abstract backend; NOT 18 homogeneous ports
set(RETIRE_WIDTH 12)
set(ROB_SIZE 576)
set(DECODE_BUFFER_SIZE 192)        # Model capacity; not independently verified Lion Cove IDQ
set(LQ_WIDTH 3)
set(SQ_WIDTH 2)                   # Store data rate; 3 STA AGUs are not 3 stores/cycle
set(DTLB_SET 32)                  # 128 entries; associativity assumption
set(DTLB_WAY 4)

set(L1I_SET 64)
set(L1I_WAY 16)                   # 64 KiB
set(L1I_HIT_LATENCY 3)
set(L1I_FILL_LATENCY 1)
set(L1D_SET 64)
set(L1D_WAY 12)                   # Physical L0D: 48 KiB
set(L1D_HIT_LATENCY 3)
set(L1D_FILL_LATENCY 1)
set(L1D_MAX_READ 3)
set(L1D_MAX_WRITE 2)
set(ENABLE_L1M 1)                 # Physical L1D: 192 KiB, data path only
set(L1M_SET 256)
set(L1M_WAY 12)
set(L1M_HIT_LATENCY 4)            # Incremental stage budget, not 9-cycle load-to-use
set(L1M_FILL_LATENCY 1)
set(L2C_SET 4096)
set(L2C_WAY 12)                   # 3 MiB (Arrow Lake-sized option)
set(L2C_HIT_LATENCY 16)           # Stage budget; hardware 17-cycle L2 inspires 16+1
set(L2C_FILL_LATENCY 1)
set(L2C_MSHR_SIZE 64)             # Modeling assumption
set(L2C_MAX_READ 2)
set(LLC_SET 4096)
set(LLC_WAY 16)                   # 4 MiB effective single-core capacity assumption
set(LLC_HIT_LATENCY 39)
set(LLC_FILL_LATENCY 1)

# Classic ChampSim DDR4-3200, not a modern Intel platform's memory subsystem.
set(DRAM_DEFAULT_FULL_BANDWIDTH 1) # Prevent legacy default silently dividing rate by 4
set(DRAM_IO_FREQ 3200)            # MT/s, not physical DDR clock MHz
set(DRAM_CHANNELS 1)
set(DRAM_CHANNEL_WIDTH 8)         # Bytes: 64-bit channel, 25.6 GB/s peak
set(DRAM_RANKS 1)
set(DRAM_BANKS 8)                 # Classic flat-bank model, no bank groups
set(DRAM_ROWS 65536)
set(DRAM_COLUMNS 128)
set(DRAM_ROW_SIZE 8)              # KiB, matching legacy address geometry
set(VIRTUAL_MEMORY_SIZE 4294967296) # Physical allocator matches modeled 4 GiB DRAM
set(DRAM_RQ_SIZE 64)
set(DRAM_WQ_SIZE 64)
set(tRP_DRAM_NANOSECONDS 12.5)
set(tRCD_DRAM_NANOSECONDS 12.5)
set(tCAS_DRAM_NANOSECONDS 12.5)
# FDIP, DIB, TAGE-SC-L, BTB policies and other queues retain artifact semantics.
