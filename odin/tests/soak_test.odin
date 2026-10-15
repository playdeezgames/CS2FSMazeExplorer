#+build !js
package tests

import "core:log"
import "core:testing"
import "../game"
import "../ui"

// Invariants that must hold after every action of any play, however silly.
check_world :: proc(t: ^testing.T, g: ^game.Game, label: string) -> bool {
	c := g.counters
	ok := true
	check :: proc(t: ^testing.T, cond: bool, label, what: string, ok: ^bool) {
		if !cond {
			testing.expectf(t, false, "%s: %s", label, what)
			ok^ = false
		}
	}
	check(t, g.position >= 0 && g.position < game.MAZE_CELLS, label, "position off the grid", &ok)
	check(t, g.visible[g.position], label, "explorer cell not visible", &ok)
	check(t, g.visited[g.position], label, "explorer cell not visited", &ok)
	check(t, g.items[g.position] == .None, label, "item left under the explorer", &ok)
	check(t, g.monsters[g.position].type == .None, label, "monster under the explorer", &ok)
	check(t, !g.locked[g.position], label, "explorer on a locked cell", &ok)
	check(t, c[.Wounds] >= 0 && c[.Wounds] <= c[.Health], label, "wounds out of range", &ok)
	check(t, c[.Health] >= 1, label, "health below 1", &ok)
	check(t, c[.Keys] >= 0 && c[.Potions] >= 0 && c[.Attack] >= 1 && c[.Defense] >= 0, label, "negative counter", &ok)
	check(t, c[.Stairs] == 0 || c[.Stairs] == 1, label, "stairs flag", &ok)
	for cell in 0 ..< game.MAZE_CELLS {
		if g.locked[cell] {
			check(t, g.items[cell] != .None && game.exit_count(g, cell) == 1, label, "lock off an item dead end", &ok)
		}
		if g.monsters[cell].type != .None {
			m := game.MONSTERS[g.monsters[cell].type]
			check(t, g.monsters[cell].damage >= 0 && g.monsters[cell].damage < m.health, label, "monster damage out of range", &ok)
			check(t, g.items[cell] != .None && g.items[cell] != .Exit, label, "monster on an empty or exit cell", &ok)
		}
		if !ok {return false}
	}
	return true
}

// Plays random keys through the real app (every screen, every key) on a fake clock that
// sometimes jumps far ahead, drawing now and then, and checks the invariants after every key.
@(test)
random_play_never_breaks_invariants :: proc(t: ^testing.T) {
	app := new(ui.App)
	defer free(app)
	// mostly arrows (several of the same kind in a row, so the explorer actually walks), the rest
	// of the keys sprinkled in; Q is rare so games last long enough to finish
	arrows := [4]ui.Key{.Up, .Down, .Left, .Right}
	others := [?]ui.Key{.Space, .Space, .F1, .F3, .Escape, .Escape, .M, .P, .F2, .Q}
	runs_with_death, runs_with_timeout, runs_with_exit := 0, 0, 0
	for seed in 1 ..= 120 {
		ui.app_init(app, u64(seed))
		r: game.Rng
		game.rng_seed(&r, u64(seed) * 7919)
		now := 1000.0
		died, timed_out, exited := false, false, false
		ui.app_key(app, .F2, now)
		heading := arrows[0]
		for step in 0 ..< 600 {
			// mostly short gaps; now and then minutes pass (clock runs out, pauses end)
			now += f64(game.rng_int(&r, 2500))
			if game.rng_int(&r, 300) == 0 {now += 120_000}
			roll := game.rng_int(&r, 100)
			key: ui.Key
			switch {
			case roll < 12: heading = arrows[game.rng_int(&r, 4)]; key = heading
			case roll < 94: key = heading
			case: key = others[game.rng_int(&r, len(others))]
			}
			// a Q is a quit: make it rare
			if key == .Q && game.rng_int(&r, 12) != 0 {key = heading}
			ui.app_key(app, key, now)
			ui.app_take_sfx(app)
			if step % 7 == 0 {ui.app_draw(app, now)}
			if app.screen == .Play {
				switch game.explorer_state(&app.world, now) {
				case .Dead: died = true
				case .Out_Of_Time: timed_out = true
				case .Exited: exited = true
				case .Alive:
				}
			}
			if app.screen == .Play || app.screen == .Score {
				if !check_world(t, &app.world, "soak") {
					testing.expectf(t, false, "seed %d step %d key %v", seed, step, key)
					return
				}
			}
		}
		if died {runs_with_death += 1}
		if timed_out {runs_with_timeout += 1}
		if exited {runs_with_exit += 1}
	}
	log.infof("soak: 120 runs, %d with a death, %d with the clock running out, %d with an exit", runs_with_death, runs_with_timeout, runs_with_exit)
	testing.expect(t, runs_with_death > 0 && runs_with_timeout > 0, "random play should reach death and time-out")
}

// Dead and out-of-time explorers stay inert whatever is pressed afterwards.
@(test)
finished_games_ignore_commands :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	for state in ([2]game.Explorer_State{.Dead, .Out_Of_Time}) {
		game.new_game(g, .Normal, 5, NOW)
		now := NOW
		if state == .Dead {
			g.counters[.Wounds] = g.counters[.Health]
		} else {
			now += 10_000_000
		}
		before := g^
		for d in game.Direction {
			testing.expect_value(t, game.act(g, {kind = .Turn, direction = d}, now), game.Sfx.None)
			testing.expect_value(t, game.act(g, {kind = .Move}, now), game.Sfx.None)
		}
		testing.expect(t, g^ == before)
	}
}
