#!/usr/bin/env bash
# Run the original F# pattern files under `dotnet fsi` and require every pattern to match what
# gen_patterns.py read from the same source text. Skipped when dotnet is not installed.
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v dotnet > /dev/null; then
	echo "dotnet not found: skipping the F# oracle check"
	exit 0
fi
mkdir -p build
python3 tools/gen_patterns.py --fsx > build/oracle_patterns.fsx
python3 tools/gen_patterns.py --dump > build/oracle_expected.txt
DOTNET_NOLOGO=1 DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet fsi --quiet --exec build/oracle_patterns.fsx > build/oracle_actual.txt
diff build/oracle_expected.txt build/oracle_actual.txt
echo "F# oracle matches: $(wc -l < build/oracle_actual.txt) patterns"
