#!/usr/bin/env bash
# Fetch upstream into work/upstream, apply patches/ into work/build.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cmd git
require_cmd python3
require_cmd tar

if [[ ! -d "$PATCH_DIR" ]] || ! compgen -G "${PATCH_DIR}/*.patch" >/dev/null; then
  die "no patches in ${PATCH_DIR}"
fi

ensure_upstream_checkout
commit="$(cat "${WORK_DIR}/.upstream-commit")"

echo "==> creating work/build from upstream ${commit}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
# Copy tree (no VCS metadata from archive)
cp -a "${UPSTREAM_DIR}/." "$BUILD_DIR/"

# Track build as its own mini-repo so rebuild-patches can diff cleanly.
git -C "$BUILD_DIR" init -q
git -C "$BUILD_DIR" checkout -q -b build
# identity only for local commits inside work/ (never pushed)
git -C "$BUILD_DIR" -c user.email="fork@localhost" -c user.name="fork" \
  add -A
git -C "$BUILD_DIR" -c user.email="fork@localhost" -c user.name="fork" \
  commit -q -m "Upstream ${commit}"
git -C "$BUILD_DIR" tag -f upstream-base

echo "==> applying patches"
shopt -s nullglob
patches=("${PATCH_DIR}"/*.patch)
for p in "${patches[@]}"; do
  echo "    $(basename "$p")"
  git -C "$BUILD_DIR" apply --index --whitespace=nowarn "$p" \
    || die "failed to apply $(basename "$p") — fix conflicts in work/build then rebuild-patches"
  # Subject = patch name minus the order prefix, so rebuild-patches.sh
  # round-trips the series (commit subject → patch filename).
  name="$(basename "$p" .patch)"
  subject="${name#[0-9][0-9][0-9][0-9]-}"
  git -C "$BUILD_DIR" -c user.email="fork@localhost" -c user.name="fork" \
    commit -q -m "$subject"
done

echo ""
echo "==> ready: work/build  (edit here, then ./scripts/rebuild-patches.sh)"
echo "    build:  cd work/build && cargo build -p xai-grok-pager-bin"
