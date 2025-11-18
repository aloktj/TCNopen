#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${repo_root}"

presets=(
  linux-posix-release
  linux-posix-debug
  linux-posix-minimal
  linux-high-perf
  linux-tsn
)
declare -A build_presets=(
  [linux-posix-release]=build-linux-posix-release
  [linux-posix-debug]=build-linux-posix-debug
  [linux-posix-minimal]=build-linux-posix-minimal
  [linux-high-perf]=build-linux-high-perf
  [linux-tsn]=build-linux-tsn
)

echo "Building Linux presets: ${presets[*]}"
for preset in "${presets[@]}"; do
  build_preset=${build_presets[${preset}]}
  echo "\n=== Configuring '${preset}' ==="
  cmake --preset "${preset}"
  echo "=== Building via '${build_preset}' ==="
  cmake --build --preset "${build_preset}"
  echo "=== Completed '${preset}' ==="
done

echo "\nAll Linux presets built successfully."
