module TitleScreenRenderer

open GameData

let titleScreenStrings =
    [(Tiles.fonts.[Colors.Sapphire],(9,4),"Maze  Explorer");
    (Tiles.fonts.[Colors.Garnet],(9,15),"F1 - Help    ");
    (Tiles.fonts.[Colors.Garnet],(9,16),"F2 - New Game");
    (Tiles.fonts.[Colors.Garnet],(9,17),"F3 - Options ")]

let titleScreenTiles =
    [(Tiles.Empty,(0,0));
    (Tiles.Empty,(1,0));
    (Tiles.Empty,(0,1));
    (Tiles.Empty,(0,2));
    (Tiles.Empty,(0,3));
    (Tiles.Visible,(2,0));
    (Tiles.Visible,(2,1));
    (Tiles.Hidden,(1,1));
    (Tiles.Hidden,(1,2));
    (Tiles.Hidden,(1,3));
    (Tiles.Hidden,(2,2));
    (Tiles.Hidden,(2,3));
    (Tiles.Hidden,(3,0));
    (Tiles.Hidden,(3,1));
    (Tiles.Hidden,(3,2));
    (Tiles.Hidden,(3,3));
    (Tiles.room.[(false,true,true,true)],(0,0));
    (Tiles.room.[(false,true,false,true)],(1,0));
    (Tiles.room.[(false,false,true,true)],(2,0));
    (Tiles.room.[(true,true,true,false)],(0,1));
    (Tiles.room.[(true,false,false,false)],(2,1));
    (Tiles.room.[(true,false,true,true)],(0,2));
    (Tiles.room.[(true,false,true,false)],(0,3));
    (Tiles.explorer.[Cardinal.South],(2,0));
    (ExplorerTiles.Key,(2,1))]
    |> List.map (fun (t,(x,y))-> (t,(x + 14,y + 7)) )

let drawTitleScreen () =
    FrameBuffer.clear Colors.Turquoise
    titleScreenStrings
    |> List.iter (fun (f,xy,s) -> f |> FrameBuffer.renderString xy s)
    titleScreenTiles
    |> List.iter (fun (t,xy)-> t |> FrameBuffer.RenderTile xy)

