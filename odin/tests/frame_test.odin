#+build !js
package tests

import "core:fmt"
import "core:os"
import "core:testing"
import "../game"
import "../ui"

@(test)
frame_is_32_by_18_cells_of_8_pixels :: proc(t: ^testing.T) {
	testing.expect_value(t, ui.FRAME_W, 256)
	testing.expect_value(t, ui.FRAME_H, 144)
	testing.expect_value(t, game.MAZE_COLUMNS + 8, game.TILE_COLUMNS)
}

@(test)
palette_matches_colors_fs :: proc(t: ^testing.T) {
	testing.expect_value(t, ui.PALETTE[.Garnet], ui.rgb(128, 32, 32))
	testing.expect_value(t, ui.PALETTE[.Onyx], ui.rgb(32, 32, 32))
	testing.expect_value(t, ui.PALETTE[.Lightest_Tone], ui.rgb(255, 144, 144))
	testing.expect_value(t, ui.PALETTE[.Transparent], u32(0))
	for c in ui.Palette_Color {
		if c != .Transparent {
			testing.expect_value(t, ui.PALETTE[c] >> 24, u32(0xFF))
		}
	}
}

@(test)
transparent_background_leaves_what_is_underneath :: proc(t: ^testing.T) {
	fb := new(ui.Framebuffer)
	defer free(fb)
	ui.clear(fb, .Copper)
	// the Exit pattern is not solid: Onyx where the pattern is set, Copper left alone elsewhere
	tile, _ := ui.tile_item(.Exit)
	ui.render_tile(fb, 3, 2, tile)
	onyx, copper := 0, 0
	for py in 0 ..< 8 {
		for px in 0 ..< 8 {
			p := fb.pixels[(2 * 8 + py) * ui.FRAME_W + 3 * 8 + px]
			if p == ui.PALETTE[.Onyx] {onyx += 1}
			if p == ui.PALETTE[.Copper] {copper += 1}
		}
	}
	testing.expect(t, onyx > 0 && copper > 0 && onyx + copper == 64)
	// and the cell next door is untouched
	testing.expect_value(t, fb.pixels[2 * 8 * ui.FRAME_W + 4 * 8], ui.PALETTE[.Copper])
}

@(test)
opaque_fills_cover_the_whole_cell :: proc(t: ^testing.T) {
	fb := new(ui.Framebuffer)
	defer free(fb)
	ui.clear(fb, .Onyx)
	ui.render_tile(fb, 0, 0, ui.tile_empty())
	ui.render_tile(fb, 1, 0, ui.tile_visible())
	ui.render_tile(fb, 2, 0, ui.tile_never_visited())
	for x in 0 ..< 8 {
		for y in 0 ..< 8 {
			testing.expect_value(t, fb.pixels[y * ui.FRAME_W + x], ui.PALETTE[.Tin])
			testing.expect_value(t, fb.pixels[y * ui.FRAME_W + 8 + x], ui.PALETTE[.Copper])
			testing.expect_value(t, fb.pixels[y * ui.FRAME_W + 16 + x], ui.PALETTE[.Carnelian])
		}
	}
}

@(test)
hidden_tile_is_a_question_mark_on_jade :: proc(t: ^testing.T) {
	fb := new(ui.Framebuffer)
	defer free(fb)
	ui.render_tile(fb, 0, 0, ui.tile_hidden())
	jade, onyx := 0, 0
	for y in 0 ..< 8 {
		for x in 0 ..< 8 {
			p := fb.pixels[y * ui.FRAME_W + x]
			if p == ui.PALETTE[.Jade] {jade += 1}
			if p == ui.PALETTE[.Onyx] {onyx += 1}
		}
	}
	testing.expect_value(t, jade + onyx, 64)
	testing.expect(t, onyx > 8 && onyx < 32)
}

@(test)
strings_use_one_cell_per_byte_and_clip_at_the_edge :: proc(t: ^testing.T) {
	fb := new(ui.Framebuffer)
	defer free(fb)
	ui.clear(fb, .Onyx)
	ui.render_string(fb, 30, 17, "ABCDEF", .Gold) // runs off the right edge: clipped, no crash
	ui.render_string(fb, -2, 0, "AB", .Gold)
	gold := 0
	for p in fb.pixels {
		if p == ui.PALETTE[.Gold] {gold += 1}
	}
	testing.expect(t, gold > 0)
	// \x03 (heart) is not the same picture as 'A'
	testing.expect(t, ui.FONT_PATTERNS[3] != ui.FONT_PATTERNS['A'])
	// the original maps code point 16 to the pattern of character 6 (Q11)
	testing.expect_value(t, ui.FONT_PATTERNS[16], ui.FONT_PATTERNS[6])
}

@(test)
tile_sheet_is_opaque_and_written_to_ppm :: proc(t: ^testing.T) {
	fb := new(ui.Framebuffer)
	defer free(fb)
	ui.draw_tile_sheet(fb)
	for p, i in fb.pixels {
		if p >> 24 != 0xFF {
			testing.expectf(t, false, "pixel %d is not opaque: %x", i, p)
			return
		}
	}
	// a PPM for looking at (tools turn it into a PNG); failure to write is not a test failure
	data := make([dynamic]u8)
	defer delete(data)
	append(&data, fmt.tprintf("P6\n%d %d\n255\n", ui.FRAME_W, ui.FRAME_H))
	for p in fb.pixels {
		append(&data, u8(p), u8(p >> 8), u8(p >> 16))
	}
	_ = os.make_directory("build")
	_ = os.write_entire_file("build/tile_sheet.ppm", data[:])
}
