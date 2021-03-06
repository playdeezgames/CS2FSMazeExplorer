module ExplorerTiles

let createCardinal background foreground =
    [(Cardinal.North,ExplorerPatterns.ExplorerN);
    (Cardinal.East,ExplorerPatterns.ExplorerE);
    (Cardinal.South,ExplorerPatterns.ExplorerS);
    (Cardinal.West,ExplorerPatterns.ExplorerW)]
    |> Seq.map (fun (k,p) -> (k, new Tile.Tile(p,background,foreground)))
    |> Map.ofSeq


let Treasure = new Tile.Tile(ExplorerPatterns.Treasure, Colors.Transparent, Colors.Gold)
let Trap = new Tile.Tile(ExplorerPatterns.Treasure, Colors.Transparent, Colors.Onyx)
let Key = new Tile.Tile(ExplorerPatterns.Key, Colors.Transparent, Colors.Onyx)
let Sword =  new Tile.Tile(ExplorerPatterns.Sword, Colors.Transparent, Colors.Silver)
let Potion =  new Tile.Tile(ExplorerPatterns.Potion, Colors.Transparent, Colors.Amethyst)
let Shield =  new Tile.Tile(ExplorerPatterns.Shield, Colors.Transparent, Colors.Aquamarine)
let Hourglass =  new Tile.Tile(ExplorerPatterns.Hourglass, Colors.Transparent, Colors.Amethyst)
let LoveInterest = new Tile.Tile(ExplorerPatterns.LoveInterest, Colors.Transparent, Colors.Garnet)
let Amulet = new Tile.Tile(ExplorerPatterns.Amulet, Colors.Transparent, Colors.Emerald)
let Exit = new Tile.Tile(ExplorerPatterns.Exit, Colors.Transparent, Colors.Onyx)

