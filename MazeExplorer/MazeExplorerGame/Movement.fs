module Movement

open Explorer
open State
open Update
open Notifications
open Initialization

let mustUnlock next (explorer: Explorer<Cardinal.Direction, State>) =
    next
    |> explorer.State.Locks.Contains

let canEnter next (explorer: Explorer<Cardinal.Direction, State>) =
    let canGo = next |> explorer.Maze.[explorer.Position].Contains
    let isLocked = explorer |> mustUnlock next
    let hasKey = explorer.State |> getCounter Keys > 0
    canGo && if isLocked then hasKey else true

let enterLocation eventHandler next explorer =
    {explorer with 
        Position = next; 
        State = explorer |> updateState eventHandler next}

let unlockLocation eventHandler next explorer =
    PlaySound UnlockDoor
    |> eventHandler
    {explorer with State = explorer.State |> updateLock next}

let moveAction eventHandler (explorer: Explorer<Cardinal.Direction, State>) = 
    let next =
        explorer.Orientation
        |> Cardinal.walk explorer.Position
    if explorer |> canEnter next then
        if explorer |> mustUnlock next then
            explorer
            |> unlockLocation eventHandler next
        else
            explorer
            |> enterLocation eventHandler next
    else
        explorer

let turnAction eventHandler direction explorer = 
    {explorer with Orientation = direction; State={explorer.State with Visited = explorer.State.Visited |> Set.union explorer.State.Visible; Visible = visibleLocations(explorer.Position, direction, explorer.Maze)}}
