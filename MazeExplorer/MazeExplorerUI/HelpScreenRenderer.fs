module HelpScreenRenderer

open GameData

let helpScreenStrings =
    [(Tiles.emeraldFont,(0,0),"Help");
    (Tiles.emeraldFont,(0,2),"Esc - Go Back")]

let drawHelpScreen () =
    FrameBuffer.clear Colors.Onyx
    helpScreenStrings
    |> List.iter (fun (f,xy,s) -> f |> FrameBuffer.renderString xy s)

