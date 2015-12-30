module HelpScreenRenderer

open GameData

let helpScreenStrings =
    [(Tiles.fonts.[Colors.Emerald],(0,0),"Help");
    (Tiles.fonts.[Colors.Emerald],(0,2),"Esc - Go Back")]

let drawHelpScreen () =
    FrameBuffer.clear Colors.Onyx
    helpScreenStrings
    |> List.iter (fun (f,xy,s) -> f |> FrameBuffer.renderString xy s)

