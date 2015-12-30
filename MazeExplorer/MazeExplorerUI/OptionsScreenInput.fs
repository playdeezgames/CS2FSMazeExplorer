module OptionsScreenInput

open GameData
open System.Windows.Forms

let increaseDifficulty difficultyLevel =
    match difficultyLevel with
    | Easy -> Normal
    | Normal -> Hard
    | Hard -> Hard

let decreaseDifficulty difficultyLevel =
    match difficultyLevel with
    | Easy -> Easy
    | Normal -> Easy
    | Hard -> Normal

let handleOptionsScreenInput keyCode =
    match keyCode with
    | Keys.Up ->
            GameSettings.options <- {GameSettings.options with DifficultyLevel = GameSettings.options.DifficultyLevel |> increaseDifficulty}
            true
    | Keys.Down ->
            GameSettings.options <- {GameSettings.options with DifficultyLevel = GameSettings.options.DifficultyLevel |> decreaseDifficulty}
            true
    | Keys.M ->
            GameSettings.options <- {GameSettings.options with Sfx=GameSettings.options.Sfx |> not}
            true
    | Keys.P ->
            GameSettings.options <- {GameSettings.options with PauseAllowed=GameSettings.options.PauseAllowed |> not}
            true
    | Keys.Escape ->
            GameData.gameState <- GameData.gameState |> GameEvents.restorePreviousGameState 
            true
    | _ -> false
