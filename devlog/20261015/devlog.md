# Maze Explorer of SPLORR!! is up

Maze Explorer was a sample game for a blog series about moving from C# to F#. I wrote it years ago, it was WinForms and it was never going to run in a browser. It does now.

This is an exact port. The rules, the difficulty tables, the 8 by 8 art and the font are the original's. You get a maze you only see a little of, locks and keys, monsters, items, and a clock that is not on your side. Three difficulties, a score screen, and your best score for each is remembered in the browser.

What is new: it runs as WebAssembly (Odin), it has touch buttons for phones, fullscreen on the F key, and the sounds are new, made with jsfxr instead of the original wav files. Add `?seed=N` to the address to play the same maze again.

The quirks. The original has a few, and I went through them one at a time. Fixed: a Drink command that did nothing is gone (potions still drink themselves when they would save you), the clock no longer eats the last second, and a maze with too few dead ends can no longer lose its exit (it never happened in 900 mazes, but now it cannot). Kept on purpose: monsters you cannot hurt until you have better gear, a locked exit now and then, a random start cell, the original art, and the rule that turns the pause keys off when Pause Game is off.

Under the hood: 50 tests, the 297 original art patterns checked against the F# source, and a check that the wasm build and a native build draw the same frames for the same keys.

Still on the list: a proper listen to those sounds, and whatever you find when you play it.
