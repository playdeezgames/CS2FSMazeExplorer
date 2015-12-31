module PauseScreenInput

open GameData
open System.Windows.Forms
open PausedExplorer
open GameState

let handlePauseScreenInput keyCode pausedExplorer=
    match keyCode with
    | Keys.Space ->
            gameState <- pausedExplorer |> unpauseExplorer |> PlayScreen
            true
    | _ -> false
