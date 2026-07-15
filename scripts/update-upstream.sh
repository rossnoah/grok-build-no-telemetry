#!/usr/bin/env bash
# Rewrite the pin in scripts/lib.sh and re-apply patches.
# Usage: ./scripts/update-upstream.sh <commit-sha> [git-url]
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <commit-sha> [git-url]" >&2
  exit 1
fi

NEW_BASE="$1"
NEW_URL="${2:-$UPSTREAM_URL}"
LIB="${ROOT}/scripts/lib.sh"

[[ -f "$LIB" ]] || die "missing $LIB"

# In-place update of the defaults in lib.sh (portable-ish sed).
tmp="$(mktemp)"
sed \
  -e "s|^UPSTREAM_URL=.*|UPSTREAM_URL=\"\${UPSTREAM_URL:-${NEW_URL}}\"|" \
  -e "s|^UPSTREAM_COMMIT=.*|UPSTREAM_COMMIT=\"\${UPSTREAM_COMMIT:-${NEW_BASE}}\"|" \
  "$LIB" > "$tmp"
mv "$tmp" "$LIB"

# Re-source with new defaults
# shellcheck source=lib.sh
source "$LIB"

echo "==> pin → ${UPSTREAM_COMMIT} (${UPSTREAM_URL})"

if ! "${ROOT}/scripts/apply-patches.sh"; then
  echo "apply failed — fix work/build, then ./scripts/rebuild-patches.sh" >&2
  exit 1
fi

echo "==> done"
