#!/usr/bin/env bash
set -euo pipefail

pkgver=${1:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <asset>}
pkgrel=${2:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <asset>}
asset=${3:?usage: update-aur-metadata.sh <pkgver> <pkgrel> <asset>}
checksum=$(sha256sum "$asset" | awk '{print $1}')

[[ "$pkgver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "unexpected pkgver: $pkgver" >&2
  exit 1
}
[[ "$pkgrel" =~ ^[1-9][0-9]*$ ]] || {
  echo "unexpected pkgrel: $pkgrel" >&2
  exit 1
}

perl -0pi -e "s/^pkgver=.*/pkgver=${pkgver}/m; s/^pkgrel=.*/pkgrel=${pkgrel}/m; s/^_asset_name=\"[^\"]*\"/_asset_name=\"\\\${pkgname}-${pkgver}-${pkgrel}-x86_64.tar.zst\"/m; s/^sha256sums=\('[^']*'\)/sha256sums=('${checksum}')/m" PKGBUILD

print_srcinfo() {
  if [[ ${EUID} -ne 0 ]]; then
    makepkg --printsrcinfo
    return
  fi

  local temp_home
  temp_home=$(mktemp -d)
  trap 'rm -rf "$temp_home"' RETURN
  mkdir -p "$temp_home"/build "$temp_home"/log "$temp_home"/pkg "$temp_home"/src "$temp_home"/srcpkg
  chown -R 65534:65534 "$temp_home"
  HOME="$temp_home" \
  BUILDDIR="$temp_home/build" \
  LOGDEST="$temp_home/log" \
  PKGDEST="$temp_home/pkg" \
  SRCDEST="$temp_home/src" \
  SRCPKGDEST="$temp_home/srcpkg" \
    setpriv --reuid 65534 --regid 65534 --clear-groups makepkg --printsrcinfo
}

print_srcinfo > .SRCINFO

printf 'Updated PKGBUILD and .SRCINFO for %s-%s\n' "$pkgver" "$pkgrel"
