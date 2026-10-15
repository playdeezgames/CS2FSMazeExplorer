package ui

import "../game"

// What the page keeps in localStorage (docs/PORT.md D11): the options and the best grand total
// per difficulty, as one short line of text:
//
//	MX1 <sfx 0|1> <pause 0|1> <difficulty 0..2> <best easy> <best normal> <best hard>
//
// Loading is strict: anything else is refused and nothing changes.
SETTINGS_TAG :: "MX1"
MAX_BEST :: 9_999_999

settings_encode :: proc(app: ^App) -> string {
	b: Builder
	builder_str(&b, SETTINGS_TAG)
	builder_str(&b, " ")
	builder_int(&b, 1 if app.options.sfx else 0, 0)
	builder_str(&b, " ")
	builder_int(&b, 1 if app.options.pause_allowed else 0, 0)
	builder_str(&b, " ")
	builder_int(&b, int(app.options.difficulty), 0)
	for d in game.Difficulty {
		builder_str(&b, " ")
		builder_int(&b, app.best[d], 0)
	}
	n := min(builder_len(&b), len(app.io))
	copy(app.io[:n], b.buf[:n])
	return string(app.io[:n])
}

// Parses a non-negative decimal of at most `max_digits` digits from `text`; the whole token.
@(private = "file")
parse_token :: proc(token: string, max_value: int) -> (value: int, ok: bool) {
	if len(token) == 0 || len(token) > 8 {return 0, false}
	for c in transmute([]u8)token {
		if c < '0' || c > '9' {return 0, false}
		value = value * 10 + int(c - '0')
	}
	return value, value <= max_value
}

settings_decode :: proc(app: ^App, text: string) -> bool {
	tokens: [8]string
	count := 0
	start := 0
	for i in 0 ..= len(text) {
		if i == len(text) || text[i] == ' ' {
			if count == len(tokens) {return false}
			tokens[count] = text[start:i]
			count += 1
			start = i + 1
		}
	}
	if count != 7 || tokens[0] != SETTINGS_TAG {return false}
	sfx, ok1 := parse_token(tokens[1], 1)
	pause, ok2 := parse_token(tokens[2], 1)
	difficulty, ok3 := parse_token(tokens[3], int(max(game.Difficulty)))
	if !(ok1 && ok2 && ok3) {return false}
	best: [game.Difficulty]int
	for d in game.Difficulty {
		v, ok := parse_token(tokens[4 + int(d)], MAX_BEST)
		if !ok {return false}
		best[d] = v
	}
	app.options = {
		sfx           = sfx == 1,
		pause_allowed = pause == 1,
		difficulty    = game.Difficulty(difficulty),
	}
	app.best = best
	app.dirty = true
	return true
}
