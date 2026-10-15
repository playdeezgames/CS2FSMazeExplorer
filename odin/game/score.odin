package game

// Ported from ScoreScreenRenderer.fs.

Score_Row :: struct {
	name:    string,
	counter: Counter,
	value:   int,
}

SCORE_ROWS := [10]Score_Row {
	{"Loot", .Loot, 10},
	{"Keys", .Keys_Acquired, 25},
	{"Pots", .Potions_Acquired, 50},
	{"Swrd", .Swords_Acquired, 50},
	{"Shld", .Shields_Acquired, 100},
	{"Trap", .Traps_Sprung, -25},
	{"Door", .Doors_Unlocked, 25},
	{"Hrgl", .Hourglasses_Acquired, 50},
	{"Amul", .Amulet, 500},
	{"Exit", .Stairs, 250},
}

score_items :: proc(g: ^Game) -> int {
	total := 0
	for row in SCORE_ROWS {
		total += g.counters[row.counter] * row.value
	}
	return total
}

score_monsters :: proc(g: ^Game) -> int {
	total := 0
	for t in Monster_Type {
		total += g.kills[t] * MONSTERS[t].score
	}
	return total
}

score_total :: proc(g: ^Game) -> int {
	return score_items(g) + score_monsters(g)
}
