module GameState

open PausedExplorer
open Explorer
open State

type GameState =
    | TitleScreen
    | HelpScreen of PausedExplorer<Cardinal.Direction, State> option
    | OptionsScreen of PausedExplorer<Cardinal.Direction, State> option
    | PlayScreen of Explorer<Cardinal.Direction, State>
    | PauseScreen of PausedExplorer<Cardinal.Direction, State>
    | ScoreScreen of State 

let mutable gameState = TitleScreen

