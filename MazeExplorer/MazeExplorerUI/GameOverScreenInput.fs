module GameOverScreenInput

open GameData
open System.Windows.Forms

let keyDown (event:KeyEventArgs) =
    match gameState with
    | GameOverScreen (explorer, explorerState) -> false
    | _ -> false



