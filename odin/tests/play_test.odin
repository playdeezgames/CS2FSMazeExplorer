#+build !js
package tests

import "core:log"
import "core:testing"
import "../game"
import "../ui"

new_app :: proc() -> ^ui.App {
	app := new(ui.App)
	ui.app_init(app, 1)
	app.screen = .Play
	return app
}

pixel :: proc(app: ^ui.App, x, y: int) -> u32 {
	return app.fb.pixels[y * ui.FRAME_W + x]
}

// how many pixels of `color` lie in the cell rectangle [c0, c1) by [r0, r1)
count_color :: proc(app: ^ui.App, color: ui.Palette_Color, c0, r0, c1, r1: int) -> int {
	n := 0
	for y in r0 * 8 ..< r1 * 8 {
		for x in c0 * 8 ..< c1 * 8 {
			if pixel(app, x, y) == ui.PALETTE[color] {n += 1}
		}
	}
	return n
}

@(test)
arrow_turns_then_moves :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 4)
	app.screen = .Play
	testing.expect(t, ui.app_key(app, .Up, NOW))
	testing.expect_value(t, app.world.orientation, game.Direction.North)
	testing.expect_value(t, app.world.position, 0)
	ui.app_key(app, .Right, NOW) // turn east
	testing.expect_value(t, app.world.position, 0)
	ui.app_key(app, .Right, NOW) // now facing east: move
	testing.expect_value(t, app.world.position, 1)
	// a wall to the north: facing it, the arrow bumps and the page is told to play Blocked
	ui.app_key(app, .Up, NOW)
	ui.app_key(app, .Up, NOW)
	testing.expect_value(t, ui.app_take_sfx(app), game.Sfx.Blocked)
	testing.expect_value(t, ui.app_take_sfx(app), game.Sfx.None)
	testing.expect(t, !ui.app_key(app, .M, NOW)) // not a play key: no redraw
}

@(test)
q_goes_to_the_score_screen :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 4)
	app.screen = .Play
	testing.expect(t, ui.app_key(app, .Q, NOW))
	testing.expect_value(t, app.screen, ui.Screen.Score)
}

@(test)
hidden_visible_and_visited_cells_are_drawn_differently :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 4)
	app.dirty = true
	ui.app_draw(app, NOW)
	// a cell nobody has seen: the '?' tile, whose top-left pixel is the Jade background
	testing.expect_value(t, pixel(app, 10 * 8, 10 * 8), ui.PALETTE[.Jade])
	// a cell in the ray: Copper fill inside its walls (cell 2, column 2, row 0)
	testing.expect_value(t, pixel(app, 2 * 8 + 3, 3), ui.PALETTE[.Copper])
	// the explorer (Silver) on cell 0
	testing.expect(t, count_color(app, .Silver, 0, 0, 1, 1) > 0)
	// turn away: the ray is now only cell 0, and the corridor becomes visited (Tin fill)
	ui.app_key(app, .Up, NOW)
	ui.app_draw(app, NOW)
	testing.expect_value(t, pixel(app, 2 * 8 + 3, 3), ui.PALETTE[.Tin])
	testing.expect_value(t, pixel(app, 3, 0), ui.PALETTE[.Emerald]) // a wall of cell 0 still drawn
}

@(test)
items_and_monsters_follow_locks_and_the_amulet :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 4)
	w := &app.world
	w.items[2] = .Treasure
	w.items[3] = .Key
	w.locked[3] = true
	w.monsters[1] = {.Zombie, 0}
	ui.app_draw(app, NOW)
	testing.expect(t, count_color(app, .Jade, 1, 0, 2, 1) > 0) // zombie drawn (Jade) on cell 1
	testing.expect(t, count_color(app, .Gold, 2, 0, 3, 1) > 0) // treasure on the open cell 2
	// cell 3 is locked: the key inside stays hidden, and the lock is Onyx without a key
	testing.expect_value(t, count_color(app, .Gold, 3, 0, 4, 1), 0)
	// with a key the lock is drawn Gold
	w.counters[.Keys] = 1
	app.dirty = true
	ui.app_draw(app, NOW)
	testing.expect(t, count_color(app, .Gold, 3, 0, 4, 1) > 0)
}

@(test)
game_over_reveals_the_whole_maze :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 4)
	app.world.counters[.Wounds] = 10 // dead
	app.dirty = true
	ui.app_draw(app, NOW)
	// a never-visited cell shows the Carnelian fill
	testing.expect_value(t, pixel(app, 10 * 8 + 3, 10 * 8 + 3), ui.PALETTE[.Carnelian])
	testing.expect(t, count_color(app, .Garnet, 24, 4, 32, 5) > 0) // "Dead!"
}

@(test)
clock_colour_follows_the_remaining_time :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 2)
	// 480 s limit: more than half green, more than a quarter gold, else red
	for tc in ([?]struct {
			elapsed_s: f64,
			color:     ui.Palette_Color,
		}{{0, .Emerald}, {239, .Emerald}, {240, .Gold}, {359, .Gold}, {360, .Garnet}, {470, .Garnet}}) {
		app.dirty = true
		ui.app_draw(app, NOW + tc.elapsed_s * 1000)
		testing.expectf(t, count_color(app, tc.color, 24, 5, 32, 6) > 0, "elapsed %v", tc.elapsed_s)
	}
	// out of time: no clock, and the status says so
	app.dirty = true
	ui.app_draw(app, NOW + 481_000)
	testing.expect_value(t, count_color(app, .Emerald, 24, 5, 32, 6), 0)
	testing.expect(t, count_color(app, .Garnet, 24, 4, 32, 5) > 0)
}

@(test)
redraws_only_when_the_second_changes :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 2)
	app.dirty = true
	testing.expect(t, ui.app_draw(app, NOW)) // shows 480
	testing.expect(t, !ui.app_draw(app, NOW))
	testing.expect(t, !ui.app_draw(app, NOW + 200)) // 479.8 rounds up to 480 (Q3)
	testing.expect(t, ui.app_draw(app, NOW + 1200)) // 478.8: 479
	testing.expect(t, !ui.app_draw(app, NOW + 1900)) // 478.1: still 479
	testing.expect(t, ui.app_draw(app, NOW + 2200)) // 477.8: 478
}

@(test)
monster_stats_show_for_the_cell_ahead :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	corridor(&app.world, 3)
	app.world.monsters[1] = {.Mummy, 1}
	app.world.kills[.Mummy] = 2
	app.dirty = true
	ui.app_draw(app, NOW)
	testing.expect(t, count_color(app, .Gold, 24, 7, 32, 8) > 0) // "Mummy"
	testing.expect(t, count_color(app, .Garnet, 24, 8, 28, 9) > 0) // health left
	testing.expect(t, count_color(app, .Tin, 28, 8, 32, 9) > 0) // kills
	testing.expect(t, count_color(app, .Aquamarine, 28, 9, 32, 10) > 0) // defence
	// facing away: no stats
	ui.app_key(app, .Up, NOW)
	ui.app_draw(app, NOW)
	testing.expect_value(t, count_color(app, .Gold, 24, 7, 32, 8), 0)
}

fnv1a :: proc(pixels: []u32) -> u64 {
	fb := new(ui.Framebuffer)
	defer free(fb)
	copy(fb.pixels[:], pixels)
	return ui.frame_hash64(fb)
}

// A regression pin: the first frame of three seeded games. If maze generation, item placement or
// the renderer changes on purpose, update the numbers (the log prints the new ones).
@(test)
first_frames_are_stable :: proc(t: ^testing.T) {
	app := new_app()
	defer free(app)
	expected := [3]u64{0xcacccb7648116805, 0xb1eeb416eb43ab85, 0xe7cd36561106d5c5}
	for seed, i in ([3]u64{1, 2, 3}) {
		ui.app_init(app, seed)
		ui.app_new_game(app, NOW)
		ui.app_draw(app, NOW)
		h := fnv1a(app.fb.pixels[:])
		log.infof("seed %d first frame hash %x", seed, h)
		testing.expectf(t, h == expected[i], "seed %d: %x", seed, h)
	}
}

@(test)
numbers_are_space_padded_like_sprintf :: proc(t: ^testing.T) {
	buf: [32]u8
	testing.expect_value(t, ui.format_padded(buf[:], "", 7, 3), "  7")
	testing.expect_value(t, ui.format_padded(buf[:], "$", 0, 3), "$  0")
	testing.expect_value(t, ui.format_padded(buf[:], "\x03", 42, 3), "\x03 42")
	testing.expect_value(t, ui.format_padded(buf[:], "Time ", 480, 3), "Time 480")
	testing.expect_value(t, ui.format_padded(buf[:], "", 1234, 3), "1234")
	testing.expect_value(t, ui.format_padded(buf[:], "", -5, 3), " -5")
	testing.expect_value(t, ui.format_padded(buf[:], "Grand Total", 1720, 6), "Grand Total  1720")
}
