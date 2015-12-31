module HelpScreenInput

open System.Windows.Forms
open GameState

let handleHelpScreenInput keyCode =
    match keyCode with
    | Keys.Escape ->
            gameState <- gameState |> GameEvents.restorePreviousGameState 
            true
    | _ -> false
