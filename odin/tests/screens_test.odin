#+build !js
package tests

import "core:testing"
import "../game"
import "../ui"

// An app at the title screen, as the page starts it.
title_app :: proc() -> ^ui.App {
	app := new(ui.App)
	ui.app_init(app, 5)
	return app
}

@(test)
title_menu_keys :: proc(t: ^testing.T) {
	app := title_app()
	defer free(app)
	testing.expect_value(t, app.screen, ui.Screen.Title)
	testing.expect(t, !ui.app_key(app, .Up, NOW))
	testing.expect(t, !ui.app_key(app, .Space, NOW))
	testing.expect(t, !ui.app_key(app, .Q, NOW))
	testing.expect(t, ui.app_key(app, .F1, NOW))
	testing.expect_value(t, app.screen, ui.Screen.Help)
	testing.expect(t, !ui.app_key(app, .Space, NOW)) // only Esc leaves help
	testing.expect(t, ui.app_key(app, .Escape, NOW))
	testing.expect_value(t, app.screen, ui.Screen.Title)
	ui.app_key(app, .F3, NOW)
	testing.expect_value(t, app.screen, ui.Screen.Options)
	ui.app_key(app, .Escape, NOW)
	testing.expect_value(t, app.screen, ui.Screen.Title)
	ui.app_key(app, .F2, NOW)
	testing.expect_value(t, app.screen, ui.Screen.Play)
}

@(test)
options_change_and_apply_to_the_next_game :: proc(t: ^testing.T) {
	app := title_app()
	defer free(app)
	ui.app_key(app, .F3, NOW)
	testing.expect_value(t, app.options.difficulty, game.Difficulty.Normal)
	ui.app_key(app, .Up, NOW)
	testing.expect_value(t, app.options.difficulty, game.Difficulty.Hard)
	ui.app_key(app, .Up, NOW) // stays at Hard
	testing.expect_value(t, app.options.difficulty, game.Difficulty.Hard)
	for _ in 0 ..< 3 {ui.app_key(app, .Down, NOW)}
	testing.expect_value(t, app.options.difficulty, game.Difficulty.Easy)
	ui.app_key(app, .M, NOW)
	ui.app_key(app, .P, NOW)
	testing.expect(t, !app.options.sfx && !app.options.pause_allowed)
	testing.expect(t, app.settings_dirty)
	ui.app_key(app, .Escape, NOW)
	ui.app_key(app, .F2, NOW)
	testing.expect_value(t, app.world.difficulty, game.Difficulty.Easy)
	testing.expect_value(t, app.world.counters[.Health], 10)
	// a muted game plays nothing
	app.sfx = .Fight
	testing.expect_value(t, ui.app_take_sfx(app), game.Sfx.None)
}

@(test)
pause_keeps_the_remaining_time :: proc(t: ^testing.T) {
	app := title_app()
	defer free(app)
	ui.app_key(app, .F2, NOW)
	before := game.time_left_seconds(&app.world, NOW + 10_000)
	ui.app_key(app, .Space, NOW + 10_000)
	testing.expect_value(t, app.screen, ui.Screen.Pause)
	testing.expect(t, !ui.app_key(app, .Escape, NOW + 20_000)) // only Space resumes
	testing.expect(t, !ui.app_key(app, .Up, NOW + 20_000))
	ui.app_key(app, .Space, NOW + 70_000) // a minute away
	testing.expect_value(t, app.screen, ui.Screen.Play)
	testing.expect_value(t, game.time_left_seconds(&app.world, NOW + 70_000), before)
}

@(test)
help_and_options_from_play_resume_with_time_kept :: proc(t: ^testing.T) {
	app := title_app()
	defer free(app)
	ui.app_key(app, .F2, NOW)
	before := game.time_left_seconds(&app.world, NOW)
	ui.app_key(app, .F1, NOW)
	testing.expect_value(t, app.screen, ui.Screen.Help)
	ui.app_key(app, .Escape, NOW + 30_000)
	testing.expect_value(t, app.screen, ui.Screen.Play)
	testing.expect_value(t, game.time_left_seconds(&app.world, NOW + 30_000), before)
	ui.app_key(app, .F3, NOW + 30_000)
	testing.expect_value(t, app.screen, ui.Screen.Options)
	ui.app_key(app, .Up, NOW + 30_000) // does not touch the game in progress
	testing.expect_value(t, app.world.difficulty, game.Difficulty.Normal)
	ui.app_key(app, .Escape, NOW + 45_000)
	testing.expect_value(t, app.screen, ui.Screen.Play)
	testing.expect_value(t, game.time_left_seconds(&app.world, NOW + 45_000), before)
}

@(test)
pause_not_allowed_blocks_pause_help_and_options_in_play :: proc(t: ^testing.T) { // Q7
	app := title_app()
	defer free(app)
	ui.app_key(app, .F3, NOW)
	ui.app_key(app, .P, NOW)
	ui.app_key(app, .Escape, NOW)
	ui.app_key(app, .F2, NOW)
	for key in ([3]ui.Key{.Space, .F1, .F3}) {
		testing.expect(t, ui.app_key(app, key, NOW))
		testing.expect_value(t, app.screen, ui.Screen.Play)
	}
}

@(test)
quit_shows_score_and_records_best_per_difficulty :: proc(t: ^testing.T) {
	app := title_app()
	defer free(app)
	ui.app_key(app, .F2, NOW)
	app.world.counters[.Loot] = 4 // 40
	app.world.kills[.Zombie] = 1 // 40
	ui.app_key(app, .Q, NOW)
	testing.expect_value(t, app.screen, ui.Screen.Score)
	testing.expect_value(t, app.best[.Normal], 80)
	testing.expect(t, app.new_best)
	testing.expect(t, app.settings_dirty)
	ui.app_draw(app, NOW)
	testing.expect(t, !ui.app_key(app, .Space, NOW)) // only Esc
	ui.app_key(app, .Escape, NOW)
	testing.expect_value(t, app.screen, ui.Screen.Title)
	// a worse game does not replace it
	ui.app_key(app, .F2, NOW)
	app.world.counters[.Loot] = 1
	ui.app_key(app, .Q, NOW)
	testing.expect_value(t, app.best[.Normal], 80)
	testing.expect(t, !app.new_best)
	testing.expect_value(t, app.best[.Easy], 0)
}

@(test)
every_screen_draws_something_distinct :: proc(t: ^testing.T) {
	app := title_app()
	defer free(app)
	hashes: [dynamic]u64
	defer delete(hashes)
	for step in 0 ..< 6 {
		app.dirty = true
		testing.expect(t, ui.app_draw(app, NOW))
		append(&hashes, fnv1a(app.fb.pixels[:]))
		switch step {
		case 0: ui.app_key(app, .F1, NOW) // help
		case 1:
			ui.app_key(app, .Escape, NOW)
			ui.app_key(app, .F3, NOW) // options
		case 2:
			ui.app_key(app, .Escape, NOW)
			ui.app_key(app, .F2, NOW) // play
		case 3: ui.app_key(app, .Space, NOW) // pause
		case 4:
			ui.app_key(app, .Space, NOW)
			ui.app_key(app, .Q, NOW) // score
		}
	}
	for i in 0 ..< len(hashes) {
		for j in i + 1 ..< len(hashes) {
			testing.expect(t, hashes[i] != hashes[j])
		}
	}
	// the title and pause backgrounds are the original's colours
	ui.app_key(app, .Escape, NOW)
	app.dirty = true
	ui.app_draw(app, NOW)
	testing.expect_value(t, app.fb.pixels[0], ui.PALETTE[.Turquoise]) // title background
}

@(test)
settings_round_trip_and_strict_loading :: proc(t: ^testing.T) {
	a := title_app()
	defer free(a)
	a.options = {sfx = false, pause_allowed = true, difficulty = .Hard}
	a.best = {.Easy = 120, .Normal = 0, .Hard = 9_999_999}
	text := ui.settings_encode(a)
	testing.expect_value(t, text, "MX1 0 1 2 120 0 9999999")
	b := title_app()
	defer free(b)
	testing.expect(t, ui.settings_decode(b, text))
	testing.expect_value(t, b.options, a.options)
	testing.expect_value(t, b.best, a.best)

	bad := [?]string {
		"", "MX1", "MX2 1 1 1 0 0 0", "MX1 2 1 1 0 0 0", "MX1 1 1 3 0 0 0", "MX1 1 1 1 -1 0 0",
		"MX1 1 1 1 0 0", "MX1 1 1 1 0 0 0 0", "MX1 1 1 1 10000000 0 0", "MX1 1 1 1 a 0 0", "MX1  1 1 1 0 0 0",
		"MX1 1 1 1 0 0 000000000",
	}
	for s in bad {
		c := title_app()
		before := c^
		testing.expectf(t, !ui.settings_decode(c, s), "accepted %q", s)
		testing.expect(t, c.options == before.options && c.best == before.best)
		free(c)
	}
}
