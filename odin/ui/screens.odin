package ui

import "../game"

// Ported from TitleScreenRenderer.fs, HelpScreenRenderer.fs, OptionsScreenRenderer.fs,
// PauseScreenRenderer.fs and ScoreScreenRenderer.fs.

// exits as the F# (north, east, south, west) booleans
exits_nesw :: proc(n, e, s, w: bool) -> bit_set[game.Direction;u8] {
	r: bit_set[game.Direction;u8]
	if n {r += {.North}}
	if e {r += {.East}}
	if s {r += {.South}}
	if w {r += {.West}}
	return r
}

draw_title_screen :: proc(app: ^App) {
	fb := &app.fb
	clear(fb, .Turquoise)
	render_string(fb, 9, 4, "Maze  Explorer", .Sapphire)
	render_string(fb, 9, 15, "F1 - Help    ", .Garnet)
	render_string(fb, 9, 16, "F2 - New Game", .Garnet)
	render_string(fb, 9, 17, "F3 - Options ", .Garnet)

	// a little picture of a maze, drawn in the original's order (14 columns right, 7 rows down)
	T :: struct {
		tile: Tile,
		x, y: int,
	}
	key, _ := tile_item(.Key)
	tiles := [?]T {
		{tile_empty(), 0, 0}, {tile_empty(), 1, 0}, {tile_empty(), 0, 1}, {tile_empty(), 0, 2}, {tile_empty(), 0, 3},
		{tile_visible(), 2, 0}, {tile_visible(), 2, 1},
		{tile_hidden(), 1, 1}, {tile_hidden(), 1, 2}, {tile_hidden(), 1, 3}, {tile_hidden(), 2, 2}, {tile_hidden(), 2, 3},
		{tile_hidden(), 3, 0}, {tile_hidden(), 3, 1}, {tile_hidden(), 3, 2}, {tile_hidden(), 3, 3},
		{tile_room(exits_nesw(false, true, true, true)), 0, 0},
		{tile_room(exits_nesw(false, true, false, true)), 1, 0},
		{tile_room(exits_nesw(false, false, true, true)), 2, 0},
		{tile_room(exits_nesw(true, true, true, false)), 0, 1},
		{tile_room(exits_nesw(true, false, false, false)), 2, 1},
		{tile_room(exits_nesw(true, false, true, true)), 0, 2},
		{tile_room(exits_nesw(true, false, true, false)), 0, 3},
		{tile_explorer(.South), 2, 0},
		{key, 2, 1},
	}
	for e in tiles {
		render_tile(fb, e.x + 14, e.y + 7, e.tile)
	}
}

draw_help_screen :: proc(app: ^App) {
	fb := &app.fb
	clear(fb, .Sapphire)
	render_string(fb, 0, 0, "Help", .Silver)
	labels := [?]string {
		"Treasure", "Trap", "Key", "Sword", "Shield", "Love Interest", "Hourglass", "Explorer",
		"Visited Room", "Visible Room", "Locked Room", "Unexplored", "Potion", "Amulet", "Stairs",
	}
	for label, i in labels {
		render_string(fb, 2, 1 + i, label, .Onyx)
	}
	render_string(fb, 0, 17, "Esc - Go Back", .Tanzanite)
	monsters := [?]string{"Skeleton", "Zombie", "Mummy", "Ghoul", "Golem", "Wizard"}
	for label, i in monsters {
		render_string(fb, game.TILE_COLUMNS / 2 + 2, 1 + i, label, .Onyx)
	}

	items := [?]game.Item_Type{.Treasure, .Trap, .Key, .Sword, .Shield, .Love_Interest, .Hourglass}
	for item, i in items {
		tile, _ := tile_item(item)
		render_tile(fb, 0, 1 + i, tile)
	}
	east_only := tile_room(exits_nesw(false, true, false, false))
	render_tile(fb, 0, 8, tile_explorer(.North))
	render_tile(fb, 0, 9, tile_empty())
	render_tile(fb, 0, 9, east_only)
	render_tile(fb, 0, 10, tile_visible())
	render_tile(fb, 0, 10, east_only)
	render_tile(fb, 0, 11, tile_empty())
	render_tile(fb, 0, 11, east_only)
	render_tile(fb, 0, 11, tile_lock(.East, false))
	render_tile(fb, 0, 12, tile_hidden())
	potion, _ := tile_item(.Potion)
	amulet, _ := tile_item(.Amulet)
	exit, _ := tile_item(.Exit)
	render_tile(fb, 0, 13, potion)
	render_tile(fb, 0, 14, amulet)
	render_tile(fb, 0, 15, exit)
	types := [?]game.Monster_Type{.Skeleton, .Zombie, .Mummy, .Ghoul, .Golem, .Wizard}
	for type, i in types {
		tile, _ := tile_monster(type)
		render_tile(fb, game.TILE_COLUMNS / 2, 1 + i, tile)
	}
}

draw_options_screen :: proc(app: ^App) {
	fb := &app.fb
	o := app.options
	clear(fb, .Amethyst)
	render_string(fb, 0, 0, "Game Options", .Silver)
	if o.sfx {
		render_string(fb, 0, 2, "Sounds: ON", .Emerald)
		render_string(fb, 0, 3, "[M]ute sounds", .Tin)
	} else {
		render_string(fb, 0, 2, "Sounds: OFF", .Garnet)
		render_string(fb, 0, 3, "Un[m]ute sounds", .Tin)
	}
	if o.pause_allowed {
		render_string(fb, 0, 5, "Pause Game: ON", .Emerald)
		render_string(fb, 0, 6, "Disallow [P]ause", .Tin)
	} else {
		render_string(fb, 0, 5, "Pause Game: OFF", .Garnet)
		render_string(fb, 0, 6, "Allow [P]ause", .Tin)
	}
	switch o.difficulty {
	case .Easy: render_string(fb, 0, 8, "Difficulty: Easy", .Emerald)
	case .Normal: render_string(fb, 0, 8, "Difficulty: Normal", .Gold)
	case .Hard: render_string(fb, 0, 8, "Difficulty: Hard", .Garnet)
	}
	render_string(fb, 0, 9, "[\x18/\x19] Change Difficulty", .Tin)
	render_string(fb, 0, 10, "(Difficulty changes will not", .Copper)
	render_string(fb, 0, 11, "affect games in progress)", .Copper)
	render_string(fb, 0, 17, "Esc - Go Back", .Aquamarine)
}

draw_pause_screen :: proc(app: ^App) {
	clear(&app.fb, .Carnelian)
	render_string(&app.fb, 10, 9, "***PAUSED***", .Garnet)
	render_string(&app.fb, 8, 17, "SPACE -  Unpause", .Gold)
}

// "%4s%2i@%3i=%5i": name, count, points each, line total.
@(private = "file")
score_line :: proc(b: ^Builder, name: string, count, each, total: int) {
	for _ in len(name) ..< 4 {builder_str(b, " ")}
	builder_str(b, name)
	builder_int(b, count, 2)
	builder_str(b, "@")
	builder_int(b, each, 3)
	builder_str(b, "=")
	builder_int(b, total, 5)
}

draw_score_screen :: proc(app: ^App) {
	fb := &app.fb
	g := &app.world
	clear(fb, .Silver)
	render_string(fb, 0, 0, "Final Score", .Onyx)
	render_string(fb, 0, 17, "Esc - Main Menu", .Onyx)

	row := 2
	item_total := 0
	for r in game.SCORE_ROWS {
		count := g.counters[r.counter]
		b: Builder
		score_line(&b, r.name, count, r.value, count * r.value)
		render_string(fb, 0, row, builder_string(&b), .Onyx)
		item_total += count * r.value
		row += 1
	}
	{
		b: Builder
		builder_str(&b, "Item Total")
		builder_int(&b, item_total, 6)
		render_string(fb, 0, row, builder_string(&b), .Onyx)
	}

	// only the monster types that were killed, in the original's order
	monster_row := 2
	monster_total := 0
	for type in game.Monster_Type {
		if type == .None || g.kills[type] == 0 {continue}
		m := game.MONSTERS[type]
		b: Builder
		score_line(&b, m.abbr, g.kills[type], m.score, g.kills[type] * m.score)
		render_string(fb, game.TILE_COLUMNS / 2, monster_row, builder_string(&b), .Onyx)
		monster_total += g.kills[type] * m.score
		monster_row += 1
	}
	{
		b: Builder
		builder_str(&b, "Mon. Total")
		builder_int(&b, monster_total, 6)
		render_string(fb, game.TILE_COLUMNS / 2, monster_row, builder_string(&b), .Onyx)
	}
	{
		b: Builder
		builder_str(&b, "Grand Total")
		builder_int(&b, monster_total + item_total, 6)
		render_string(fb, 0, row + 2, builder_string(&b), .Onyx)
	}

	// D11, beyond the original: the best grand total for this difficulty
	{
		b: Builder
		builder_str(&b, "Best ")
		switch g.difficulty {
		case .Easy: builder_str(&b, "(Easy)")
		case .Normal: builder_str(&b, "(Normal)")
		case .Hard: builder_str(&b, "(Hard)")
		}
		builder_int(&b, app.best[g.difficulty], 6)
		render_string(fb, 0, row + 4, builder_string(&b), .Onyx)
		if app.new_best {
			render_string(fb, 20, row + 4, "New best!", .Garnet)
		}
	}
}
