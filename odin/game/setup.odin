package game

// Ported from Initialization.fs and ItemGeneration.fs: building a new game.

Weighted_Monster :: struct {
	monster: Monster_Type, // .None means "no monster"
	weight:  int,
}

Monster_Table :: [4]Weighted_Monster

// ItemGeneration.itemMonsters. Unused slots have weight 0.
item_monster_table :: proc(item: Item_Type) -> Monster_Table {
	switch item {
	case .Treasure: return {{.Skeleton, 3}, {.Zombie, 2}, {.None, 3}, {}}
	case .Trap: return {{.Skeleton, 3}, {.Zombie, 2}, {.None, 2}, {}}
	case .Key: return {{.Skeleton, 3}, {.Zombie, 2}, {.Mummy, 1}, {.None, 2}}
	case .Sword: return {{.Skeleton, 3}, {.Zombie, 2}, {.None, 3}, {}}
	case .Shield: return {{.Zombie, 3}, {.Mummy, 2}, {.None, 5}, {}}
	case .Hourglass: return {{.Zombie, 3}, {.Mummy, 2}, {.Ghoul, 1}, {}}
	case .Potion: return {{.Skeleton, 3}, {.Zombie, 2}, {.Ghoul, 1}, {.None, 2}}
	case .Amulet: return {{.Golem, 1}, {}, {}, {}}
	case .Exit: return {{.None, 1}, {}, {}, {}}
	case .Love_Interest: return {{.Wizard, 1}, {}, {}, {}}
	case .None: return {}
	}
	return {}
}

pick_monster :: proc(r: ^Rng, table: Monster_Table) -> Monster_Type {
	total := 0
	for e in table {total += e.weight}
	if total <= 0 {return .None}
	roll := rng_int(r, total)
	for e in table {
		if roll < e.weight {return e.monster}
		roll -= e.weight
	}
	return .None
}

// ItemGeneration.variableItemGenerator: Treasure 25, Trap 20, Shield 10, Key 15.
pick_variable_item :: proc(r: ^Rng) -> Item_Type {
	roll := rng_int(r, 70)
	switch {
	case roll < 25: return .Treasure
	case roll < 45: return .Trap
	case roll < 55: return .Shield
	}
	return .Key
}

// ItemGeneration.fixedItemList, in the original order. Q4: the caller truncates this list to the
// number of dead ends and keeps the Exit (see new_game), so the items at the end are lost first.
fixed_item_list :: proc(difficulty: Difficulty, out: ^[MAZE_CELLS]Item_Type) -> int {
	s := DIFFICULTY_SETTINGS[difficulty]
	n := 0
	add :: proc(out: ^[MAZE_CELLS]Item_Type, n: ^int, item: Item_Type, times: int) {
		for _ in 0 ..< times {
			out[n^] = item
			n^ += 1
		}
	}
	add(out, &n, .Love_Interest, 1)
	add(out, &n, .Amulet, 1)
	add(out, &n, .Potion, s.potions)
	add(out, &n, .Exit, 1)
	add(out, &n, .Hourglass, s.hourglasses)
	add(out, &n, .Sword, s.swords)
	return n
}

// Q4 guard: a maze with too few dead ends only has room for the first `count` fixed items, which
// would drop the Exit and make it unwinnable. Move the Exit to the front so it is the last thing
// lost. Does nothing when the Exit already fits, so no measured maze changes.
keep_exit :: proc(fixed: []Item_Type, count: int) {
	if count <= 0 {return}
	for i in count ..< len(fixed) {
		if fixed[i] != .Exit {continue}
		copy(fixed[1:i + 1], fixed[0:i])
		fixed[0] = .Exit
		return
	}
}

shuffle_items :: proc(r: ^Rng, items: []Item_Type) {
	for i := len(items) - 1; i > 0; i -= 1 {
		j := rng_int(r, i + 1)
		items[i], items[j] = items[j], items[i]
	}
}

shuffle_cells :: proc(r: ^Rng, cells: []int) {
	for i := len(cells) - 1; i > 0; i -= 1 {
		j := rng_int(r, i + 1)
		cells[i], cells[j] = cells[j], cells[i]
	}
}

// Starts a new game. `now_ms` is the page clock; the deadline is `now_ms` plus the time limit.
new_game :: proc(g: ^Game, difficulty: Difficulty, seed: u64, now_ms: f64) {
	g^ = {}
	rng_seed(&g.rng, seed)
	g.difficulty = difficulty
	settings := DIFFICULTY_SETTINGS[difficulty]

	generate_maze(g)

	// Start on a random cell that is not a dead end, facing a random way.
	starts: [MAZE_CELLS]int
	start_count := 0
	for cell in 0 ..< MAZE_CELLS {
		if exit_count(g, cell) > 1 {
			starts[start_count] = cell
			start_count += 1
		}
	}
	g.position = starts[rng_int(&g.rng, start_count)]
	g.orientation = Direction(rng_int(&g.rng, len(Direction)))

	// One item per dead end: the fixed list (truncated), topped up with random items, shuffled.
	dead_ends: [MAZE_CELLS]int
	dead_end_count := 0
	for cell in 0 ..< MAZE_CELLS {
		if exit_count(g, cell) == 1 {
			dead_ends[dead_end_count] = cell
			dead_end_count += 1
		}
	}
	fixed: [MAZE_CELLS]Item_Type
	fixed_count := min(fixed_item_list(difficulty, &fixed), dead_end_count)
	keep_exit(fixed[:], fixed_count)
	list: [MAZE_CELLS]Item_Type
	for i in 0 ..< fixed_count {
		list[i] = fixed[i]
	}
	for i in fixed_count ..< dead_end_count {
		list[i] = pick_variable_item(&g.rng)
	}
	shuffle_items(&g.rng, list[:dead_end_count])
	for i in 0 ..< dead_end_count {
		g.items[dead_ends[i]] = list[i]
	}

	// Monsters stand on item cells, rolled per item type.
	for i in 0 ..< dead_end_count {
		cell := dead_ends[i]
		monster := pick_monster(&g.rng, item_monster_table(g.items[cell]))
		if monster != .None {
			g.monsters[cell] = {monster, 0}
		}
	}

	// As many locks as keys, on random non-key item cells.
	key_count := 0
	others: [MAZE_CELLS]int
	other_count := 0
	for i in 0 ..< dead_end_count {
		cell := dead_ends[i]
		if g.items[cell] == .Key {
			key_count += 1
		} else {
			others[other_count] = cell
			other_count += 1
		}
	}
	shuffle_cells(&g.rng, others[:other_count])
	for i in 0 ..< min(key_count, other_count) {
		g.locked[others[i]] = true
	}

	g.counters[.Wounds] = INITIAL_WOUNDS
	g.counters[.Attack] = INITIAL_ATTACK
	g.counters[.Potions] = INITIAL_POTIONS
	g.counters[.Time_Bonus] = settings.time_bonus
	g.counters[.Time_Limit] = settings.time_limit
	g.counters[.Health] = settings.initial_health
	g.counters[.Defense_Saving_Throw] = settings.defense_saving_throw
	g.end_time_ms = now_ms + f64(settings.time_limit) * 1000

	g.visited[g.position] = true
	refresh_visible(g)
}
