#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
deps_dir=${THERMOMETER_DEPS:-/scratch/ningzhiai/thermometer-deps}
cmake -S "$repo_dir" -B "$repo_dir/build-lion-cove" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBOOST_ROOT="$deps_dir/env" -DBoost_NO_SYSTEM_PATHS=ON -DBoost_NO_BOOST_CMAKE=ON \
  -DXED_INCLUDE_DIRS="$deps_dir/xed-install/include" \
  -DXED_LIBRARY_DIR="$deps_dir/xed-install/lib" \
  '-DTHERMOMETER_CONFIGS=lion_cove_ddr4' \
  '-DTHERMOMETER_TARGETS=lru;opt_generate;opt;hot_warm_cold_80_50_f_keep_curr_hotter_lru'
cmake --build "$repo_dir/build-lion-cove" --parallel "${BUILD_JOBS:-4}"
