#!/usr/bin/env bash
# Builds the SlideBolt image.
#   build.sh [--tag IMAGE]                     from the versions in versions.env
#   build.sh --workspace DIR [--tag IMAGE]     from a checkout of every repo in DIR
#   build.sh --pin DIR                         rewrites versions.env from DIR (see below)
#
# From versions.env, every repo is cloned from github.com/slidebolt at its tag,
# so the result depends only on published tags. This is what release CI runs.
# --workspace builds whatever is checked out side by side in DIR, committed or
# not; use it to test changes before they are released.
# --pin sets each repo's version to the tag at its HEAD in DIR, and fails if a
# HEAD is not exactly on a tag.
#
# The image carries /app/build-manifest.json: the release, the mode, and the
# commit of every repo it was built from.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
org_url="${SLIDEBOLT_GIT_URL:-https://github.com/slidebolt}"
image="slidebolt:local" workspace="" pin=""
while (( $# )); do
  case "$1" in
    --tag) image="$2"; shift ;;
    --workspace) workspace="$(cd "$2" && pwd)"; shift ;;
    --pin) pin="$(cd "$2" && pwd)"; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# Every repo the Dockerfile copies, except release itself.
repos() { sed -nE 's#^COPY[[:space:]]+([a-z0-9][a-z0-9-]*)/.*#\1#p' "$here/image/Dockerfile" | grep -vx release | sort -u; }

version_of() { awk -F= -v r="$1" '$1==r {print $2}' "$here/versions.env"; }

if [[ -n "$pin" ]]; then
  out="$(mktemp)"
  { echo "# The tag of every repo in the image. Written by: build.sh --pin <workspace>"
    for r in $(repos); do
      t="$(git -C "$pin/$r" describe --tags --exact-match HEAD 2>/dev/null)" || die "$r: HEAD is not on a tag"
      echo "$r=$t"
    done; } >"$out"
  mv "$out" "$here/versions.env"
  log "versions.env pinned to $(repos | wc -l) tags"
  exit 0
fi

ctx="$(mktemp -d)"; trap 'rm -rf "$ctx"' EXIT
release_version="$(git -C "$here" describe --tags --always --dirty 2>/dev/null || echo unknown)"
declare -A commit url

if [[ -n "$workspace" ]]; then
  mode=workspace
  [[ "$(cd "$workspace/release" 2>/dev/null && pwd)" == "$here" ]] \
    || die "--workspace must be the directory that holds this release checkout"
  build_ctx="$workspace"
  for r in $(repos) release; do
    [[ -d "$workspace/$r" ]] || die "$r is not checked out in $workspace"
    c="$(git -C "$workspace/$r" rev-parse HEAD 2>/dev/null || echo none)"
    [[ -z "$(git -C "$workspace/$r" status --porcelain 2>/dev/null)" ]] || c="$c-dirty"
    commit[$r]="$c"
  done
else
  mode=tags
  build_ctx="$ctx"
  for r in $(repos); do
    v="$(version_of "$r")"
    [[ -n "$v" ]] || die "$r is in image/Dockerfile but not in versions.env"
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$v" "$org_url/$r.git" "$ctx/$r" \
      || die "cannot clone $r at $v"
    commit[$r]="$(git -C "$ctx/$r" rev-parse HEAD)"
    url[$r]="$org_url/$r"
  done
  # This checkout of release supplies the image definition.
  mkdir "$ctx/release"
  # Tracked and new files, skipping ones deleted in this checkout.
  (cd "$here" && git ls-files -z --cached --others --exclude-standard |
    while IFS= read -r -d '' f; do [[ -e "$f" ]] && printf '%s\0' "$f"; done |
    xargs -0 cp --parents -t "$ctx/release")
  commit[release]="$(git -C "$here" rev-parse HEAD 2>/dev/null || echo none)"
  log "cloned $(repos | wc -l) repos at the versions in versions.env"
fi

build_id="$release_version-$(date -u +%Y%m%d%H%M%S)"
manifest="$(
  for r in "${!commit[@]}"; do printf '%s %s %s\n' "$r" "${commit[$r]}" "${url[$r]:-}"; done |
  python3 -c '
import json, sys
repos, urls = {}, {}
for line in sys.stdin:
    p = line.split()
    repos[p[0]] = p[1]
    if len(p) > 2: urls[p[0]] = p[2]
print(json.dumps({"build_id": sys.argv[1], "release": sys.argv[2], "mode": sys.argv[3],
                  "repos": dict(sorted(repos.items())), "urls": dict(sorted(urls.items()))},
                 sort_keys=True, separators=(",", ":")))' "$build_id" "$release_version" "$mode"
)"

log "building $image ($mode, release $release_version)"
docker build -f "$build_ctx/release/image/Dockerfile" -t "$image" \
  --build-arg SB_BUILD_ID="$build_id" --build-arg SB_BUILD_MANIFEST="$manifest" "$build_ctx"
log "built $image"
