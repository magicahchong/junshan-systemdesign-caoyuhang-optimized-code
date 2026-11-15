#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
source_dir="${1:-$repo_root/systems/GateANN-public}"
build_jobs="${FVS_BUILD_JOBS:-8}"

if [[ ! -f "$source_dir/CMakeLists.txt" ]]; then
  echo "ERROR: GateANN source directory not found: $source_dir" >&2
  exit 2
fi

cmake -S "$source_dir" -B "$source_dir/build" -DCMAKE_BUILD_TYPE=Release -DUSE_AIO=ON
cmake --build "$source_dir/build" --target build_disk_index search_disk_index_yfcc -j "$build_jobs"

dataset_root="$repo_root/datasets/yfcc_course_v1"
if [[ -d "$dataset_root" ]]; then
  python3 "$repo_root/adapters/gateann_adapter.py" doctor --repo "$source_dir" --dataset-root "$dataset_root" --tier debug
else
  echo "GateANN build complete. Download the course dataset before running doctor."
fi
