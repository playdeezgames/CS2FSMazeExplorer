package game

// Ported from MazeExplorerGame: State.fs, Monsters.fs, Difficulty.fs, Notifications.fs.

MAZE_CELLS :: MAZE_COLUMNS * MAZE_ROWS

Direction :: enum u8 {
	North,
	East,
	South,
	West,
}

Item_Type :: enum u8 {
	None,
	Treasure,
	Trap,
	Key,
	Sword,
	Shield,
	Hourglass,
	Potion,
	Love_Interest,
	Amulet,
	Exit,
}

Monster_Type :: enum u8 {
	None,
	Skeleton,
	Zombie,
	Mummy,
	Ghoul,
	Golem,
	Wizard,
}

Monster_Descriptor :: struct {
	name:    string,
	health:  int,
	attack:  int,
	defense: int,
	score:   int,
	abbr:    string,
}

Monster_Instance :: struct {
	type:   Monster_Type,
	damage: int,
}

MONSTERS := [Monster_Type]Monster_Descriptor {
	.None     = {},
	.Skeleton = {"Skeleton", 1, 1, 0, 20, "Skel"},
	.Zombie   = {"Zombie", 2, 1, 0, 40, "Zomb"},
	.Mummy    = {"Mummy", 3, 2, 1, 180, "Mumm"},
	.Ghoul    = {"Ghoul", 3, 2, 2, 240, "Ghul"},
	.Golem    = {"Golem", 4, 3, 3, 480, "Golm"},
	.Wizard   = {"Wizard", 5, 3, 3, 600, "Wizd"},
}

Counter :: enum u8 {
	Loot,
	Wounds,
	Health,
	Keys,
	Potions,
	Attack,
	Defense,
	Amulet,
	Stairs,
	Keys_Acquired,
	Potions_Acquired,
	Swords_Acquired,
	Shields_Acquired,
	Traps_Sprung,
	Doors_Unlocked,
	Hourglasses_Acquired,
	Time_Bonus,
	Time_Limit,
	Defense_Saving_Throw,
}

Difficulty :: enum u8 {
	Easy,
	Normal,
	Hard,
}

Difficulty_Settings :: struct {
	hourglasses:          int,
	potions:              int,
	swords:               int,
	time_limit:           int, // seconds
	time_bonus:           int, // seconds
	initial_health:       int,
	defense_saving_throw: int,
}

// Constants.fs and Difficulty.fs, exactly (docs/PORT.md D13).
DIFFICULTY_SETTINGS := [Difficulty]Difficulty_Settings {
	.Easy   = {hourglasses = 6, potions = 6, swords = 5, time_limit = 600, time_bonus = 120, initial_health = 10, defense_saving_throw = 6},
	.Normal = {hourglasses = 5, potions = 5, swords = 4, time_limit = 480, time_bonus = 90, initial_health = 7, defense_saving_throw = 4},
	.Hard   = {hourglasses = 4, potions = 4, swords = 3, time_limit = 360, time_bonus = 60, initial_health = 5, defense_saving_throw = 3},
}

INITIAL_WOUNDS :: 0
INITIAL_ATTACK :: 1
INITIAL_POTIONS :: 3

// Notifications.Sfx. Each step produces at most one.
Sfx :: enum u8 {
	None,
	Acquire_Loot,
	Acquire_Hourglass,
	Acquire_Key,
	Acquire_Potion,
	Acquire_Shield,
	Acquire_Sword,
	Trigger_Trap,
	Unlock_Door,
	Blocked,
	Drink_Potion,
	Amulet,
	Death,
	Exit,
	Fight,
	Love_Interest,
}

Explorer_State :: enum u8 {
	Alive,
	Dead,
	Exited,
	Out_Of_Time,
}

Command_Kind :: enum u8 {
	Turn,
	Move,
}

Command :: struct {
	kind:      Command_Kind,
	direction: Direction, // Turn only
}

// Everything the F# `Explorer<Direction, State>` held, as flat arrays indexed by cell
// (row * MAZE_COLUMNS + column). No heap, no globals.
Game :: struct {
	rng:         Rng,
	difficulty:  Difficulty,
	exits:       [MAZE_CELLS]bit_set[Direction;u8],
	items:       [MAZE_CELLS]Item_Type,
	monsters:    [MAZE_CELLS]Monster_Instance,
	locked:      [MAZE_CELLS]bool,
	visited:     [MAZE_CELLS]bool,
	visible:     [MAZE_CELLS]bool,
	kills:       [Monster_Type]int,
	counters:    [Counter]int,
	position:    int,
	orientation: Direction,
	end_time_ms: f64, // the deadline, in the same clock as the `now_ms` arguments
}
