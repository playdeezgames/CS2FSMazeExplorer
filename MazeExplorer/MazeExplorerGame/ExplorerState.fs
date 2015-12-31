module ExplorerState

open State
open Explorer

let wonGame (explorer:Explorer.Explorer<Cardinal.Direction,State>) =
    explorer.State.Items
    |> Map.tryPick (fun k v -> if v = Treasure then Some k else None)
    |> Option.isNone

let isDead explorer = 
    explorer.State
    |> getCounter Health
    <= 0

let getTimeLeft explorer =
    let timeRemaining = (explorer.State.EndTime - System.DateTime.Now).TotalSeconds |> int
    if timeRemaining < 0 then
        0
    else
        timeRemaining

type ExplorerState = 
    | Win
    | Alive
    | Dead
    | OutOfTime

let getExplorerState explorer = 
    if explorer |> isDead then
        Dead
    elif explorer |> wonGame then
        Win
    elif (explorer |> getTimeLeft) <= 0 then
        OutOfTime
    else
        Alive


