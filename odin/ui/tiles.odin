package ui

import "../game"

// Ported from Tiles.fs, ExplorerTiles.fs and RoomTiles.fs: which pattern and colors draw what.

Tile :: struct {
	pattern:    Pattern,
	background: Palette_Color,
	foreground: Palette_Color,
}

// RoomTiles.createCardinal with Colors.Transparent / Colors.Emerald: walls of a cell, open where
// it has an exit.
tile_room :: proc(exits: bit_set[game.Direction;u8]) -> Tile {
	return {PATTERN_ROOM[transmute(u8)exits], .Transparent, .Emerald}
}

// RoomTiles.createCardinalLocks: Gold when the explorer holds a key, Onyx when not. A locked cell is
// a dead end, so it has exactly one exit, and the lock is drawn on that side.
tile_lock :: proc(exit: game.Direction, has_key: bool) -> Tile {
	return {PATTERN_LOCK[exit], .Transparent, .Gold if has_key else .Onyx}
}

tile_explorer :: proc(d: game.Direction) -> Tile {
	return {PATTERN_EXPLORER[d], .Transparent, .Silver}
}

// ExplorerTiles. A trap is drawn with the treasure pattern in Onyx (as the original does).
tile_item :: proc(item: game.Item_Type) -> (tile: Tile, ok: bool) {
	switch item {
	case .None: return {}, false
	case .Treasure: return {PATTERN_ITEM_TREASURE, .Transparent, .Gold}, true
	case .Trap: return {PATTERN_ITEM_TREASURE, .Transparent, .Onyx}, true
	case .Key: return {PATTERN_ITEM_KEY, .Transparent, .Onyx}, true
	case .Sword: return {PATTERN_ITEM_SWORD, .Transparent, .Silver}, true
	case .Shield: return {PATTERN_ITEM_SHIELD, .Transparent, .Aquamarine}, true
	case .Hourglass: return {PATTERN_ITEM_HOURGLASS, .Transparent, .Amethyst}, true
	case .Potion: return {PATTERN_ITEM_POTION, .Transparent, .Amethyst}, true
	case .Love_Interest: return {PATTERN_ITEM_LOVEINTEREST, .Transparent, .Garnet}, true
	case .Amulet: return {PATTERN_ITEM_AMULET, .Transparent, .Emerald}, true
	case .Exit: return {PATTERN_ITEM_EXIT, .Transparent, .Onyx}, true
	}
	return {}, false
}

// Tiles.monsters.
tile_monster :: proc(type: game.Monster_Type) -> (tile: Tile, ok: bool) {
	switch type {
	case .None: return {}, false
	case .Skeleton: return {PATTERN_MONSTER_SKELETON, .Transparent, .Silver}, true
	case .Zombie: return {PATTERN_MONSTER_ZOMBIE, .Transparent, .Jade}, true
	case .Mummy: return {PATTERN_MONSTER_MUMMY, .Transparent, .Silver}, true
	case .Ghoul: return {PATTERN_MONSTER_GHOUL, .Transparent, .Onyx}, true
	case .Golem: return {PATTERN_MONSTER_GOLEM, .Transparent, .Gold}, true
	case .Wizard: return {PATTERN_MONSTER_WIZARD, .Transparent, .Tanzanite}, true
	}
	return {}, false
}

// The key icon of the stats panel (PlayScreenRenderer.UIKey) is Copper, not Onyx.
tile_ui_key :: proc() -> Tile {
	return {PATTERN_ITEM_KEY, .Transparent, .Copper}
}

// Tiles.Empty, Visible, Hidden, NeverVisited: the fills behind the maze cells.
tile_empty :: proc() -> Tile {
	return {PATTERN_EMPTY, .Tin, .Tin}
}

tile_visible :: proc() -> Tile {
	return {PATTERN_EMPTY, .Copper, .Copper}
}

// Hidden is character 63 ('?') in Onyx on Jade.
tile_hidden :: proc() -> Tile {
	return {FONT_PATTERNS['?'], .Jade, .Onyx}
}

tile_never_visited :: proc() -> Tile {
	return {PATTERN_EMPTY, .Carnelian, .Carnelian}
}

// The fifteen colors the original built fonts for (Tiles.fonts).
FONT_COLORS :: [15]Palette_Color {
	.Amethyst, .Aquamarine, .Carnelian, .Copper, .Emerald, .Garnet, .Gold, .Jade,
	.Lapis_Lazuli, .Onyx, .Sapphire, .Silver, .Tanzanite, .Tin, .Turquoise,
}
