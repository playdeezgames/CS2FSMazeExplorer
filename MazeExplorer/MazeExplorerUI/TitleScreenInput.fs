module TitleScreenInput

open GameData
open System.Windows.Forms
open GameState
open Initialization

let handleTitleScreenInput keyCode =
    match keyCode with
    | Keys.F1 ->
            gameState <- HelpScreen None
            true
    | Keys.F2 -> 
            gameState <- PlayScreen  (restart GameSettings.options.DifficultyLevel  GameEvents.handle)
            true
    | Keys.F3 ->
            gameState <- OptionsScreen None
            true
    | _ -> false
