#!/usr/bin/env bash
# Shared helpers for apply/rebuild/update scripts.
# shellcheck disable=SC2034

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH_DIR="${ROOT}/patches"
WORK_DIR="${ROOT}/work"
UPSTREAM_DIR="${WORK_DIR}/upstream"
BUILD_DIR="${WORK_DIR}/build"

# --- upstream pin (edit these, or use scripts/update-upstream.sh) ---
# Clean tree lives on the "upstream" branch of this repo (or whatever URL you set).
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/rossnoah/grok-build-no-telemetry.git}"
UPSTREAM_REF="${UPSTREAM_REF:-upstream}"
UPSTREAM_COMMIT="${UPSTREAM_COMMIT:-c1b5909ec707c069f1d21a93917af044e71da0d7}"
# -------------------------------------------------------------------

die() {
  echo "error: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

# Prefer a local object; otherwise fetch into work/.upstream-git.
ensure_upstream_checkout() {
  local commit="$UPSTREAM_COMMIT"
  local url="$UPSTREAM_URL"
  local ref="$UPSTREAM_REF"
  local cache="${WORK_DIR}/.upstream-git"

  [[ -n "$commit" ]] || die "UPSTREAM_COMMIT is empty"
  [[ -n "$url" ]] || die "UPSTREAM_URL is empty"

  mkdir -p "$WORK_DIR"

  if git -C "$ROOT" cat-file -e "${commit}^{commit}" 2>/dev/null; then
    echo "==> local ${commit}"
    rm -rf "$UPSTREAM_DIR"
    mkdir -p "$UPSTREAM_DIR"
    git -C "$ROOT" archive "$commit" | tar -x -C "$UPSTREAM_DIR"
    printf '%s\n' "$commit" > "${WORK_DIR}/.upstream-commit"
    return 0
  fi

  echo "==> fetch ${commit} from ${url}"
  if [[ ! -d "${cache}/.git" ]]; then
    git clone --filter=blob:none --no-checkout "$url" "$cache"
  fi
  git -C "$cache" remote set-url origin "$url"
  git -C "$cache" fetch --tags origin "+refs/heads/*:refs/remotes/origin/*" 2>/dev/null || true
  if [[ -n "$ref" ]]; then
    git -C "$cache" fetch origin "$ref" 2>/dev/null || true
  fi
  git -C "$cache" fetch origin "$commit" 2>/dev/null \
    || git -C "$cache" fetch origin 2>/dev/null \
    || true

  git -C "$cache" cat-file -e "${commit}^{commit}" 2>/dev/null \
    || die "could not fetch ${commit} from ${url} (push the upstream branch?)"

  rm -rf "$UPSTREAM_DIR"
  mkdir -p "$UPSTREAM_DIR"
  git -C "$cache" archive "$commit" | tar -x -C "$UPSTREAM_DIR"
  printf '%s\n' "$commit" > "${WORK_DIR}/.upstream-commit"
}
