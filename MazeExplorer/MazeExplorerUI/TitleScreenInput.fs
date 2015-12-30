module TitleScreenInput

open GameData
open System.Windows.Forms

let handleTitleScreenInput keyCode =
    match keyCode with
    | Keys.F1 ->
            GameData.gameState <- HelpScreen None
            true
    | Keys.F2 -> 
            GameData.gameState <- PlayScreen  ( restart GameSettings.options.DifficultyLevel  GameEvents.handle)
            true
    | Keys.F3 ->
            GameData.gameState <- OptionsScreen None
            true
    | _ -> false
