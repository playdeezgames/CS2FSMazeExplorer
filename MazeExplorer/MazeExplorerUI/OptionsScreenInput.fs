module OptionsScreenInput

open GameData
open System.Windows.Forms

let handleOptionsScreenInput keyCode =
    match keyCode with
    | Keys.M ->
            GameSettings.options <- {GameSettings.options with Sfx=GameSettings.options.Sfx |> not}
            true
    | Keys.P ->
            GameSettings.options <- {GameSettings.options with PauseAllowed=GameSettings.options.PauseAllowed |> not}
            true
    | Keys.Escape ->
            GameData.gameState <- TitleScreen
            true
    | _ -> false
