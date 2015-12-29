module HelpScreenInput

open GameData
open System.Windows.Forms

let handleHelpScreenKey keyCode =
    match keyCode with
    | Keys.Escape ->
            GameData.gameState <- TitleScreen
            true
    | _ -> false

let keyDown (event:KeyEventArgs) =
    match gameState with
    | HelpScreen pausedExplorer -> event.KeyCode |> handleHelpScreenKey
    | _ -> false
