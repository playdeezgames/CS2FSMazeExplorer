module Input

open System.Windows.Forms

let keyDown (event:KeyEventArgs) =
    match GameData.gameState with
    | GameData.TitleScreen                              -> event |> TitleScreenInput.keyDown
    | GameData.HelpScreen pausedExplorer                -> event |> HelpScreenInput.keyDown
    | GameData.OptionsScreen pausedExplorer             -> event |> OptionsScreenInput.keyDown
    | GameData.PlayScreen explorer                      -> event |> PlayScreenInput.keyDown
    | GameData.GameOverScreen (explorer, explorerState) -> event |> GameOverScreenInput.keyDown
    


