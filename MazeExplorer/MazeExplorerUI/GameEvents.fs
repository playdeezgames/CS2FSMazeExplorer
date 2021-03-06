module GameEvents

open GameData
open Notifications
open PausedExplorer
open GameState

let handle (event:GameEvent) =
    match event with
    | PlaySound sfx -> Audio.playSound sfx

let restorePreviousGameState gameState = 
    match gameState with
    | HelpScreen (Some pausedExplorer) -> pausedExplorer |> unpauseExplorer |> PlayScreen
    | HelpScreen None -> TitleScreen
    | OptionsScreen (Some pausedExplorer) -> pausedExplorer |> unpauseExplorer |> PlayScreen
    | OptionsScreen None -> TitleScreen
    | _ -> gameState

