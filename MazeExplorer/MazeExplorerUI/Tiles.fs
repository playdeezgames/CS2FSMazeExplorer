module Tiles

let room = RoomTiles.createCardinal Colors.Transparent Colors.Emerald
let lock = RoomTiles.createCardinalLocks Colors.Transparent Colors.Onyx

let explorer = ExplorerTiles.createCardinal Colors.Transparent Colors.Silver

let fonts =
    [Colors.Amethyst;
    Colors.Aquamarine;
    Colors.Carnelian;
    Colors.Copper;
    Colors.Emerald;
    Colors.Garnet;
    Colors.Gold;
    Colors.Jade;
    Colors.LapisLazuli;
    Colors.Onyx;
    Colors.Sapphire;
    Colors.Silver;
    Colors.Tanzanite;
    Colors.Tin;
    Colors.Turquoise]
    |> Seq.map (fun c-> (c, c|> FontTiles.create Colors.Transparent))
    |> Map.ofSeq

let Filled = new Tile.Tile(CommonPatterns.Filled, Colors.Transparent, Colors.Amethyst)
let Empty = new Tile.Tile(CommonPatterns.Empty, Colors.Tin, Colors.Tin)
let Visible = new Tile.Tile(CommonPatterns.Empty, Colors.Copper, Colors.Copper)
let Hidden = new Tile.Tile(CharacterPatterns.character63, Colors.Jade, Colors.Onyx)
let NeverVisited = new Tile.Tile(CommonPatterns.Empty, Colors.Carnelian, Colors.Carnelian)

let monsters =
    [(Monsters.Skeleton, MonsterPatterns.Skeleton, Colors.Silver);
    (Monsters.Zombie, MonsterPatterns.Zombie, Colors.Jade);
    (Monsters.Mummy, MonsterPatterns.Mummy, Colors.Silver);
    (Monsters.Ghoul, MonsterPatterns.Ghoul, Colors.Onyx);
    (Monsters.Golem, MonsterPatterns.Golem, Colors.Copper);
    (Monsters.Wizard, MonsterPatterns.Wizard, Colors.Tanzanite)]
    |> Seq.map (fun (t,p,c)->(t, new Tile.Tile(p, Colors.Transparent, c)))
    |> Map.ofSeq