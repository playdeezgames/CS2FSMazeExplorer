#!/usr/bin/env bash
# Tests, an optimized web build, a zip of build/web (index.html at the root). Pushes ONLY with --push.
# Never touches git and never deletes anything but the old zip. Usage: tools/ship.sh [--push]
set -euo pipefail
cd "$(dirname "$0")/.."
# The page: https://thegrumpygamedev.itch.io/maze-explorer-of-splorr
TARGET="thegrumpygamedev/maze-explorer-of-splorr:html"
ZIP="build/maze-explorer-html5.zip"

tools/test.sh
tools/build_web.sh
rm -f "$ZIP"
(cd build/web && zip -q -9 -r "../maze-explorer-html5.zip" .)
echo "zip: $ZIP ($(du -h "$ZIP" | cut -f1)); wasm $(du -h build/web/mazeexplorer.wasm | cut -f1)"
unzip -l "$ZIP" | tail -5

if [ "${1:-}" = "--push" ]; then
	if [ -n "$(git status --porcelain)" ]; then echo "note: the working tree has uncommitted changes; what is pushed is the working tree, not a commit"; fi
	"${BUTLER:-$HOME/bin/butler}" push build/web "$TARGET"
	echo "pushed to $TARGET. It goes live after itch.io processes it; check: butler status $TARGET"
else
	echo "not pushed (run tools/ship.sh --push when you want it live; the target is $TARGET)"
fi
