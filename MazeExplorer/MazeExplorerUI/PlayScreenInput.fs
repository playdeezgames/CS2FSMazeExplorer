module PlayScreenInput

open GameData
open System.Windows.Forms

let keyCodeToCommand direction keyCode = 
    match keyCode with
    | Keys.Up    -> if direction = Cardinal.North then Move else Turn Cardinal.North
    | Keys.Right -> if direction = Cardinal.East  then Move else Turn Cardinal.East
    | Keys.Down  -> if direction = Cardinal.South then Move else Turn Cardinal.South
    | Keys.Left  -> if direction = Cardinal.West  then Move else Turn Cardinal.West
    | Keys.R     -> Restart
    | _          -> Wait

let keyDown (event:KeyEventArgs) =
    match gameState with
    | PlayScreen explorer ->
            let command = 
                event.KeyCode
                |> keyCodeToCommand explorer.Orientation
            match command with
            | Wait -> false
            | _ -> 
                    gameState <- PlayScreen (explorer |> act PlayScreenRenderer.handleGameEvent command)
                    true
    | _ -> false


