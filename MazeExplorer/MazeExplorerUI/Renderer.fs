module Renderer

let redraw graphics =
    match GameData.gameState with
    | GameData.TitleScreen -> ()
    | GameData.HelpScreen pausedExplorer -> ()
    | GameData.OptionsScreen pausedExplorer -> ()
    | GameData.PlayScreen explorer -> graphics |> PlayRenderer.redraw
    | GameData.GameOver (explorer, explorerState) -> ()

