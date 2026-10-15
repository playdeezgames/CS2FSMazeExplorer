# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**Maze Explorer of SPLORR!!**: a port of an old F# game (the sample for the "C# to F#" blog series, https://csharptofsharp.wordpress.com/) to the user's Odin + `js_wasm32` stack, web only. The F# in `MazeExplorer/` is the **oracle for the port**, not something to extend (legacy .NET 4.5 WinForms, no tests; `dotnet` 10 cannot build it, and the port does not need it to). The port lives in `odin/`.

Decisions are the user's and are logged in `docs/PORT.md`; the milestone plan is `docs/PORT_PLAN.md` (M0 to M6 done, M7 release prep needs the user). **The exact port ships first**; the F#'s quirks (Q1 to Q12 in `PORT.md`) are reproduced on purpose and marked `QUIRK Qn` in code, to be dealt with after the port. Any departure from the F# behaviour goes in `PORT.md` and is asked about first. Title, web only, 256x144 frame, jsfxr sounds (not the original wavs), original art and font, options plus best score saved: all decided.

## Commands

```bash
tools/test.sh                      # everything; must end with ALL TESTS PASSED
tools/build_web.sh                 # build/web: wasm, odin.js, page, sfx/ (serve with python3 -m http.server -d build/web PORT)
tools/parity.sh                    # native replay vs wasm under node: same digest for the same seed and keys
python3 tools/gen_patterns.py      # regenerate odin/ui/patterns_gen.odin from the F# pattern sources (--check to verify)
tools/check_patterns.sh            # run the original F# pattern files under `dotnet fsi` and compare (297 patterns)
node tools/gen_sfx.js --sfxr DIR   # regenerate odin/platform/web/page/sfx/*.wav (DIR = jsfxr's sfxr.js + riffwave.js from sfxr.me; not kept in the repo)
node tools/wasm_node.js dump SEED KEYS out.ppm [STEP_MS]   # a frame from the wasm build without a browser
```

Odin is `/home/yermom/ODIN/odin` (`dev-2026-07-nightly`). One test: `odin test odin/tests -define:ODIN_TEST_THREADS=1 -define:ODIN_TEST_NAMES=tests.NAME -out:build/tests.bin` (run from the repo root: two tests read `odin/platform/web/page`). `ODIN_TEST_THREADS=1` is required (see the vault's `Gotchas.md`). Page options: `?seed=N` fixes the first maze, `?play=1` skips the title, `?touch=1` shows touch controls, `?log=1` logs keys.

## Architecture (`odin/`)

Packages import each other by relative path. Everything below `platform/` compiles for native and `js_wasm32` (`tools/test.sh` checks both, so a stray `core:os` fails).

- `game/`: the pure rules, no platform imports, no heap, no globals. One flat `Game` struct (arrays indexed by cell, `row * 24 + column`). **Clock and entropy are arguments**: `now_ms` is passed to every call, randomness is the core's own xoshiro256** seeded by the caller. `new_game` (setup.odin), `act` (act.odin: turn, move, unlock, fight, pickups, explorer state), `score.odin`, `maze.odin` (Prim tree, ray visibility). `act` returns the sound (`Sfx`) of the step.
- `ui/`: the software framebuffer (`[256*144]u32`, bytes R,G,B,A), tile rendering, all six screens, key handling, settings text. `App` is the whole UI state; `app_key(app, key, now_ms)`, `app_draw(app, now_ms)`, `app_take_sfx`. `patterns_gen.odin` is **generated** (never hand edit). `Key` numbers are shared with the page.
- `platform/web/`: `main.odin` (exports `platform_*`, `#+build` free but only built for wasm) and `page/` (`index.html`, `platform.js`, `sfx/`). The page owns the animation loop, maps `e.key` to `ui.Key`, copies the frame to a canvas, plays sounds after the first user gesture, stores `mex:settings` in localStorage. Two tests pin the page's key numbers and sound list against the Odin enums, so changing either side alone fails.
- `tools/replay/`: the native half of the parity check (a console program, not a client).
- `tests/`: `#+build !js`, run natively. Game rules use a `corridor` helper for exact-number scenarios; a bot plays whole mazes; `soak_test` plays random keys through every screen checking invariants; `first_frames_are_stable` pins frame hashes for three seeds (update them deliberately).

## Things that are easy to get wrong

- Odin's `%3d` zero-pads; the F# `%3i` pads with spaces. Use `ui.format_padded` / `Builder`.
- `app.dirty` must be set for anything that should repaint; `app_key` does it from its result.
- Pause, help and options opened from play shift the deadline by the time away (`shift_deadline`); with Pause Game off those keys do nothing (Q7).
- Seeds are not the F#'s: it used `System.Random`, so only distributions and rules match, not streams.
- The vault (`/home/yermom/git/bok-of-splorr/splorr`, an additional working directory) holds the Odin wasm recipe and gotchas; `Tech/Odin wasm recipe.md` and `Gotchas.md` are the ones to read. Vault edits are a separate repo: ask before committing there.

## The F# original, for reference

Four projects under `MazeExplorer/`: `MazeExplorerLibrary` (generic maze: Prim growth on a **square** 4-neighbour grid; the Hex and Intercardinal modules are unused), `MazeExplorerGame` (immutable `State`, `Action.act` with `Turn | Move | Drink`, `Movement`, `ItemPickup`, `Difficulty`/`Constants`, `Monsters`), `MazeExplorerUILibrary` (8x8 `'X'` pattern bitmaps, palette, font, tiles, `FrameBuffer`), `MazeExplorerUI` (screens, `Input.fs`, `Audio.fs`, a mutable `GameState`). The compile order in each `.fsproj` is a good reading order. `docs/PORT.md` lists the behaviours worth knowing (generation, combat, scoring, constants).
