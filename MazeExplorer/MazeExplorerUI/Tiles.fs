module Tiles

let room = RoomTiles.createCardinal Colors.Transparent Colors.Emerald
let lock = RoomTiles.createCardinalLocks Colors.Transparent Colors.Onyx

let explorer = ExplorerTiles.createCardinal Colors.Transparent Colors.Silver

let garnetFont = FontTiles.create Colors.Transparent Colors.Garnet
let goldFont = FontTiles.create Colors.Transparent Colors.Gold
let sapphireFont = FontTiles.create Colors.Transparent Colors.Sapphire
let emeraldFont = FontTiles.create Colors.Transparent Colors.Emerald

let Filled = new Tile.Tile(CommonPatterns.Filled, Colors.Transparent, Colors.Amethyst)
let Empty = new Tile.Tile(CommonPatterns.Empty, Colors.Tin, Colors.Tin)
let Visible = new Tile.Tile(CommonPatterns.Empty, Colors.Copper, Colors.Copper)
let Hidden = new Tile.Tile(CharacterPatterns.character63, Colors.Jade, Colors.Onyx)
let NeverVisited = new Tile.Tile(CommonPatterns.Empty, Colors.Carnelian, Colors.Carnelian)
