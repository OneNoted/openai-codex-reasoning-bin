#!/usr/bin/env bash
set -euo pipefail

asset=${1:?usage: smoke-asset.sh <asset> <pkgver>}
pkgver=${2:?usage: smoke-asset.sh <asset> <pkgver>}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

bsdtar -xf "$asset" -C "$root"

required_paths=(
  "usr/bin/codex"
  "usr/bin/codex-exec"
  "usr/bin/codex-linux-sandbox"
  "usr/share/licenses/openai-codex-reasoning-bin/LICENSE"
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "$root/$path" ]]; then
    printf 'missing required path: %s\n' "$path" >&2
    exit 1
  fi
done

version_output=$("$root/usr/bin/codex" --version)
case "$version_output" in
  *"$pkgver"*) ;;
  *)
    printf 'unexpected version output: %s\n' "$version_output" >&2
    exit 1
    ;;
esac

printf 'Asset smoke check passed for %s\n' "$asset"
