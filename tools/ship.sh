#!/usr/bin/env bash
# Test, build, zip build/web (index.html at the zip's root). Uploads to itch.io only with --push.
set -euo pipefail
cd "$(dirname "$0")/.."
tools/test.sh
tools/build_web.sh
ZIP=build/maze-explorer-html5.zip
rm -f "$ZIP"
(cd build/web && zip -qr "../../$ZIP" .)
ls -l "$ZIP"
if [ "${1:-}" = "--push" ]; then
	"${BUTLER:-$HOME/bin/butler}" push build/web thegrumpygamedev/maze-explorer-of-splorr:html
else
	echo "not pushed (pass --push to upload to thegrumpygamedev/maze-explorer-of-splorr:html)"
fi
