#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 POLICY TRACE [simulator options...]" >&2
  echo "PT input by default. Set TRACE_FORMAT=champsim for address-bearing binary traces." >&2
  exit 2
fi
policy=$1
trace=$2
shift 2
exe="$repo_dir/build-lion-cove/ChampSim_lion_cove_ddr4_${policy}"
if [ ! -x "$exe" ]; then echo "Missing executable: $exe" >&2; exit 2; fi
if [ ! -f "$trace" ]; then echo "Missing trace: $trace" >&2; exit 2; fi
trace=$(realpath "$trace")
entries=${BTB_ENTRIES:-8192}
ways=${BTB_WAYS:-4}
export THERMOMETER_DATA_ROOT=${THERMOMETER_DATA_ROOT:-"$repo_dir/runs/lion-cove-ddr4-${entries}-${ways}"}
mkdir -p "$THERMOMETER_DATA_ROOT/btb_record_insert_taken"
trace_flags=()
if [ "${TRACE_FORMAT:-pt}" = pt ]; then trace_flags=(--pt); fi
exec "$exe" --warmup_instructions "${WARMUP_INSTRUCTIONS:-1000000}" \
  --simulation_instructions "${SIMULATION_INSTRUCTIONS:-10000000}" \
  --high_bandwidth --total_btb_entries "$entries" --total_btb_ways "$ways" \
  --train_total_btb_entries "$entries" --train_total_btb_ways "$ways" \
  "${trace_flags[@]}" "$@" -traces "$trace"
