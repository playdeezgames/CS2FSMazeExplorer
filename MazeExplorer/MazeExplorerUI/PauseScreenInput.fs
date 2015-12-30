module PauseScreenInput

open GameData
open System.Windows.Forms

let handlePauseScreenInput keyCode pausedExplorer=
    match keyCode with
    | Keys.Space ->
            GameData.gameState <- pausedExplorer |> unpauseExplorer |> PlayScreen
            true
    | _ -> false
