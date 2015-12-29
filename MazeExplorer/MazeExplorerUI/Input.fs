module Input

open System.Windows.Forms

let keyDown (event:KeyEventArgs) =
    match GameData.gameState with
    | GameData.TitleScreen -> false
    | GameData.HelpScreen pausedExplorer -> false
    | GameData.OptionsScreen pausedExplorer -> false
    | GameData.PlayScreen explorer -> event |> PlayInput.keyDown
    | GameData.GameOver (explorer, explorerState) -> false
    


