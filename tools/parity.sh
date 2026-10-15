#!/usr/bin/env bash
# The wasm build and the native build of the same packages must draw identical frames for the same
# seed and keys. Needs build/web (tools/build_web.sh) and node; skipped without node.
set -euo pipefail
cd "$(dirname "$0")/.."
ODIN="${ODIN:-$HOME/ODIN/odin}"
NODE="${NODE:-node}"
if ! command -v "$NODE" > /dev/null; then
	echo "node not found: skipping the wasm parity check"
	exit 0
fi
mkdir -p build
"$ODIN" build odin/tools/replay -out:build/replay
fail=0
for seed in 1 7 42 31337; do
	keys=$(python3 - "$seed" <<'PY'
import random, sys
random.seed(int(sys.argv[1]))
# ui.Key numbers (odin/ui/app.odin): 1-4 arrows, 5 Q, 6 Space, 7 F1, 8 F3, 9 Escape, 10 M, 11 P, 12 F2.
# Start a game, then mostly arrows with the other keys mixed in, so every screen is visited.
pool = [1, 2, 3, 4] * 8 + [5, 6, 7, 8, 9, 10, 11, 12]
print(','.join(['12'] + [str(random.choice(pool)) for _ in range(800)]))
PY
)
	native=$(build/replay "$seed" "$keys")
	web=$("$NODE" tools/wasm_node.js hash "$seed" "$keys")
	if [ "$native" = "$web" ]; then
		echo "seed $seed: same ($(echo "$native" | tr '\n' ' '))"
	else
		echo "seed $seed: MISMATCH"
		echo "  native: $(echo "$native" | tr '\n' ' ')"
		echo "  web:    $(echo "$web" | tr '\n' ' ')"
		fail=1
	fi
done
exit $fail
