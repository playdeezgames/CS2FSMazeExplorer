module TitleScreenInput

open GameData
open System.Windows.Forms

let handleTitleScreenKey keyCode =
    match keyCode with
    | Keys.F1 ->
            GameData.gameState <- HelpScreen None
            true
    | Keys.F2 -> 
            GameData.gameState <- PlayScreen (restart())
            true
    | Keys.F3 ->
            GameData.gameState <- OptionsScreen None
            true
    | _ -> false

let keyDown (event:KeyEventArgs) =
    match gameState with
    | TitleScreen -> event.KeyCode |> handleTitleScreenKey
    | _ -> false
