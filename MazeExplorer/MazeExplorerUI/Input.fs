module Input

open System.Windows.Forms
open GameData
open GameState

let keyDown (event:KeyEventArgs) =
    match gameState with
    | TitleScreen                              -> event.KeyCode |> TitleScreenInput.handleTitleScreenInput
    | HelpScreen pausedExplorer                -> event.KeyCode |> HelpScreenInput.handleHelpScreenInput
    | OptionsScreen pausedExplorer             -> event.KeyCode |> OptionsScreenInput.handleOptionsScreenInput
    | PlayScreen explorer                      -> explorer |> PlayScreenInput.handlePlayScreenInput event.KeyCode
    | PauseScreen pausedExplorer               -> pausedExplorer |> PauseScreenInput.handlePauseScreenInput event.KeyCode
    | ScoreScreen _                            -> event.KeyCode |> ScoreScreenInput.handleScoreScreenInput
    


