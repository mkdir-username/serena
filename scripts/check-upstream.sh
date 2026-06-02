#!/bin/bash
# Notify when oraios/serena (upstream) has new commits/tags beyond what this fork has seen.
# Mirrors the codegraph fork's upstream-watch pattern. Run weekly via launchd.
# State file remembers the last-seen upstream HEAD so only NEW changes notify.

set -euo pipefail

FORK_DIR="${SERENA_FORK_DIR:-$HOME/Docs/serena}"
STATE="$FORK_DIR/.upstream-last-seen"

cd "$FORK_DIR"
git fetch --quiet --tags upstream 2>/dev/null || { echo "fetch failed"; exit 0; }

upstream_head=$(git rev-parse --short upstream/main)
latest_tag=$(git tag --sort=-v:refname --merged upstream/main 2>/dev/null | head -1)
[ -z "$latest_tag" ] && latest_tag=$(git ls-remote --tags upstream | sed 's#.*refs/tags/##' | grep -E '^v[0-9]' | sort -V | tail -1)

last_seen=""
[ -f "$STATE" ] && last_seen=$(cat "$STATE")

if [ "$upstream_head" = "$last_seen" ]; then
    exit 0   # nothing new since last check
fi

ahead=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo "?")
msg="serena upstream: +$ahead commits (latest tag $latest_tag, head $upstream_head). Sync: see FORK.md"

# macOS notification + log line
osascript -e "display notification \"$msg\" with title \"Serena fork — upstream update\"" 2>/dev/null || true
echo "$(date '+%Y-%m-%d %H:%M') $msg" >> "$FORK_DIR/.upstream-check.log"

echo "$upstream_head" > "$STATE"
