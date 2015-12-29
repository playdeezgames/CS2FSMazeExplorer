module TitleScreenRenderer

open GameData

let titleScreenStrings =
    [(Tiles.emeraldFont,(0,0),"Maze Explorer");
    (Tiles.emeraldFont,(0,2),"F1 - Help");
    (Tiles.emeraldFont,(0,3),"F2 - New Game");
    (Tiles.emeraldFont,(0,4),"F3 - Options")]

let drawTitleScreen () =
    FrameBuffer.clear Colors.Onyx
    titleScreenStrings
    |> List.iter (fun (f,xy,s) -> f |> FrameBuffer.renderString xy s)

let redraw graphics =
    match gameState with
    | TitleScreen -> drawTitleScreen()
    | _ -> ()

