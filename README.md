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
