module OptionsScreenRenderer

open GameData

// What are the options I want to set?
// A) SFX toggle/volume?
// B) Difficulty level?
// C) Hardcore/No Pause mode

let optionsScreenStrings =
    [(Tiles.emeraldFont,(0,0),"Options");
    (Tiles.emeraldFont,(0,2),"Esc - Go Back")]

let drawOptionsScreen () =
    FrameBuffer.clear Colors.Onyx
    optionsScreenStrings
    |> List.iter (fun (f,xy,s) -> f |> FrameBuffer.renderString xy s)

let redraw graphics =
    match gameState with
    | OptionsScreen pausedExplorer -> drawOptionsScreen()
    | _ -> ()



