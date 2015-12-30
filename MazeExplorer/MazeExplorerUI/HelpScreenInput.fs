module HelpScreenInput

open GameData
open System.Windows.Forms

let handleHelpScreenInput keyCode =
    match keyCode with
    | Keys.Escape ->
            GameData.gameState <- TitleScreen
            true
    | _ -> false
