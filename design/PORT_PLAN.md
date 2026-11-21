# Maze Explorer of SPLORR!! — milestone plan

Decisions and the original-behaviour reference are in [PORT.md](PORT.md). Toolchain, build commands, shim patterns and gotchas come from the vault's `Tech/Odin wasm recipe.md` and `Gotchas.md`: Odin `dev-2026-07-nightly` at `/home/yermom/ODIN/odin`, target `js_wasm32`, no WebGL, 2D canvas copy of a software framebuffer.

## Target layout

```
odin/
  game/          pure rules, no platform imports (maze, generation, state, act, score, rng)
  ui/            framebuffer, tile/pattern data, font, screens, input mapping, options save
  platform/web/  #+build js, exports + index.html + audio/touch glue
tools/           test.sh, build.sh, wasm parity + frame dump scripts
design/            PORT.md, PORT_PLAN.md
```

Packages import each other by relative path (`import "../game"`), as HamQuest does, so no collection flag is needed. Run tests with `-define:ODIN_TEST_THREADS=1`, put `#+build !js` on test files, and make `tools/test.sh` also `odin check -target:js_wasm32` every package (catches stray `core:os`).

## Milestones

Each milestone ends with `tools/test.sh` passing and a PORT.md log entry.

### M0: scaffold (done 2026-10-14)
- `odin/` layout, `tools/build.sh` (wasm + copy `odin.js` and page to `build/web`), `tools/test.sh`, `.gitignore` for `build/`.
- Web page that shows a solid 256x144 frame scaled crisply to the window; frame loop via exported `platform_frame`.
- **Done when** the page builds, serves over http and shows the frame.

### M1: rules core (done 2026-10-14)
- Port `Location`, `Cardinal`, weighted picker, Prim maze generator, item and monster placement, locks, difficulty tables, counters (`State`), `act(Turn|Move)`, movement/fight/unlock/pickup, visibility ray, `explorer_state`, score.
- Own xoshiro RNG, seeded by argument; clock is `now_ms` input. Every loop bounded.
- Tests: maze is a tree (connected, cells-1 edges) over 200 seeds; item count = dead ends; lock count = key count; every key reachable (bot); exit presence is **measured and logged, not guarded** (Q4, handled after the port); combat table cases; potion rescue; trap rescue; hourglass; score arithmetic against hand-computed `ScoreScreenRenderer` examples; Q4 frequency measured and recorded.
- **Done when** a scripted bot wins/loses deterministically per seed.

### M2: art and framebuffer (done 2026-10-14)
- Convert `ExplorerPatterns`, `MonsterPatterns`, `RoomPatterns`, `CommonPatterns`, `CharacterPatterns`, `Colors`, `FontTiles` into Odin constant data (a small script may generate it: `tools/gen_patterns.py`; the F# source is the input).
- Software framebuffer (`[144][256]u32`), `render_tile`, `render_string` with coloured fonts.
- Test: render each tile and compare with an F#-side or hand-checked hex dump of a few tiles.
- **Done when** a test dumps a PPM of a tile sheet that matches the original look.

### M3: play screen (done 2026-10-14)
- Port `PlayScreenRenderer` exactly: room walls by exit flags, lock tiles (with/without key), hidden/visited/visible states, items, monsters, explorer, stats panel (health/loot/keys/potions/attack/defense), monster stats of the cell ahead, status text and the time colouring (>1/2 green, >1/4 gold, else red).
- Keyboard: arrows turn-then-move, Q to score screen.
- **Done when** a seeded game is playable on the page and a frame hash is recorded for the first frame of a few seeds.

### M4: other screens and options (done 2026-10-14)
- Title, help, options (difficulty, sfx, pause allowed), pause, score screens and the state machine (`GameState` union as an Odin enum + payload). Pause shifts the deadline.
- Options and the best grand total per difficulty (D11) persisted in `localStorage` through a storage import; every read validated, missing or bad data falls back to defaults. Show the best on the score screen (placement to confirm with the user).
- **Done when** every original screen is reachable by the original keys and Esc returns as in the F#.

### M5: audio and touch (done 2026-10-14)
- Generate one jsfxr effect per original `Sfx` case (15: AcquireLoot, AcquireHourglass, AcquireKey, AcquirePotion, AcquireShield, AcquireSword, TriggerTrap, UnlockDoor, Blocked, DrinkPotion, Amulet, Death, Exit, Fight, LoveInterest), scripted under node per `Tech/jsfxr sound effects.md`, wavs committed under `odin/platform/web/`. Page-side Web Audio decodes on first input; core emits sound ids per step. The original wavs stay in the F# tree only and are never shipped.
- On-screen d-pad plus Quit/Pause/Help buttons on coarse pointers; `e.key` before `e.code`.
- **Done when** every sfx fires on the matching event and a phone-width layout works.

### M6: parity, QA and tooling (done 2026-10-15)
- Node script that drives the wasm with scripted keys and hashes frames; a native `odin test` plays the same script on the core and compares (vault: HamQuest `tools/parity.sh`, minus the SDL2 client).
- `?seed=N` and a frame-dump tool for screenshots without a browser pane.
- Soak test: random play over many seeds never hangs or panics.
- **Done when** `tools/test.sh` ends with `ALL TESTS PASSED`.

### M7: release prep (in progress, 2026-10-15)
Done: fullscreen (F key and corner button), `tools/ship.sh` (`shippit.sh` links to it; pushes only with `--push`), `tools/make_cover.py` (assets/cover.png), `ITCH_DESCRIPTION.md`, vault page. Left for the user: listen to the sounds, create the itch page, check the slug `maze-explorer-of-splorr`, look at the cover, say yes to the push.
- Cover image, itch.io page copy, credits, `shippit.sh` that tests, builds, zips and pushes only with `--push` (vault: `Shipping to itch.io`).
- Fullscreen button/key on the page. No native client (D7).
- Update the vault: add `Games/Maze Explorer of SPLORR!!.md` and a Home.md entry (the vault is a separate repo; ask before committing there).

## After the port

The exact port ships first (D3). Then, with the user: the possibly missing Exit (Q4, measured in M1), the dead `Drink` command (Q1), and the rest of the quirks table in PORT.md.
