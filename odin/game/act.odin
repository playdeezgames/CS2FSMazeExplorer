package game

// Ported from Action.fs, Movement.fs, Update.fs, ItemPickup.fs and ExplorerState.fs.
// The wall clock is always an argument (`now_ms`); nothing here reads a clock.

// ExplorerState.getTimeLeft. Q3 (decided): whole seconds rounded up and clamped at 0, so the
// clock reads 1 for the last second and time is out exactly at 0 (the F# truncated and lost it).
time_left_seconds :: proc(g: ^Game, now_ms: f64) -> int {
	remaining := g.end_time_ms - now_ms
	if remaining <= 0 {return 0}
	seconds := int(remaining / 1000)
	if f64(seconds) * 1000 < remaining {seconds += 1}
	return seconds
}

// Pausing keeps the remaining time: the page moves the deadline by the paused duration on resume.
shift_deadline :: proc(g: ^Game, delta_ms: f64) {
	g.end_time_ms += delta_ms
}

is_dead :: proc(g: ^Game) -> bool {
	return g.counters[.Wounds] >= g.counters[.Health]
}

explorer_state :: proc(g: ^Game, now_ms: f64) -> Explorer_State {
	switch {
	case is_dead(g): return .Dead
	case g.counters[.Stairs] > 0: return .Exited
	case time_left_seconds(g, now_ms) <= 0: return .Out_Of_Time
	}
	return .Alive
}

// Action.act: commands only do anything while Alive. Returns the sound to play, if any.
act :: proc(g: ^Game, command: Command, now_ms: f64) -> Sfx {
	if explorer_state(g, now_ms) != .Alive {return .None}
	switch command.kind {
	case .Turn: return turn_action(g, command.direction)
	case .Move: return move_action(g)
	}
	return .None
}

turn_action :: proc(g: ^Game, d: Direction) -> Sfx {
	g.orientation = d
	for i in 0 ..< MAZE_CELLS {
		if g.visible[i] {g.visited[i] = true}
	}
	refresh_visible(g)
	return .None
}

move_action :: proc(g: ^Game) -> Sfx {
	next, in_grid := neighbor(g.position, g.orientation)
	connected := in_grid && g.orientation in g.exits[g.position]
	has_key := g.counters[.Keys] > 0
	if !connected || (g.locked[next] && !has_key) {
		return .Blocked
	}
	if g.locked[next] {
		g.locked[next] = false
		g.counters[.Keys] -= 1
		g.counters[.Doors_Unlocked] += 1
		return .Unlock_Door
	}
	if g.monsters[next].type != .None {
		return fight(g, next)
	}
	return enter_location(g, next)
}

calculate_damage :: proc(attack, defense: int) -> int {
	return attack - defense if attack > defense else 0
}

// Movement.fightLocation: one round, both sides hit at once.
fight :: proc(g: ^Game, cell: int) -> Sfx {
	instance := g.monsters[cell]
	m := MONSTERS[instance.type]
	player_attack, player_defense := g.counters[.Attack], g.counters[.Defense]

	monster_damage := calculate_damage(player_attack, m.defense)
	player_damage := calculate_damage(m.attack, player_defense)

	// adjustPlayerDefense: a hit may wear the armour down. Short-circuits like the F#.
	new_defense := player_defense
	if player_defense > 0 && rng_int(&g.rng, g.counters[.Defense_Saving_Throw]) < m.attack {
		new_defense = player_defense - 1
	}

	sfx: Sfx
	if g.counters[.Wounds] + player_damage >= g.counters[.Health] {
		if g.counters[.Potions] > 0 {
			sfx = .Drink_Potion
			g.counters[.Potions] -= 1
			g.counters[.Wounds] = 0
		} else {
			sfx = .Death
			g.counters[.Wounds] = g.counters[.Health]
		}
	} else {
		sfx = .Fight
		g.counters[.Wounds] += player_damage
	}
	g.counters[.Defense] = new_defense

	// QUIRK Q10: a monster whose defence is at least the player's attack takes no damage and
	// can never be killed.
	if instance.damage + monster_damage >= m.health {
		g.monsters[cell] = {}
		g.kills[instance.type] += 1
	} else {
		g.monsters[cell].damage += monster_damage
	}
	return sfx
}

enter_location :: proc(g: ^Game, next: int) -> Sfx {
	g.position = next
	// Update.updateState: visited absorbs the old view, the view is recomputed, then pickups.
	g.visited[next] = true
	for i in 0 ..< MAZE_CELLS {
		if g.visible[i] {g.visited[i] = true}
	}
	refresh_visible(g)
	sfx := pickup(g, next)
	g.items[next] = .None
	return sfx
}

pickup :: proc(g: ^Game, cell: int) -> Sfx {
	c := &g.counters
	switch g.items[cell] {
	case .None:
		return .None
	case .Treasure:
		c[.Loot] += 1
		return .Acquire_Loot
	case .Trap:
		c[.Wounds] += 1
		c[.Traps_Sprung] += 1
		// A trap that would kill spends a potion, silently (no Drink_Potion sound).
		if c[.Wounds] >= c[.Health] && c[.Potions] > 0 {
			c[.Potions] -= 1
			c[.Wounds] = 0
		}
		return .Trigger_Trap
	case .Key:
		c[.Keys] += 1
		c[.Keys_Acquired] += 1
		return .Acquire_Key
	case .Sword:
		c[.Attack] += 1
		c[.Swords_Acquired] += 1
		return .Acquire_Sword
	case .Shield:
		c[.Defense] += 1
		c[.Shields_Acquired] += 1
		return .Acquire_Shield
	case .Potion:
		c[.Potions] += 1
		c[.Potions_Acquired] += 1
		return .Acquire_Potion
	case .Hourglass:
		g.end_time_ms += f64(c[.Time_Bonus]) * 1000
		c[.Hourglasses_Acquired] += 1
		return .Acquire_Hourglass
	case .Love_Interest:
		c[.Health] += c[.Health] // doubles Health; wounds are not cleared
		return .Love_Interest
	case .Amulet:
		c[.Amulet] = 1
		return .Amulet
	case .Exit:
		c[.Stairs] = 1
		return .Exit
	}
	return .None
}
