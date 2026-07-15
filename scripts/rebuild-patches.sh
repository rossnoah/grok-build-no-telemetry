#!/usr/bin/env bash
# Regenerate patches/ from the commit series in work/build — one patch per
# commit after the upstream-base tag, numbered by commit order, named from
# the commit subject.
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cmd git

[[ -d "$BUILD_DIR/.git" ]] || die "work/build missing — run ./scripts/apply-patches.sh first"
git -C "$BUILD_DIR" rev-parse -q --verify upstream-base >/dev/null \
  || die "work/build has no upstream-base tag — re-run ./scripts/apply-patches.sh"

# Every change must live in a commit so it lands in a specific patch.
# Fold edits into the right commit (git commit --amend for HEAD) or add a
# new commit whose subject becomes the new patch's name.
if [[ -n "$(git -C "$BUILD_DIR" status --porcelain)" ]]; then
  die "work/build has uncommitted changes — commit them first (subject = patch name)"
fi

commits=$(git -C "$BUILD_DIR" rev-list --reverse upstream-base..HEAD)
[[ -n "$commits" ]] || die "no commits after upstream-base (nothing to export)"

mkdir -p "$PATCH_DIR"
rm -f "${PATCH_DIR}"/*.patch

i=0
while read -r c; do
  i=$((i + 1))
  subject=$(git -C "$BUILD_DIR" log -1 --format=%s "$c")
  slug=$(printf '%s' "$subject" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
  [[ -n "$slug" ]] || die "commit $c has an empty subject slug"
  out=$(printf '%s/%04d-%s.patch' "$PATCH_DIR" "$i" "$slug")
  [[ ! -e "$out" ]] || die "duplicate patch name: $(basename "$out")"
  git -C "$BUILD_DIR" diff --binary --minimal "${c}^" "$c" > "$out"
  grep -q '^diff --git' "$out" || die "empty patch from commit $c ($subject)"
  hunks=$(grep -c '^@@' "$out" || true)
  echo "==> wrote $(basename "$out") (${hunks} hunks)"
done <<< "$commits"

echo "    commit patches/ (and any script/docs changes) to this repo"
