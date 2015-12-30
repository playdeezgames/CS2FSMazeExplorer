module HelpScreenInput

open GameData
open System.Windows.Forms

let handleHelpScreenInput keyCode =
    match keyCode with
    | Keys.Escape ->
            GameData.gameState <- GameData.gameState |> GameEvents.restorePreviousGameState 
            true
    | _ -> false
