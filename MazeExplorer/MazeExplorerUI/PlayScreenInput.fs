module PlayScreenInput

open GameData
open System.Windows.Forms
open Explorer

let keyCodeToCommand direction keyCode = 
    match keyCode with
    | Keys.Up    -> if direction = Cardinal.North then Move else Turn Cardinal.North
    | Keys.Right -> if direction = Cardinal.East  then Move else Turn Cardinal.East
    | Keys.Down  -> if direction = Cardinal.South then Move else Turn Cardinal.South
    | Keys.Left  -> if direction = Cardinal.West  then Move else Turn Cardinal.West
    | Keys.R     -> Restart
    | Keys.Space -> if GameSettings.options.PauseAllowed then Pause else Wait
    | _          -> Wait

let handlePlayScreenInput keyCode explorer=
    let command = 
        keyCode
        |> keyCodeToCommand explorer.Orientation
    match command with
    | Wait -> 
            false
    | Pause -> 
            gameState <- explorer |> pauseExplorer |> PauseScreen
            true
    | _ -> 
            gameState <- explorer |> act GameSettings.options.DifficultyLevel GameEvents.handle command |> PlayScreen
            true


