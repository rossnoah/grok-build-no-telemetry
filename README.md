# grok-build-no-telemetry

Grok Build with SpaceXAI product telemetry ripped out.

This repo is patches and scripts only. Upstream is fetched into `work/` when you
apply them (that directory is gitignored).

One patch per disabled component. Env, config, and remote settings can't turn
any of them back on:

| Patch | Removes |
|---|---|
| `0001-disable-product-analytics` | Product event posts + Mixpanel client wiring |
| `0002-neuter-mixpanel-crate` | Network I/O inside `xai-mixpanel` (belt and braces) |
| `0003-disable-sentry` | Sentry crash/error reporting |
| `0004-disable-otlp-export` | OTLP span export to cli-chat-proxy |
| `0005-disable-trace-upload` | Session trace / GCS artifact upload (incl. heap profiles, auth diagnostics) |
| `0006-disable-feedback` | `/feedback` posts to cli-chat-proxy |

Still available: external OpenTelemetry aimed at your own collector (`GROK_EXTERNAL_OTEL`).

## Install

Prebuilt binaries for Linux (x86_64 / aarch64) and macOS (Apple Silicon) are on the
[releases page](https://github.com/rossnoah/grok-build-no-telemetry/releases):

```sh
curl -fsSL https://github.com/rossnoah/grok-build-no-telemetry/releases/latest/download/grok-no-telemetry-aarch64-apple-darwin.tar.gz | tar xz
./grok
```

(There's no `cargo install` path — this repo is patches, not a crate.)

## CI / releases

CI applies the patches and runs `cargo check` plus the fork's tests on every
push. Pushing a `v*` tag builds release binaries and publishes them.

Versioning: `v<upstream-version>+notel.<n>` — the upstream base must match the
highest entry in `crates/codegen/xai-grok-shell/changelogs/` in the pinned
source (the release workflow checks this), and `<n>` counts fork revisions on
that base. The version has equal semver precedence with upstream's, which
keeps the binary's minimum-version gate happy:

```sh
git tag 'v0.2.101+notel.1' && git push origin 'v0.2.101+notel.1'
```

## Build

```sh
./scripts/apply-patches.sh
cd work/build
cargo run -p xai-grok-pager-bin
```

You need Rust (toolchain file is in the build tree) and `protoc` on `PATH`.

```sh
cd work/build
cargo build -p xai-grok-pager-bin --release
# → work/build/target/release/xai-grok-pager
```

The official install script ships stock Grok Build, not this.

## Working on patches

Each patch is one commit in `work/build` on top of the `upstream-base` tag;
`rebuild-patches.sh` exports one numbered patch per commit, named from the
commit subject. It requires a clean tree — commit your edits first:

```sh
./scripts/apply-patches.sh                 # work/build = upstream + one commit per patch
# edit under work/build, then either:
#   fold into the last patch:  git -C work/build commit -a --amend --no-edit
#   add a new patch:           git -C work/build commit -am "disable-foo"
./scripts/rebuild-patches.sh               # refresh patches/ from the commit series
./scripts/update-upstream.sh <sha> [url]   # bump pin in scripts/lib.sh, re-apply
```

Upstream pin (URL + commit) is hardcoded at the top of `scripts/lib.sh`. Clean
sources live on the `upstream` branch so `main` stays small — push both:

```sh
git push origin main upstream
```
