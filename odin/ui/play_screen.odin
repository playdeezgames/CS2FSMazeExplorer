package ui

import "../game"

// Ported from PlayScreenInput.fs and PlayScreenRenderer.fs.

FIRST_STATS_COLUMN :: game.MAZE_COLUMNS
SECOND_STATS_COLUMN :: FIRST_STATS_COLUMN + (game.TILE_COLUMNS - game.MAZE_COLUMNS) / 2

// PlayScreenInput.keyCodeToCommand: an arrow key moves when the explorer already faces that way,
// and turns otherwise.
play_key :: proc(app: ^App, key: Key, now_ms: f64) -> bool {
	g := &app.world
	direction: game.Direction
	#partial switch key {
	case .Up: direction = .North
	case .Right: direction = .East
	case .Down: direction = .South
	case .Left: direction = .West
	case .Q:
		enter_score_screen(app)
		return true
	case .Space, .F1, .F3:
		// QUIRK Q7: with "Pause Game" off these do nothing (the F# just redraws the play screen).
		if app.options.pause_allowed {
			app.paused_at_ms = now_ms
			#partial switch key {
			case .Space: app.screen = .Pause
			case .F1:
				app.screen = .Help
				app.back_to_play = true
			case .F3:
				app.screen = .Options
				app.back_to_play = true
			}
		}
		return true
	case:
		return false
	}
	command := game.Command{kind = .Move} if direction == g.orientation else game.Command{kind = .Turn, direction = direction}
	app.sfx = game.act(g, command, now_ms)
	return true
}

render_item :: proc(fb: ^Framebuffer, cell: int, item: game.Item_Type, locked, game_over: bool) {
	// itemTiles only has `true` keys: an item is drawn when the game is over or its cell is open
	if !(game_over || !locked) {return}
	if tile, ok := tile_item(item); ok {
		render_tile(fb, game.cell_column(cell), game.cell_row(cell), tile)
	}
}

render_monster :: proc(fb: ^Framebuffer, cell: int, type: game.Monster_Type, locked: bool) {
	if locked {return}
	if tile, ok := tile_monster(type); ok {
		render_tile(fb, game.cell_column(cell), game.cell_row(cell), tile)
	}
}

render_walls :: proc(fb: ^Framebuffer, g: ^game.Game, cell: int) {
	render_tile(fb, game.cell_column(cell), game.cell_row(cell), tile_room(g.exits[cell]))
}

// A locked cell is a dead end, so it has exactly one exit; the lock is drawn on that side.
render_lock :: proc(fb: ^Framebuffer, g: ^game.Game, cell: int, has_key: bool) {
	if !g.locked[cell] {return}
	for d in g.exits[cell] {
		render_tile(fb, game.cell_column(cell), game.cell_row(cell), tile_lock(d, has_key))
	}
}

// PlayScreenRenderer.renderRoom. The order of the draws matters because tiles are transparent.
render_room :: proc(fb: ^Framebuffer, g: ^game.Game, cell: int, has_keys, has_amulet, game_over: bool) {
	col, row := game.cell_column(cell), game.cell_row(cell)
	visited, visible := g.visited[cell], g.visible[cell]
	item := g.items[cell]
	monster := g.monsters[cell].type
	locked := g.locked[cell]
	switch {
	case visible:
		render_tile(fb, col, row, tile_visible())
		if monster != .None {
			render_monster(fb, cell, monster, locked)
		} else {
			render_item(fb, cell, item, locked, game_over)
		}
		render_walls(fb, g, cell)
		render_lock(fb, g, cell, has_keys)
	case game_over:
		render_tile(fb, col, row, tile_empty() if visited else tile_never_visited())
		render_item(fb, cell, item, locked, game_over)
		render_walls(fb, g, cell)
		render_lock(fb, g, cell, has_keys)
	case visited:
		render_tile(fb, col, row, tile_empty())
		render_walls(fb, g, cell)
		if monster != .None {
			render_monster(fb, cell, monster, locked)
		} else if has_amulet {
			render_item(fb, cell, item, locked, game_over)
		}
		render_lock(fb, g, cell, has_keys)
	case:
		render_tile(fb, col, row, tile_hidden())
	}
}

// PlayScreenRenderer.drawMonsterStats: the monster on the cell ahead, when that cell is in view and
// not locked.
draw_monster_stats :: proc(fb: ^Framebuffer, g: ^game.Game) {
	next, ok := game.neighbor(g.position, g.orientation)
	if !ok || !g.visible[next] || g.locked[next] {return}
	instance := g.monsters[next]
	if instance.type == .None {return}
	m := game.MONSTERS[instance.type]
	buf: [16]u8
	render_string(fb, FIRST_STATS_COLUMN, 7, m.name, .Gold)
	render_string(fb, FIRST_STATS_COLUMN, 8, format_padded(buf[:], "\x03", m.health - instance.damage, 3), .Garnet)
	render_string(fb, SECOND_STATS_COLUMN, 8, format_padded(buf[:], "X", g.kills[instance.type], 3), .Tin)
	sword, _ := tile_item(.Sword)
	shield, _ := tile_item(.Shield)
	render_tile(fb, FIRST_STATS_COLUMN, 9, sword)
	render_string(fb, FIRST_STATS_COLUMN + 1, 9, format_padded(buf[:], "", m.attack, 3), .Silver)
	render_tile(fb, SECOND_STATS_COLUMN, 9, shield)
	render_string(fb, SECOND_STATS_COLUMN + 1, 9, format_padded(buf[:], "", m.defense, 3), .Aquamarine)
}

// PlayScreenRenderer.drawGameScreen.
draw_play_screen :: proc(app: ^App, now_ms: f64) {
	fb := &app.fb
	g := &app.world
	state := game.explorer_state(g, now_ms)
	game_over := state != .Alive
	has_keys := g.counters[.Keys] > 0
	has_amulet := g.counters[.Amulet] > 0

	clear(fb, .Onyx)
	for cell in 0 ..< game.MAZE_CELLS {
		render_room(fb, g, cell, has_keys, has_amulet, game_over)
	}
	render_tile(fb, game.cell_column(g.position), game.cell_row(g.position), tile_explorer(g.orientation))

	buf: [16]u8
	c := &g.counters
	render_string(fb, SECOND_STATS_COLUMN, 0, format_padded(buf[:], "$", c[.Loot], 3), .Gold)
	render_string(fb, FIRST_STATS_COLUMN + 1, 1, format_padded(buf[:], "", c[.Keys], 3), .Copper)
	render_string(fb, SECOND_STATS_COLUMN + 1, 1, format_padded(buf[:], "", c[.Potions], 3), .Amethyst)
	render_string(fb, FIRST_STATS_COLUMN + 1, 2, format_padded(buf[:], "", c[.Attack], 3), .Silver)
	render_string(fb, SECOND_STATS_COLUMN + 1, 2, format_padded(buf[:], "", c[.Defense], 3), .Aquamarine)
	render_string(fb, FIRST_STATS_COLUMN, 0, format_padded(buf[:], "\x03", c[.Health] - c[.Wounds], 3), .Garnet)
	render_string(fb, FIRST_STATS_COLUMN, 16, "\x18\x19\x1b\x1aMove", .Sapphire)
	render_string(fb, FIRST_STATS_COLUMN, 17, "[Q]uit", .Sapphire)

	render_tile(fb, FIRST_STATS_COLUMN, 1, tile_ui_key())
	potion, _ := tile_item(.Potion)
	sword, _ := tile_item(.Sword)
	shield, _ := tile_item(.Shield)
	render_tile(fb, SECOND_STATS_COLUMN, 1, potion)
	render_tile(fb, FIRST_STATS_COLUMN, 2, sword)
	render_tile(fb, SECOND_STATS_COLUMN, 2, shield)

	draw_monster_stats(fb, g)

	status_text: string
	status_color: Palette_Color
	switch state {
	case .Alive: status_text, status_color = "Alive!  ", .Emerald
	case .Dead: status_text, status_color = "Dead!   ", .Garnet
	case .Exited: status_text, status_color = "Exited! ", .Gold
	case .Out_Of_Time: status_text, status_color = "Times Up", .Garnet
	}
	render_string(fb, FIRST_STATS_COLUMN, 4, status_text, status_color)

	remaining := game.time_left_seconds(g, now_ms)
	app.shown_seconds = remaining
	if state == .Alive {
		limit := c[.Time_Limit]
		color: Palette_Color
		switch {
		case remaining > limit / 2: color = .Emerald
		case remaining > limit / 4: color = .Gold
		case: color = .Garnet
		}
		render_string(fb, game.MAZE_COLUMNS, 5, format_padded(buf[:], "Time ", remaining, 3), color)
	}
}
