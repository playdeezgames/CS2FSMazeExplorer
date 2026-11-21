package ui

import "../game"

// GameState.fs: the screens. `Help` and `Options` remember whether they were opened from play
// (the F# `Some pausedExplorer`) or from the title (`None`).
Screen :: enum u8 {
	Title,
	Help,
	Options,
	Play,
	Pause,
	Score,
}

// GameSettings.options.
Options :: struct {
	sfx:           bool,
	pause_allowed: bool,
	difficulty:    game.Difficulty,
}

// Logical keys, independent of the browser. The page maps `e.key` to these (see platform.js, which
// must list the same numbers). Append only: the page and saved layouts use the numbers.
Key :: enum u8 {
	None,
	Up,
	Down,
	Left,
	Right,
	Q,
	Space,
	F1,
	F3,
	Escape,
	M,
	P,
	F2,
}

IO_SIZE :: 256

App :: struct {
	world:          game.Game,
	fb:             Framebuffer,
	screen:         Screen,
	options:        Options,
	dirty:          bool,
	shown_seconds:  int, // the clock the last drawn play frame showed
	sfx:            game.Sfx, // the sound of the last action, for the page to play
	paused_at_ms:   f64, // when play was left for pause, help or options
	back_to_play:   bool, // Help and Options: opened from play, so Esc resumes it
	best:           [game.Difficulty]int, // best grand total per difficulty (design/PORT.md D11)
	new_best:       bool, // the score on screen beat the previous best
	next_seed:      u64, // the seed of the next new game
	settings_dirty: bool, // options or best changed since the page last stored them
	io:             [IO_SIZE]u8, // text exchanged with the page for saving and loading
}

app_init :: proc(app: ^App, first_seed: u64) {
	app^ = {}
	app.options = {
		sfx           = true,
		pause_allowed = true,
		difficulty    = .Normal,
	}
	app.screen = .Title
	app.next_seed = first_seed
	app.dirty = true
}

// Title screen F2 in the original: a fresh game with the current difficulty. The first game uses
// the seed the page gave (`?seed=N` makes it fixed); later games derive new ones from it.
app_new_game :: proc(app: ^App, now_ms: f64) {
	seed := app.next_seed
	state := seed
	app.next_seed = game.splitmix64(&state)
	game.new_game(&app.world, app.options.difficulty, seed, now_ms)
	app.screen = .Play
	app.sfx = .None
	app.dirty = true
}

// A key press. Returns true when the picture needs redrawing (the F# handlers' bool).
app_key :: proc(app: ^App, key: Key, now_ms: f64) -> bool {
	redraw := false
	switch app.screen {
	case .Title: redraw = title_key(app, key, now_ms)
	case .Help: redraw = back_key(app, key, now_ms)
	case .Options: redraw = options_key(app, key, now_ms)
	case .Play: redraw = play_key(app, key, now_ms)
	case .Pause: redraw = pause_key(app, key, now_ms)
	case .Score: redraw = score_key(app, key)
	}
	if redraw {app.dirty = true}
	return redraw
}

// TitleScreenInput.
title_key :: proc(app: ^App, key: Key, now_ms: f64) -> bool {
	#partial switch key {
	case .F1:
		app.screen = .Help
		app.back_to_play = false
		return true
	case .F2:
		app_new_game(app, now_ms)
		return true
	case .F3:
		app.screen = .Options
		app.back_to_play = false
		return true
	}
	return false
}

// GameEvents.restorePreviousGameState: back to the paused game (time resumes where it stopped) or
// to the title.
restore_previous_screen :: proc(app: ^App, now_ms: f64) {
	if app.back_to_play {
		resume_play(app, now_ms)
	} else {
		app.screen = .Title
	}
}

// PausedExplorer.unpauseExplorer: the deadline moves by the time spent away.
resume_play :: proc(app: ^App, now_ms: f64) {
	game.shift_deadline(&app.world, now_ms - app.paused_at_ms)
	app.back_to_play = false
	app.screen = .Play
}

// HelpScreenInput.
back_key :: proc(app: ^App, key: Key, now_ms: f64) -> bool {
	if key == .Escape {
		restore_previous_screen(app, now_ms)
		return true
	}
	return false
}

// OptionsScreenInput: Up makes the game harder, Down easier; the change applies to the next game.
options_key :: proc(app: ^App, key: Key, now_ms: f64) -> bool {
	#partial switch key {
	case .Up:
		if app.options.difficulty != .Hard {app.options.difficulty = game.Difficulty(int(app.options.difficulty) + 1)}
		app.settings_dirty = true
		return true
	case .Down:
		if app.options.difficulty != .Easy {app.options.difficulty = game.Difficulty(int(app.options.difficulty) - 1)}
		app.settings_dirty = true
		return true
	case .M:
		app.options.sfx = !app.options.sfx
		app.settings_dirty = true
		return true
	case .P:
		app.options.pause_allowed = !app.options.pause_allowed
		app.settings_dirty = true
		return true
	case .Escape:
		restore_previous_screen(app, now_ms)
		return true
	}
	return false
}

// PauseScreenInput.
pause_key :: proc(app: ^App, key: Key, now_ms: f64) -> bool {
	if key == .Space {
		resume_play(app, now_ms)
		return true
	}
	return false
}

// ScoreScreenInput.
score_key :: proc(app: ^App, key: Key) -> bool {
	if key == .Escape {
		app.screen = .Title
		return true
	}
	return false
}

// Called every animation frame: marks the picture dirty when the play clock has ticked over
// (the original repainted on a one-second timer).
app_tick :: proc(app: ^App, now_ms: f64) {
	if app.screen == .Play && game.time_left_seconds(&app.world, now_ms) != app.shown_seconds {
		app.dirty = true
	}
}

// Draws if anything changed. Returns true when the framebuffer holds a new picture.
app_draw :: proc(app: ^App, now_ms: f64) -> bool {
	app_tick(app, now_ms)
	if !app.dirty {return false}
	app.dirty = false
	switch app.screen {
	case .Title: draw_title_screen(app)
	case .Help: draw_help_screen(app)
	case .Options: draw_options_screen(app)
	case .Play: draw_play_screen(app, now_ms)
	case .Pause: draw_pause_screen(app)
	case .Score: draw_score_screen(app)
	}
	return true
}

// The sound of the last action, once. Muted sound (Options) plays nothing, as Audio.playSound.
app_take_sfx :: proc(app: ^App) -> game.Sfx {
	s := app.sfx
	app.sfx = .None
	return s if app.options.sfx else .None
}

// Leaving play for the score screen: record a new best for the game's difficulty (D11).
enter_score_screen :: proc(app: ^App) {
	total := game.score_total(&app.world)
	d := app.world.difficulty
	app.new_best = total > app.best[d]
	if app.new_best {
		app.best[d] = total
		app.settings_dirty = true
	}
	app.screen = .Score
}
