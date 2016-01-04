module PlayScreenInput

open GameData
open System.Windows.Forms
open Explorer
open GameSettings
open PausedExplorer
open GameState

type UICommand =
    | Help
    | Pause
    | Quit
    | Options
    | Wait

let keyCodeToCommand direction keyCode = 
    match keyCode with
    | Keys.Up    -> if direction = Cardinal.North then Move else Turn Cardinal.North
    | Keys.Right -> if direction = Cardinal.East  then Move else Turn Cardinal.East
    | Keys.Down  -> if direction = Cardinal.South then Move else Turn Cardinal.South
    | Keys.Left  -> if direction = Cardinal.West  then Move else Turn Cardinal.West
    | Keys.Q     -> External Quit
    | Keys.Space -> External Pause
    | Keys.F1    -> External Help
    | Keys.F3    -> External Options
    | _          -> External Wait

let pauseGame options explorer =
    if options.PauseAllowed then
        explorer |> pauseExplorer |> PauseScreen
    else
        explorer |> PlayScreen

let openHelp options explorer =
    if options.PauseAllowed then
        explorer |> pauseExplorer |> Some |> HelpScreen
    else
        explorer |> PlayScreen

let openOptions options explorer =
    if options.PauseAllowed then
        explorer |> pauseExplorer |> Some |> OptionsScreen
    else
        explorer |> PlayScreen

let quitGame explorer =
    explorer.State |> ScoreScreen

let handlePlayScreenInput keyCode explorer=
    let command = 
        keyCode
        |> keyCodeToCommand explorer.Orientation
    match command with
    | External Wait -> 
            false
    | External Quit -> 
            gameState <- explorer |> quitGame
            true
    | External Pause -> 
            gameState <- explorer |> pauseGame GameSettings.options
            true
    | External Help -> 
            gameState <- explorer |> openHelp GameSettings.options
            true
    | External Options -> 
            gameState <- explorer |> openOptions GameSettings.options
            true
    | _ -> 
            gameState <- explorer |> act GameSettings.options.DifficultyLevel GameEvents.handle command |> PlayScreen
            true


