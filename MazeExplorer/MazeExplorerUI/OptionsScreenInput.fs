module OptionsScreenInput

open GameData
open System.Windows.Forms

let handleOptionsScreenKey keyCode =
    match keyCode with
    | Keys.Escape ->
            GameData.gameState <- TitleScreen
            true
    | _ -> false

let keyDown (event:KeyEventArgs) =
    match gameState with
    | OptionsScreen pausedExplorer -> event.KeyCode |> handleOptionsScreenKey
    | _ -> false
