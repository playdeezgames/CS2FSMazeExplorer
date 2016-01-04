module ScoreScreenInput

open System.Windows.Forms
open GameState

let handleScoreScreenInput keyCode =
    match keyCode with
    | Keys.Escape ->
            gameState <- TitleScreen 
            true
    | _ -> false

