package ui

import "../game"

// M2 check screen: every tile family on one frame. Replaced by the play screen in M3; kept as a
// regression picture (the test writes it to build/tile_sheet.ppm).
draw_tile_sheet :: proc(fb: ^Framebuffer) {
	clear(fb, .Onyx)
	// the 256-glyph font in a 16 by 16 grid, with the heart and arrows highlighted in color
	for cp in 0 ..< 256 {
		render_tile(fb, cp % 16, cp / 16, {FONT_PATTERNS[cp], .Transparent, .Silver})
	}
	// room walls for all sixteen exit combinations
	render_string(fb, 17, 0, "Rooms", .Gold)
	for mask in 0 ..< 16 {
		exits := transmute(bit_set[game.Direction;u8])u8(mask)
		render_tile(fb, 17 + mask % 8, 1 + mask / 8, tile_room(exits))
	}
	// locks, without and with a key, and the explorer facing each way
	render_string(fb, 17, 3, "Locks", .Gold)
	for d in game.Direction {
		render_tile(fb, 17 + int(d), 4, tile_empty())
		render_tile(fb, 17 + int(d), 4, tile_lock(d, false))
		render_tile(fb, 22 + int(d), 4, tile_empty())
		render_tile(fb, 22 + int(d), 4, tile_lock(d, true))
		render_tile(fb, 17 + int(d), 5, tile_visible())
		render_tile(fb, 17 + int(d), 5, tile_explorer(d))
	}
	// items and monsters on the visible fill
	render_string(fb, 17, 7, "Items", .Gold)
	col := 17
	for item in game.Item_Type {
		if tile, ok := tile_item(item); ok {
			render_tile(fb, col, 8, tile_visible())
			render_tile(fb, col, 8, tile)
			col += 1
		}
	}
	render_tile(fb, col, 8, tile_visible())
	render_tile(fb, col, 8, tile_ui_key())
	render_string(fb, 17, 10, "Monsters", .Gold)
	col = 17
	for type in game.Monster_Type {
		if tile, ok := tile_monster(type); ok {
			render_tile(fb, col, 11, tile_visible())
			render_tile(fb, col, 11, tile)
			col += 1
		}
	}
	// the four cell fills
	render_tile(fb, 24, 11, tile_empty())
	render_tile(fb, 25, 11, tile_visible())
	render_tile(fb, 26, 11, tile_hidden())
	render_tile(fb, 27, 11, tile_never_visited())
	// the fifteen font colors, and the glyphs the play screen uses
	render_string(fb, 17, 13, "\x03 \x18\x19\x1b\x1aMove [Q]uit", .Silver)
	colors := FONT_COLORS
	for c, i in colors {
		render_string(fb, 17 + (i % 3) * 5, 14 + i / 3, "Maze", c)
	}
}
