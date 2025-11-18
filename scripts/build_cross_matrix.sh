#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${repo_root}"

presets=(
  vxworks-ppc
  integrity-posix
)
declare -A build_presets=(
  [vxworks-ppc]=build-vxworks-ppc
  [integrity-posix]=build-integrity-posix
)

function check_env() {
  local preset=$1
  case "${preset}" in
    vxworks-ppc)
      if [[ -z "${TRDP_VXWORKS_TOOLCHAIN_PREFIX:-}" ]]; then
        echo "Skipping '${preset}': TRDP_VXWORKS_TOOLCHAIN_PREFIX is not set."
        return 1
      fi
      ;;
    integrity-posix)
      if [[ -z "${TRDP_INTEGRITY_COMPILER:-}" ]]; then
        echo "Skipping '${preset}': TRDP_INTEGRITY_COMPILER is not set."
        return 1
      fi
      ;;
  esac
  return 0
}

echo "Building cross presets (requires external toolchains): ${presets[*]}"
for preset in "${presets[@]}"; do
  build_preset=${build_presets[${preset}]}
  if ! check_env "${preset}"; then
    continue
  fi
  echo "\n=== Configuring '${preset}' ==="
  cmake --preset "${preset}"
  echo "=== Building via '${build_preset}' ==="
  cmake --build --preset "${build_preset}"
  echo "=== Completed '${preset}' ==="
done

echo "\nCross preset build script finished."
