#!/usr/bin/env bash
set -euo pipefail

current_pkgver=$(awk -F= '/^pkgver=/{print $2; exit}' PKGBUILD)
current_pkgrel=$(awk -F= '/^pkgrel=/{print $2; exit}' PKGBUILD)
current_fork_tag=$(awk -F"'" '/^_fork_tag=/{print $2; exit}' PKGBUILD)

force_release=${FORCE_RELEASE:-false}
fork_tag_override=${FORK_TAG_OVERRIDE:-}
pkgrel_override=${PKGREL_OVERRIDE:-}

latest_fork_tag() {
  git ls-remote --refs --tags https://github.com/OneNoted/codex.git 'aur-v*' |
    awk '{sub("refs/tags/","",$2); print $2}' |
    sort -V |
    tail -n 1
}

if [[ -n "$fork_tag_override" ]]; then
  fork_tag=$fork_tag_override
else
  fork_tag=$(latest_fork_tag)
fi

if [[ -z "$fork_tag" ]]; then
  echo "failed to determine fork tag" >&2
  exit 1
fi

if [[ ! "$fork_tag" =~ ^aur-v([0-9]+\.[0-9]+\.[0-9]+)-reasoning\.([0-9]+)$ ]]; then
  echo "unexpected fork tag format: $fork_tag" >&2
  exit 1
fi

pkgver=${BASH_REMATCH[1]}
release_tag="v${pkgver}-${pkgrel_override:-1}"
asset_name="openai-codex-reasoning-bin-${pkgver}-${pkgrel_override:-1}-x86_64.tar.zst"
should_release=false
reason="already at desired fork tag"

if [[ "$fork_tag" != "$current_fork_tag" ]]; then
  pkgrel=${pkgrel_override:-1}
  should_release=true
  if [[ "$pkgver" == "$current_pkgver" ]]; then
    pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
    reason="fork tag changed within same upstream release"
  else
    reason="fork tag moved to a new upstream release"
  fi
elif [[ -n "$pkgrel_override" && "$pkgrel_override" != "$current_pkgrel" ]]; then
  pkgrel=$pkgrel_override
  should_release=true
  reason="pkgrel override requested"
elif [[ "$force_release" == "true" ]]; then
  pkgrel=${pkgrel_override:-$((10#$current_pkgrel + 1))}
  should_release=true
  reason="forced release requested"
else
  pkgrel=$current_pkgrel
fi

release_tag="v${pkgver}-${pkgrel}"
asset_name="openai-codex-reasoning-bin-${pkgver}-${pkgrel}-x86_64.tar.zst"

cat <<EOF
pkgver=$pkgver
pkgrel=$pkgrel
fork_tag=$fork_tag
release_tag=$release_tag
asset_name=$asset_name
should_release=$should_release
reason=$reason
EOF
