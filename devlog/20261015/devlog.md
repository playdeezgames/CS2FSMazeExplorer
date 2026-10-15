# Maze Explorer of SPLORR!! is up

Maze Explorer was a sample game for a blog series about moving from C# to F#. I wrote it years ago, it was WinForms and it was never going to run in a browser. It does now.

This is an exact port. The rules, the difficulty tables, the 8 by 8 art and the font are the original's. You get a maze you only see a little of, locks and keys, monsters, items, and a clock that is not on your side. Three difficulties, a score screen, and your best score for each is remembered in the browser.

What is new: it runs as WebAssembly (Odin), it has touch buttons for phones, fullscreen on the F key, and the sounds are new, made with jsfxr instead of the original wav files. Add `?seed=N` to the address to play the same maze again.

What is not new, on purpose: the quirks. The original has a few. A Drink command that does nothing, a pause setting that blocks help and options while a game is running, and monsters you cannot hurt at all until you find better gear (a Golem takes nothing from a weak sword). The F# code could in theory drop the exit from a maze with too few dead ends; I measured 900 mazes and it never did. I kept all of it, wrote each one down, and will deal with them one at a time.

Under the hood: 50 tests, the 297 original art patterns checked against the F# source, and a check that the wasm build and a native build draw the same frames for the same keys.

Still on the list: the quirks, and a proper listen to those sounds.
