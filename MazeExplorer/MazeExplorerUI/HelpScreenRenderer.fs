module HelpScreenRenderer

open GameData

let helpScreenStrings =
    [(Colors.Silver,(0,0),"Help");
    (Colors.Onyx,(2,1),"Treasure");
    (Colors.Onyx,(2,2),"Trap");
    (Colors.Onyx,(2,3),"Key");
    (Colors.Onyx,(2,4),"Sword");
    (Colors.Onyx,(2,5),"Shield");
    (Colors.Onyx,(2,6),"Love Interest");
    (Colors.Onyx,(2,7),"Hourglass");
    (Colors.Onyx,(2,8),"Explorer");
    (Colors.Onyx,(2,9),"Visited Room");
    (Colors.Onyx,(2,10),"Visible Room");
    (Colors.Onyx,(2,11),"Locked Room");
    (Colors.Onyx,(2,12),"Unexplored");
    (Colors.Onyx,(2,13),"Potion");
    (Colors.Tanzanite,(0,17),"Esc - Go Back")]

let helpScreenTiles =
    [(ExplorerTiles.Treasure,(0,1));
    (ExplorerTiles.Trap,(0,2));
    (ExplorerTiles.Key,(0,3));
    (ExplorerTiles.Sword,(0,4));
    (ExplorerTiles.Shield,(0,5));
    (ExplorerTiles.LoveInterest,(0,6));
    (ExplorerTiles.Hourglass,(0,7));
    (Tiles.explorer.[Cardinal.North],(0,8));
    (Tiles.Empty,(0,9));
    (Tiles.room.[(false,true,false,false)],(0,9));
    (Tiles.Visible,(0,10));
    (Tiles.room.[(false,true,false,false)],(0,10));
    (Tiles.Empty,(0,11));
    (Tiles.room.[(false,true,false,false)],(0,11));
    (Tiles.lock.[false].[(false,true,false,false)],(0,11));
    (Tiles.NeverVisited,(0,12));
    (ExplorerTiles.Potion,(0,13));
    ]

let drawHelpScreen () =
    FrameBuffer.clear Colors.Sapphire
    helpScreenStrings
    |> List.iter (fun (c,xy,s) -> Tiles.fonts.[c] |> FrameBuffer.renderString xy s)
    helpScreenTiles
    |> List.iter (fun (t,xy)-> t |> FrameBuffer.RenderTile xy)

