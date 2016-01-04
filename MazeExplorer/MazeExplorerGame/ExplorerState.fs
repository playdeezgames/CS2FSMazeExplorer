module ExplorerState

open State
open Explorer

let tookStairs (explorer:Explorer.Explorer<Cardinal.Direction,State>) =
    (explorer.State |> getCounter Stairs) > 0

let isDead explorer = 
    let wounds = 
        explorer.State
        |> getCounter Wounds
    let health = 
        explorer.State
        |> getCounter Health
    wounds >= health


let getTimeLeft explorer =
    let timeRemaining = (explorer.State.EndTime - System.DateTime.Now).TotalSeconds |> int
    if timeRemaining < 0 then
        0
    else
        timeRemaining

type ExplorerState = 
    | Exited
    | Alive
    | Dead
    | OutOfTime

let getExplorerState explorer = 
    if explorer |> isDead then
        Dead
    elif explorer |> tookStairs then
        Exited
    elif (explorer |> getTimeLeft) <= 0 then
        OutOfTime
    else
        Alive


