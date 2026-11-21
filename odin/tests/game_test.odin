#+build !js
package tests

import "core:log"
import "core:testing"
import "../game"

NOW :: f64(1_000_000)

// A corridor along row 0, cells 0..n-1 connected east-west, explorer on cell 0 facing East,
// 10 health, the starting attack and potions, nothing else. For rule tests that need exact numbers.
corridor :: proc(g: ^game.Game, n: int) {
	g^ = {}
	game.rng_seed(&g.rng, 1)
	for i in 0 ..< n - 1 {
		g.exits[i] += {.East}
		g.exits[i + 1] += {.West}
	}
	g.position = 0
	g.orientation = .East
	g.visited[0] = true
	g.counters[.Health] = 10
	g.counters[.Attack] = game.INITIAL_ATTACK
	g.counters[.Potions] = game.INITIAL_POTIONS
	g.counters[.Time_Bonus] = 90
	g.counters[.Time_Limit] = 480
	g.counters[.Defense_Saving_Throw] = 4
	g.end_time_ms = NOW + 480_000
	game.refresh_visible(g)
}

move :: proc(g: ^game.Game) -> game.Sfx {
	return game.act(g, {kind = .Move}, NOW)
}

// ---- rng -------------------------------------------------------------------------------------

@(test)
rng_is_deterministic_and_bounded :: proc(t: ^testing.T) {
	a, b: game.Rng
	game.rng_seed(&a, 42)
	game.rng_seed(&b, 42)
	counts: [7]int
	for _ in 0 ..< 7000 {
		x := game.rng_int(&a, 7)
		testing.expect_value(t, x, game.rng_int(&b, 7))
		counts[x] += 1
	}
	for c in counts {
		testing.expectf(t, c > 800 && c < 1200, "uneven rng: %v", counts)
	}
}

// ---- generation ------------------------------------------------------------------------------

@(test)
maze_is_a_spanning_tree_for_200_seeds :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	for seed in 1 ..= 200 {
		game.new_game(g, .Normal, u64(seed), NOW)
		edges := 0
		for cell in 0 ..< game.MAZE_CELLS {
			for d in game.Direction {
				if d not_in g.exits[cell] {continue}
				nb, ok := game.neighbor(cell, d)
				if !ok || game.opposite(d) not_in g.exits[nb] {
					testing.expectf(t, false, "seed %d: bad connection at %d", seed, cell)
					return
				}
				edges += 1
			}
		}
		testing.expect_value(t, edges / 2, game.MAZE_CELLS - 1)
		// connected
		seen: [game.MAZE_CELLS]bool
		stack: [game.MAZE_CELLS]int
		top := 1
		seen[0] = true
		reached := 1
		for top > 0 {
			top -= 1
			cell := stack[top]
			for d in g.exits[cell] {
				nb, _ := game.neighbor(cell, d)
				if !seen[nb] {
					seen[nb] = true
					reached += 1
					stack[top] = nb
					top += 1
				}
			}
		}
		testing.expect_value(t, reached, game.MAZE_CELLS)
	}
}

@(test)
generation_invariants_for_all_difficulties :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	for difficulty in game.Difficulty {
		for seed in 1 ..= 100 {
			game.new_game(g, difficulty, u64(seed), NOW)
			testing.expect(t, game.exit_count(g, g.position) > 1)
			dead_ends, item_cells, keys, locks := 0, 0, 0, 0
			for cell in 0 ..< game.MAZE_CELLS {
				dead := game.exit_count(g, cell) == 1
				if dead {dead_ends += 1}
				has_item := g.items[cell] != .None
				// items sit on dead ends and only there
				testing.expect_value(t, has_item, dead)
				if has_item {item_cells += 1}
				if g.items[cell] == .Key {keys += 1}
				if g.locked[cell] {
					locks += 1
					testing.expect(t, dead && g.items[cell] != .Key)
				}
				if g.monsters[cell].type != .None {
					testing.expect(t, has_item && g.items[cell] != .Exit)
				}
				#partial switch g.items[cell] {
				case .Amulet: testing.expect_value(t, g.monsters[cell].type, game.Monster_Type.Golem)
				case .Love_Interest: testing.expect_value(t, g.monsters[cell].type, game.Monster_Type.Wizard)
				}
			}
			testing.expect_value(t, item_cells, dead_ends)
			testing.expect_value(t, locks, keys)
			s := game.DIFFICULTY_SETTINGS[difficulty]
			testing.expect_value(t, g.counters[.Health], s.initial_health)
			testing.expect_value(t, g.counters[.Potions], 3)
			testing.expect_value(t, g.counters[.Attack], 1)
			testing.expect(t, g.visited[g.position] && g.visible[g.position])
		}
	}
}

@(test)
same_seed_same_game :: proc(t: ^testing.T) {
	a, b := new(game.Game), new(game.Game)
	defer free(a)
	defer free(b)
	game.new_game(a, .Hard, 777, NOW)
	game.new_game(b, .Hard, 777, NOW)
	testing.expect(t, a^ == b^)
	game.new_game(b, .Hard, 778, NOW)
	testing.expect(t, a^ != b^)
}

@(test)
q4_guard_keeps_the_exit :: proc(t: ^testing.T) {
	list := [?]game.Item_Type{.Love_Interest, .Amulet, .Potion, .Exit, .Hourglass, .Sword}
	game.keep_exit(list[:], 4) // fits: unchanged
	testing.expect_value(t, list[3], game.Item_Type.Exit)
	game.keep_exit(list[:], 3) // would be dropped: moved to the front
	testing.expect_value(t, list, [6]game.Item_Type{.Exit, .Love_Interest, .Amulet, .Potion, .Hourglass, .Sword})
	game.keep_exit(list[:], 1) // already first
	testing.expect_value(t, list[0], game.Item_Type.Exit)
}

// Q4 (design/PORT.md): measured, then guarded by keep_exit. Records how many dead ends mazes have and how often a
// fixed item (the Exit above all) is dropped. The Exit is the only one that makes a run unwinnable.
@(test)
measure_q4_missing_fixed_items :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	for difficulty in game.Difficulty {
		fewest := max(int)
		no_exit := 0
		short := 0
		runs := 300
		for seed in 1 ..= runs {
			game.new_game(g, difficulty, u64(seed), NOW)
			dead_ends, exits := 0, 0
			for cell in 0 ..< game.MAZE_CELLS {
				if game.exit_count(g, cell) == 1 {dead_ends += 1}
				if g.items[cell] == .Exit {exits += 1}
			}
			fewest = min(fewest, dead_ends)
			if exits == 0 {no_exit += 1}
			tmp: [game.MAZE_CELLS]game.Item_Type
			if dead_ends < game.fixed_item_list(difficulty, &tmp) {short += 1}
		}
		log.infof("Q4 %v: %d mazes, fewest dead ends %d, fixed list truncated in %d, Exit missing in %d", difficulty, runs, fewest, short, no_exit)
	}
}

// ---- reachability: an overpowered bot walks to a key (if the exit is locked) and then the exit ---

Bot_Result :: enum {
	Exited,
	No_Exit_In_Maze,
	Stuck,
}

play_with_bot :: proc(g: ^game.Game) -> Bot_Result {
	exit_cell := -1
	for cell in 0 ..< game.MAZE_CELLS {
		if g.items[cell] == .Exit {exit_cell = cell}
	}
	if exit_cell < 0 {return .No_Exit_In_Maze}
	for _ in 0 ..< 20_000 {
		if game.explorer_state(g, NOW) != .Alive {break}
		target := exit_cell
		if g.locked[exit_cell] && g.counters[.Keys] == 0 {
			target = nearest_item(g, .Key)
			if target < 0 {return .Stuck}
		}
		next_dir, ok := first_step(g, g.position, target)
		if !ok {return .Stuck}
		if next_dir == g.orientation {
			game.act(g, {kind = .Move}, NOW)
		} else {
			game.act(g, {kind = .Turn, direction = next_dir}, NOW)
		}
	}
	return .Exited if game.explorer_state(g, NOW) == .Exited else .Stuck
}

nearest_item :: proc(g: ^game.Game, item: game.Item_Type) -> int {
	dist: [game.MAZE_CELLS]int
	for i in 0 ..< game.MAZE_CELLS {dist[i] = -1}
	queue: [game.MAZE_CELLS]int
	head, tail := 0, 1
	queue[0] = g.position
	dist[g.position] = 0
	for head < tail {
		cell := queue[head]
		head += 1
		if g.items[cell] == item {return cell}
		for d in g.exits[cell] {
			nb, _ := game.neighbor(cell, d)
			if dist[nb] < 0 {
				dist[nb] = dist[cell] + 1
				queue[tail] = nb
				tail += 1
			}
		}
	}
	return -1
}

first_step :: proc(g: ^game.Game, from, to: int) -> (game.Direction, bool) {
	if from == to {return .North, false}
	// breadth-first from `to`; the first step is toward the neighbour with the smaller distance
	dist: [game.MAZE_CELLS]int
	for i in 0 ..< game.MAZE_CELLS {dist[i] = -1}
	queue: [game.MAZE_CELLS]int
	head, tail := 0, 1
	queue[0] = to
	dist[to] = 0
	for head < tail {
		cell := queue[head]
		head += 1
		for d in g.exits[cell] {
			nb, _ := game.neighbor(cell, d)
			if dist[nb] < 0 {
				dist[nb] = dist[cell] + 1
				queue[tail] = nb
				tail += 1
			}
		}
	}
	for d in g.exits[from] {
		nb, _ := game.neighbor(from, d)
		if dist[nb] >= 0 && dist[nb] < dist[from] {return d, true}
	}
	return .North, false
}

@(test)
overpowered_bot_exits_every_maze :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	missing := 0
	for difficulty in game.Difficulty {
		for seed in 1 ..= 100 {
			game.new_game(g, difficulty, u64(seed), NOW)
			g.counters[.Attack] = 99
			g.counters[.Defense] = 99
			g.counters[.Health] = 999
			switch play_with_bot(g) {
			case .Exited:
				testing.expect(t, game.score_total(g) >= 250)
			case .No_Exit_In_Maze: missing += 1
			case .Stuck: testing.expectf(t, false, "%v seed %d: bot got stuck", difficulty, seed)
			}
		}
	}
	log.infof("mazes without an Exit among the 300 played: %d", missing)
}

@(test)
ordinary_bot_always_finishes_without_hanging :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	exited, dead := 0, 0
	for seed in 1 ..= 200 {
		game.new_game(g, .Normal, u64(seed), NOW)
		result := play_with_bot(g)
		if result == .Stuck {
			// not exiting is fine when the explorer died; it must not be an infinite loop or a stall
			testing.expect_value(t, game.explorer_state(g, NOW), game.Explorer_State.Dead)
			dead += 1
		} else if result == .Exited {
			exited += 1
		}
	}
	log.infof("ordinary bot on Normal, 200 seeds: %d exited, %d died", exited, dead)
}

// ---- rules -----------------------------------------------------------------------------------

@(test)
turning_merges_view_into_visited :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 4)
	testing.expect(t, g.visible[0] && g.visible[1] && g.visible[2] && g.visible[3])
	testing.expect(t, !g.visited[2])
	sfx := game.act(g, {kind = .Turn, direction = .North}, NOW)
	testing.expect_value(t, sfx, game.Sfx.None)
	testing.expect_value(t, g.orientation, game.Direction.North)
	testing.expect(t, g.visited[3]) // the old ray is now remembered
	testing.expect(t, g.visible[0] && !g.visible[1])
}

@(test)
blocked_by_wall_and_by_lock_without_key :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 3)
	g.orientation = .North
	testing.expect_value(t, move(g), game.Sfx.Blocked)
	g.orientation = .East
	g.locked[1] = true
	testing.expect_value(t, move(g), game.Sfx.Blocked)
	testing.expect_value(t, g.position, 0)
}

@(test)
unlocking_spends_a_key_and_does_not_move :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 3)
	g.locked[1] = true
	g.counters[.Keys] = 1
	testing.expect_value(t, move(g), game.Sfx.Unlock_Door)
	testing.expect_value(t, g.position, 0)
	testing.expect_value(t, g.counters[.Keys], 0)
	testing.expect_value(t, g.counters[.Doors_Unlocked], 1)
	testing.expect(t, !g.locked[1])
	move(g)
	testing.expect_value(t, g.position, 1)
}

@(test)
pickups_change_counters :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 9)
	g.items[1] = .Treasure
	g.items[2] = .Key
	g.items[3] = .Sword
	g.items[4] = .Shield
	g.items[5] = .Potion
	g.items[6] = .Hourglass
	g.items[7] = .Amulet
	g.items[8] = .Exit
	expected := [8]game.Sfx{.Acquire_Loot, .Acquire_Key, .Acquire_Sword, .Acquire_Shield, .Acquire_Potion, .Acquire_Hourglass, .Amulet, .Exit}
	for sfx in expected {
		testing.expect_value(t, move(g), sfx)
	}
	c := g.counters
	testing.expect_value(t, c[.Loot], 1)
	testing.expect_value(t, c[.Keys], 1)
	testing.expect_value(t, c[.Attack], 2)
	testing.expect_value(t, c[.Defense], 1)
	testing.expect_value(t, c[.Potions], 4)
	testing.expect_value(t, c[.Amulet], 1)
	testing.expect_value(t, c[.Stairs], 1)
	testing.expect_value(t, g.end_time_ms, NOW + 480_000 + 90_000)
	testing.expect_value(t, game.explorer_state(g, NOW), game.Explorer_State.Exited)
	// once Exited, commands do nothing
	testing.expect_value(t, game.act(g, {kind = .Turn, direction = .West}, NOW), game.Sfx.None)
	testing.expect_value(t, g.orientation, game.Direction.East)
}

@(test)
love_interest_doubles_health_without_healing :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 2)
	g.counters[.Health] = 7
	g.counters[.Wounds] = 3
	g.items[1] = .Love_Interest
	testing.expect_value(t, move(g), game.Sfx.Love_Interest)
	testing.expect_value(t, g.counters[.Health], 14)
	testing.expect_value(t, g.counters[.Wounds], 3)
}

@(test)
trap_wounds_and_spends_potion_only_when_it_would_kill :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 4)
	g.counters[.Potions] = 1
	g.items[1] = .Trap
	g.items[2] = .Trap
	testing.expect_value(t, move(g), game.Sfx.Trigger_Trap)
	testing.expect_value(t, g.counters[.Wounds], 1)
	testing.expect_value(t, g.counters[.Potions], 1)
	g.counters[.Wounds] = 9 // one more wound is lethal
	testing.expect_value(t, move(g), game.Sfx.Trigger_Trap) // silent rescue: still the trap sound
	testing.expect_value(t, g.counters[.Wounds], 0)
	testing.expect_value(t, g.counters[.Potions], 0)
	testing.expect_value(t, g.counters[.Traps_Sprung], 2)
}

@(test)
trap_without_potion_kills :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 2)
	g.counters[.Potions] = 0
	g.counters[.Wounds] = 9
	g.items[1] = .Trap
	move(g)
	testing.expect_value(t, game.explorer_state(g, NOW), game.Explorer_State.Dead)
}

@(test)
combat_follows_the_original_formula :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	// Zombie: health 2, attack 1, defence 0. Player attack 1, defence 0 -> both sides hit for 1.
	corridor(g, 2)
	g.monsters[1] = {.Zombie, 0}
	testing.expect_value(t, move(g), game.Sfx.Fight)
	testing.expect_value(t, g.counters[.Wounds], 1)
	testing.expect_value(t, g.monsters[1].damage, 1)
	testing.expect_value(t, g.position, 0)
	testing.expect_value(t, move(g), game.Sfx.Fight)
	testing.expect_value(t, g.monsters[1].type, game.Monster_Type.None)
	testing.expect_value(t, g.kills[.Zombie], 1)
	testing.expect_value(t, g.counters[.Wounds], 2)
	move(g) // walk in
	testing.expect_value(t, g.position, 1)
}

@(test)
golem_cannot_be_hurt_by_a_starting_player :: proc(t: ^testing.T) { // Q10
	g := new(game.Game)
	defer free(g)
	corridor(g, 2)
	g.monsters[1] = {.Golem, 0}
	g.counters[.Health] = 100
	for _ in 0 ..< 10 {move(g)}
	testing.expect_value(t, g.monsters[1].type, game.Monster_Type.Golem)
	testing.expect_value(t, g.monsters[1].damage, 0)
	testing.expect_value(t, g.counters[.Wounds], 30) // ten rounds of attack 3 against defence 0
}

@(test)
lethal_blow_drinks_a_potion_then_death_without_one :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 2)
	g.monsters[1] = {.Wizard, 0} // attack 3
	g.counters[.Health] = 3
	g.counters[.Potions] = 1
	testing.expect_value(t, move(g), game.Sfx.Drink_Potion)
	testing.expect_value(t, g.counters[.Wounds], 0)
	testing.expect_value(t, g.counters[.Potions], 0)
	testing.expect_value(t, move(g), game.Sfx.Death)
	testing.expect_value(t, game.explorer_state(g, NOW), game.Explorer_State.Dead)
	testing.expect_value(t, move(g), game.Sfx.None)
}

@(test)
defense_wears_down_by_saving_throw :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 2)
	g.monsters[1] = {.Golem, 0}
	g.counters[.Health] = 1000
	g.counters[.Defense] = 3
	g.counters[.Defense_Saving_Throw] = 1 // Next(1) is always 0, which is < attack 3: always wears
	testing.expect_value(t, move(g), game.Sfx.Fight)
	testing.expect_value(t, g.counters[.Defense], 2)
	testing.expect_value(t, g.counters[.Wounds], 0) // attack 3 vs defence 3 deals nothing this round
	move(g)
	testing.expect_value(t, g.counters[.Wounds], 1) // attack 3 vs defence 2
}

@(test)
time_runs_out_rounded_up :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	corridor(g, 2)
	testing.expect_value(t, game.time_left_seconds(g, NOW), 480)
	testing.expect_value(t, game.time_left_seconds(g, NOW + 500), 480) // rounded up, Q3
	testing.expect_value(t, game.time_left_seconds(g, NOW + 1_000), 479)
	testing.expect_value(t, game.time_left_seconds(g, NOW + 479_999), 1) // the last second shows
	testing.expect_value(t, game.explorer_state(g, NOW + 479_999), game.Explorer_State.Alive)
	testing.expect_value(t, game.time_left_seconds(g, NOW + 480_000), 0)
	testing.expect_value(t, game.explorer_state(g, NOW + 480_000), game.Explorer_State.Out_Of_Time)
	testing.expect_value(t, game.time_left_seconds(g, NOW + 999_999), 0)
	testing.expect_value(t, game.act(g, {kind = .Move}, NOW + 480_000), game.Sfx.None)
	game.shift_deadline(g, 10_000) // resume after a pause of ten seconds
	testing.expect_value(t, game.explorer_state(g, NOW + 480_000), game.Explorer_State.Alive)
}

@(test)
score_arithmetic :: proc(t: ^testing.T) {
	g := new(game.Game)
	defer free(g)
	g.counters[.Loot] = 3 // 30
	g.counters[.Keys_Acquired] = 2 // 50
	g.counters[.Potions_Acquired] = 1 // 50
	g.counters[.Swords_Acquired] = 2 // 100
	g.counters[.Shields_Acquired] = 1 // 100
	g.counters[.Traps_Sprung] = 4 // -100
	g.counters[.Doors_Unlocked] = 2 // 50
	g.counters[.Hourglasses_Acquired] = 1 // 50
	g.counters[.Amulet] = 1 // 500
	g.counters[.Stairs] = 1 // 250
	testing.expect_value(t, game.score_items(g), 1080)
	g.kills[.Skeleton] = 2 // 40
	g.kills[.Wizard] = 1 // 600
	testing.expect_value(t, game.score_monsters(g), 640)
	testing.expect_value(t, game.score_total(g), 1720)
}
