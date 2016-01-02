module GameData

open Movement
open Notifications
open ExplorerState
open State
open Explorer

type Command<'t> = 
     | Turn of Cardinal.Direction
     | Move
     | Drink
     | External of 't

let drinkAction (eventHandler:GameEvent->unit) explorer =
    {explorer with State = explorer.State |> changeCounter Potions -1 |> setCounter Wounds 0}

let act difficultyLevel (eventHandler:GameEvent->unit) command explorer =
    match command with
    | Turn direction -> if (explorer |> getExplorerState) = Alive then explorer |> turnAction eventHandler direction else explorer
    | Move           -> if (explorer |> getExplorerState) = Alive then explorer |> moveAction eventHandler else explorer
    | Drink          -> if (explorer |> getExplorerState) = Alive && (explorer.State |> getCounter Potions) > 0 then explorer |> drinkAction eventHandler else explorer
    | _              -> explorer

