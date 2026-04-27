# openai-codex-reasoning-bin

Binary AUR packaging repo for the OneNoted Codex fork that shows inline
reasoning traces in the TUI.

## Package contract

- package name: `openai-codex-reasoning-bin`
- target: `x86_64`
- installs the standard commands:
  `codex`, `codex-exec`, `codex-linux-sandbox`
- drop-in replacement for:
  `openai-codex`, `openai-codex-bin`, `openai-codex-reasoning`

## Source strategy

This package builds a release asset from the latest fork tag matching:

- `aur-v<upstream-version>-reasoning.<n>`

The package metadata then points at the published asset hosted in this repo's
GitHub Releases.

## Release flow

- `validate.yml` checks packaging metadata on push and pull requests
- `release.yml` polls `OneNoted/codex` for the latest `aur-v*-reasoning.*` tag
- when the fork tag changes:
  the workflow builds an `x86_64` release tarball,
  updates `PKGBUILD` and `.SRCINFO`,
  publishes a GitHub Release in this repo,
  and pushes the flat AUR snapshot

To keep binary release turnaround reasonable, asset builds override the
workspace release profile from fat LTO / single codegen-unit settings to a
packaging-oriented profile using thin LTO and higher codegen parallelism.

## Validation

```bash
./scripts/validate-repo.sh
```

## Maintainer

Jonatan Jonasson `<notes@madeingotland.com>`
