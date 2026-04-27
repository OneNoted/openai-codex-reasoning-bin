#!/usr/bin/env bash
set -euo pipefail

pkgver=${1:?usage: build-asset.sh <pkgver> <pkgrel> <fork_tag> [out-dir]}
pkgrel=${2:?usage: build-asset.sh <pkgver> <pkgrel> <fork_tag> [out-dir]}
fork_tag=${3:?usage: build-asset.sh <pkgver> <pkgrel> <fork_tag> [out-dir]}
out_dir=${4:-"$PWD/dist"}

pkgname="openai-codex-reasoning-bin"
source_repo="https://github.com/OneNoted/codex.git"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

src_dir="$work_dir/codex"
install_root="$work_dir/install-root"
asset_name="${pkgname}-${pkgver}-${pkgrel}-x86_64.tar.zst"
asset_path="${out_dir}/${asset_name}"

mkdir -p "$out_dir" "$install_root"

git clone --depth 1 --branch "$fork_tag" "$source_repo" "$src_dir"

python3 - "$src_dir/codex-rs/Cargo.toml" "$pkgver" <<'PY'
from pathlib import Path
import sys

manifest_path = Path(sys.argv[1])
build_version = sys.argv[2]
lines = manifest_path.read_text().splitlines()

in_workspace_package = False
updated = False
for index, line in enumerate(lines):
    stripped = line.strip()
    if stripped == "[workspace.package]":
        in_workspace_package = True
        continue
    if in_workspace_package and stripped.startswith("[") and stripped.endswith("]"):
        break
    if in_workspace_package and stripped.startswith("version = "):
        lines[index] = f'version = "{build_version}"'
        updated = True
        break

if not updated:
    raise SystemExit("failed to update [workspace.package].version in Cargo.toml")

manifest_path.write_text("\n".join(lines) + "\n")
PY

(
  cd "$src_dir/codex-rs"
  export RUSTUP_TOOLCHAIN=stable
  export CARGO_TARGET_DIR=target
  cargo build --release \
    -p codex-cli \
    -p codex-exec \
    -p codex-linux-sandbox
)

install -Dm755 "$src_dir/codex-rs/target/release/codex" \
  "$install_root/usr/bin/codex"
install -Dm755 "$src_dir/codex-rs/target/release/codex-exec" \
  "$install_root/usr/bin/codex-exec"
install -Dm755 "$src_dir/codex-rs/target/release/codex-linux-sandbox" \
  "$install_root/usr/bin/codex-linux-sandbox"
install -Dm644 "$src_dir/LICENSE" \
  "$install_root/usr/share/licenses/$pkgname/LICENSE"

TZ=UTC LC_ALL=C tar \
  --sort=name \
  --mtime='UTC 1970-01-01' \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --zstd \
  -cf "$asset_path" \
  -C "$install_root" \
  usr

sha256sum "$asset_path" > "${asset_path}.sha256"
printf 'Built %s\n' "$asset_path"
