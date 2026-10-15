#+build !js
package replay

// The native half of the wasm-versus-native parity check (tools/parity.sh): plays a seed and a key
// script through the same ui package the web build uses, on a fake clock, and prints a digest of
// every frame drawn. tools/wasm_node.js does the same through the wasm build; the output must be
// identical.
//
//   replay <seed> <comma separated ui.Key numbers> [step_ms]

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "../../ui"

main :: proc() {
	if len(os.args) < 3 {
		fmt.eprintln("usage: replay <seed> <keys> [step_ms]")
		os.exit(2)
	}
	seed, seed_ok := strconv.parse_u64(os.args[1])
	if !seed_ok {
		fmt.eprintln("bad seed")
		os.exit(2)
	}
	step_ms := 900.0
	if len(os.args) > 3 {
		if v, ok := strconv.parse_f64(os.args[3]); ok {step_ms = v}
	}

	app := new(ui.App)
	ui.app_init(app, seed)
	digest := ui.FNV64_OFFSET
	frames := 0
	now := 1000.0

	if ui.app_draw(app, now) {
		digest = ui.digest_fold(digest, ui.frame_hash64(&app.fb))
		frames += 1
	}
	keys, _ := strings.split(os.args[2], ",")
	for text, i in keys {
		code, ok := strconv.parse_int(text)
		if !ok || code <= 0 || code > int(max(ui.Key)) {continue}
		now = 1000.0 + f64(i + 1) * step_ms
		ui.app_key(app, ui.Key(code), now)
		ui.app_take_sfx(app)
		if ui.app_draw(app, now) {
			digest = ui.digest_fold(digest, ui.frame_hash64(&app.fb))
			frames += 1
		}
	}
	fmt.printf("digest %016x\n", digest)
	fmt.printf("last %08x\n", ui.frame_hash32(&app.fb))
	fmt.printf("frames %d screen %d\n", frames, int(app.screen))
}
