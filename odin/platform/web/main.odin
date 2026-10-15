package main

// Web shell (js_wasm32). The page owns the animation loop and calls these exports; the game and
// the UI are the same packages the tests use. Build: tools/build_web.sh

import "base:runtime"
import "../../ui"

app: ui.App
digest: u64 = ui.FNV64_OFFSET // parity check: a running hash of every frame (tools/wasm_node.js)

main :: proc() {
	ui.app_init(&app, 1)
}

// odin.js calls `step` every animation frame; the page drives everything else itself. Without a
// `step`, odin.js would end the program straight after `main`.
@(export)
step :: proc(dt: f64, c: runtime.Context) -> bool {
	return true
}

// Resets the app to the title screen. The first game uses this seed (`?seed=N` fixes it); later
// games derive theirs from it.
@(export)
platform_init :: proc "c" (seed_lo, seed_hi: u32) {
	context = runtime.default_context()
	ui.app_init(&app, u64(seed_hi) << 32 | u64(seed_lo))
}

// Skips the title screen and starts a game (`?play=1`, tests). `now_ms` is the page's clock
// (performance.now()), the same clock every later call passes in.
@(export)
platform_start_game :: proc "c" (now_ms: f64) {
	context = runtime.default_context()
	ui.app_new_game(&app, now_ms)
}

// `key` is a ui.Key number (see page/platform.js). Returns 1 when the picture needs redrawing.
@(export)
platform_key :: proc "c" (key: i32, now_ms: f64) -> i32 {
	context = runtime.default_context()
	if key <= 0 || key > i32(max(ui.Key)) {return 0}
	return 1 if ui.app_key(&app, ui.Key(key), now_ms) else 0
}

// Draws if anything changed. Returns 1 when the framebuffer holds a picture the page has not
// copied yet.
@(export)
platform_frame :: proc "c" (now_ms: f64) -> i32 {
	context = runtime.default_context()
	defer free_all(context.temp_allocator)
	return 1 if ui.app_draw(&app, now_ms) else 0
}

// The sound of the last action (a game.Sfx number), cleared when read. Played from M5 on.
@(export)
platform_take_sfx :: proc "c" () -> i32 {
	context = runtime.default_context()
	return i32(ui.app_take_sfx(&app))
}

// The shared text buffer for saved settings, IO_SIZE bytes.
@(export)
platform_io_ptr :: proc "c" () -> rawptr {
	return &app.io[0]
}

@(export)
platform_io_size :: proc "c" () -> i32 {
	return ui.IO_SIZE
}

// Have the options or best scores changed since the page last stored them?
@(export)
platform_settings_dirty :: proc "c" () -> i32 {
	return 1 if app.settings_dirty else 0
}

// Writes the settings text into the shared buffer; returns its length.
@(export)
platform_settings_encode :: proc "c" () -> i32 {
	context = runtime.default_context()
	return i32(len(ui.settings_encode(&app)))
}

@(export)
platform_settings_ack :: proc "c" () {
	app.settings_dirty = false
}

// Restores from `n` bytes the page put in the shared buffer. 0 restored, 1 refused (nothing changed).
@(export)
platform_settings_load :: proc "c" (n: i32) -> i32 {
	context = runtime.default_context()
	if n <= 0 || int(n) > ui.IO_SIZE {return 1}
	return 0 if ui.settings_decode(&app, string(app.io[:n])) else 1
}

// Parity check: fold the frame just drawn into the running digest.
@(export)
platform_digest_fold :: proc "c" () {
	context = runtime.default_context()
	digest = ui.digest_fold(digest, ui.frame_hash64(&app.fb))
}

@(export)
platform_digest_lo :: proc "c" () -> u32 {
	return u32(digest)
}

@(export)
platform_digest_hi :: proc "c" () -> u32 {
	return u32(digest >> 32)
}

@(export)
platform_frame_hash32 :: proc "c" () -> u32 {
	context = runtime.default_context()
	return ui.frame_hash32(&app.fb)
}

@(export)
platform_screen :: proc "c" () -> i32 {
	return i32(app.screen)
}

@(export)
platform_frame_ptr :: proc "c" () -> rawptr {
	return &app.fb.pixels[0]
}

@(export)
platform_width :: proc "c" () -> i32 {
	return ui.FRAME_W
}

@(export)
platform_height :: proc "c" () -> i32 {
	return ui.FRAME_H
}
