module Input

open System.Windows.Forms
open GameData

let keyDown (event:KeyEventArgs) =
    match gameState with
    | TitleScreen                              -> event.KeyCode |> TitleScreenInput.handleTitleScreenInput
    | HelpScreen pausedExplorer                -> event.KeyCode |> HelpScreenInput.handleHelpScreenInput
    | OptionsScreen pausedExplorer             -> event.KeyCode |> OptionsScreenInput.handleOptionsScreenInput
    | PlayScreen explorer                      -> explorer |> PlayScreenInput.handlePlayScreenInput event.KeyCode
    | GameOverScreen (explorer, explorerState) -> event |> GameOverScreenInput.keyDown
    | PauseScreen pausedExplorer               -> pausedExplorer |> PauseScreenInput.handlePauseScreenInput event.KeyCode
    


