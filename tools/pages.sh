#!/usr/bin/env bash
# Builds the web build and copies it to docs/ for GitHub Pages (served from the default branch, /docs):
# https://playdeezgames.github.io/CS2FSMazeExplorer/
# docs/ is generated and wiped on each run. Never commits or pushes.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf build/web; tools/build_web.sh > /dev/null
rm -rf docs
mkdir docs
cp -r build/web/. docs/
touch docs/.nojekyll
echo "docs/ ready: $(du -sh docs | cut -f1)"
