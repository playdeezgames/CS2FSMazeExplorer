module GameOverScreenRenderer

open GameData
open System.Windows.Forms

let redraw graphics =
    match gameState with
    | GameOverScreen (explorer, explorerState) -> ()
    | _ -> ()



