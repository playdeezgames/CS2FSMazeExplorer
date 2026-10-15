#!/usr/bin/env bash
# Run every check. Must end with ALL TESTS PASSED.
set -euo pipefail
cd "$(dirname "$0")/.."
ODIN="${ODIN:-$HOME/ODIN/odin}"
mkdir -p build
echo "== generated patterns are up to date, and match the F# source run under dotnet fsi"
python3 tools/gen_patterns.py --check
tools/check_patterns.sh
echo "== odin check (vet) game and ui, native and wasm"
for pkg in game ui; do
	"$ODIN" check odin/$pkg -no-entry-point -vet
	"$ODIN" check odin/$pkg -no-entry-point -vet -target:js_wasm32
done
echo "== odin test"
"$ODIN" test odin/tests -define:ODIN_TEST_THREADS=1 -o:speed -out:build/tests.bin
echo "== web build"
tools/build_web.sh > /dev/null
echo "== wasm versus native parity"
tools/parity.sh
echo "ALL TESTS PASSED"
