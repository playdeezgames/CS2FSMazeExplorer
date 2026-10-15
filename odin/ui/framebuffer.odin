package ui

import "../game"

// FrameBuffer.fs: a 32 by 18 board of 8 by 8 pixel cells.
CELL_SIZE :: 8
FRAME_W :: game.TILE_COLUMNS * CELL_SIZE
FRAME_H :: game.TILE_ROWS * CELL_SIZE

// Pixels are bytes R, G, B, A in memory (a little-endian u32 is A<<24 | B<<16 | G<<8 | R).
Framebuffer :: struct {
	pixels: [FRAME_W * FRAME_H]u32,
}

rgb :: proc(r, g, b: u8) -> u32 {
	return 0xFF000000 | u32(b) << 16 | u32(g) << 8 | u32(r)
}

clear :: proc(fb: ^Framebuffer, color: Palette_Color) {
	c := PALETTE[color]
	for i in 0 ..< len(fb.pixels) {
		fb.pixels[i] = c
	}
}

set_pixel :: proc(fb: ^Framebuffer, x, y: int, color: u32) {
	if x < 0 || y < 0 || x >= FRAME_W || y >= FRAME_H {return}
	fb.pixels[y * FRAME_W + x] = color
}

// FrameBuffer.RenderTile: draws an 8 by 8 tile at a cell. Transparent pixels (alpha 0) leave what
// is already there, as GDI+ source-over does; anything off the board is clipped.
render_tile :: proc(fb: ^Framebuffer, column, row: int, tile: Tile) {
	fg := PALETTE[tile.foreground]
	bg := PALETTE[tile.background]
	for py in 0 ..< CELL_SIZE {
		bits := tile.pattern[py]
		for px in 0 ..< CELL_SIZE {
			color := fg if bits & (0x80 >> uint(px)) != 0 else bg
			if color >> 24 == 0 {continue}
			set_pixel(fb, column * CELL_SIZE + px, row * CELL_SIZE + py, color)
		}
	}
}

// FrameBuffer.renderString: one cell per byte, the byte being the code point of the 8 by 8 font
// (code page 437 style; \x03 is the heart, \x18 to \x1B the arrows).
render_string :: proc(fb: ^Framebuffer, column, row: int, text: string, color: Palette_Color) {
	for i in 0 ..< len(text) {
		render_tile(fb, column + i, row, {FONT_PATTERNS[text[i]], .Transparent, color})
	}
}
