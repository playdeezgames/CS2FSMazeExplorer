#+build !js
package tests

import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"
import "../game"
import "../ui"

PAGE :: "odin/platform/web/page/"

// The page lists the same sound names, in the same order, as the game.Sfx enum, and every one has
// a valid WAV file next to it.
@(test)
page_sound_list_matches_the_sfx_enum :: proc(t: ^testing.T) {
	data, err := os.read_entire_file(PAGE + "platform.js", context.allocator)
	if err != nil {
		testing.expect(t, false, "cannot read platform.js (run tests from the repo root)")
		return
	}
	defer delete(data)
	text := string(data)
	start := strings.index(text, "const SFX = [")
	testing.expect(t, start >= 0)
	end := strings.index(text[start:], "];")
	testing.expect(t, end > 0)
	list := text[start + len("const SFX = [") : start + end]
	names: [dynamic]string
	defer delete(names)
	rest := list
	for {
		a := strings.index_byte(rest, '"')
		if a < 0 {break}
		b := strings.index_byte(rest[a + 1:], '"')
		if b < 0 {break}
		append(&names, rest[a + 1:a + 1 + b])
		rest = rest[a + 1 + b + 1:]
	}
	testing.expect_value(t, len(names), len(game.Sfx))
	for sfx in game.Sfx {
		i := int(sfx)
		if i >= len(names) {break}
		if sfx == .None {
			testing.expect_value(t, names[i], "")
			continue
		}
		want := strings.to_lower(fmt.tprintf("%v", sfx), context.temp_allocator)
		testing.expect_value(t, names[i], want)
		file, file_err := os.read_entire_file(fmt.tprintf("%ssfx/%s.wav", PAGE, want), context.temp_allocator)
		read_ok := file_err == nil
		testing.expectf(t, read_ok, "missing sfx/%s.wav", want)
		if read_ok {
			testing.expect(t, len(file) > 44 && string(file[0:4]) == "RIFF" && string(file[8:12]) == "WAVE")
		}
	}
}

// The page's key numbers are the ui.Key enum, by name.
@(test)
page_key_numbers_match_the_key_enum :: proc(t: ^testing.T) {
	data, err := os.read_entire_file(PAGE + "platform.js", context.allocator)
	if err != nil {
		testing.expect(t, false, "cannot read platform.js")
		return
	}
	defer delete(data)
	text := string(data)
	for key in ui.Key {
		if key == .None {continue}
		name := fmt.tprintf("%v", key)
		want := fmt.tprintf("%s: %d", name, int(key))
		testing.expectf(t, strings.contains(text, want), "platform.js KEY lacks `%s`", want)
	}
}
