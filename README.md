# openai-codex-reasoning-bin

Binary AUR packaging repo for OpenAI Codex with raw reasoning traces enabled
by default.

## Package contract

- package name: `openai-codex-reasoning-bin`
- target: `x86_64`
- installs the standard commands:
  `codex`, `codex-exec`, `codex-linux-sandbox`
- drop-in replacement for:
  `openai-codex`, `openai-codex-bin`, `openai-codex-reasoning`

## Source strategy

This package builds a release asset from the latest stable upstream tag
matching:

- `rust-v<version>`

The package metadata then points at the published asset hosted in this repo's
GitHub Releases. The build applies `default-raw-reasoning.patch` before
compilation so the binary keeps the downstream default without depending on a
long-lived source fork.

## Release flow

- `validate.yml` checks packaging metadata on push and pull requests
- `release.yml` polls `openai/codex` for the latest stable `rust-v*` tag
- when the upstream tag changes:
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
