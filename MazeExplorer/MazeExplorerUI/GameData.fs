module GameData

open Explorer
open Location

let TileColumns = 32
let TileRows = 18
let MazeColumns = 24
let MazeRows = TileRows
let InitialHealth = 3
let TimeLimit = 300
let TimeBonusPerHourglass = 60.

type GameEvent =
    | PlaySound of Audio.Sfx

type ItemType = 
    | Treasure
    | Trap
    | Key
    | Sword
    | Shield
    | Hourglass
    | Potion

type CounterType =
    | Loot
    | Health
    | Keys
    | Potions

let itemGenerator =
    [(Treasure,30);
    (Trap,20);
    (Sword,5);
    (Shield,5);
    (Potion,5);
    (Hourglass,1);
    (Key,10)]
    |> WeightedGenerator.ofPairs

let generateItem()= WeightedGenerator.generate (fun n->Utility.random.Next(n)) itemGenerator

type State = 
    {Visited: Set<Location>; 
    Items: Map<Location,ItemType>; 
    Locks: Set<Location>;
    Visible: Set<Location>; 
    Counters : Map<CounterType,int>;
    StartTime: System.DateTime}

let rec visibleLocations (location:Location, direction:Cardinal.Direction, maze:Maze.Maze) =
    let nextLocation = Cardinal.walk location direction
    if maze.[location].Contains nextLocation then
        visibleLocations (nextLocation, direction, maze)
        |> Set.add location
    else
        [location]
        |> Set.ofSeq

let itemLocations (maze:Maze.Maze) =
    maze
    |> Map.toSeq
    |> Seq.filter (fun (location, exits) -> (exits |> Set.count) = 1)
    |> Seq.map (fun (location, exits) -> location, generateItem())
    |> Map.ofSeq

let createExplorer = Explorer.create (fun l->Utility.random.Next()) (fun d->Utility.random.Next())

let wonGame (explorer:Explorer.Explorer<Cardinal.Direction,State>) =
    explorer.State.Items
    |> Map.tryPick (fun k v -> if v = Treasure then Some k else None)
    |> Option.isNone

let getCounter counterType (state:State) =
    match state.Counters |> Map.tryFind counterType with
    | Some value -> value
    | None       -> 0

let isDead explorer = 
    explorer.State
    |> getCounter Health
    |> (>=) 0

type ExplorerState = 
    | Win
    | Alive
    | Dead
    | OutOfTime

let getTimeLeft explorer =
    let elapsed = (System.DateTime.Now - explorer.State.StartTime).TotalSeconds |> int
    if elapsed >= TimeLimit then
        0
    else
        TimeLimit - elapsed

let getExplorerState explorer = 
    if explorer |> isDead then
        Dead
    elif explorer |> wonGame then
        Win
    elif (explorer |> getTimeLeft) <= 0 then
        OutOfTime
    else
        Alive

let addLocks (rng:int->seq<Location>->seq<Location>) (explorer:Explorer<Cardinal.Direction, State>) =
    let keyCells, otherCells =
        explorer.State.Items
        |> Map.partition (fun k v->v = Key)
    let lockLocations = 
        otherCells
        |> Map.toSeq
        |> Seq.map (fun (k,v)->k)
        |> rng keyCells.Count
        |> Set.ofSeq
    {explorer with State = {explorer.State with Locks=lockLocations}}

let setCounter counterType value (state:State) =
    {state with Counters= state.Counters |> Map.add counterType value}

let changeCounter counterType delta  (state:State)=
    state
    |> setCounter counterType ((state |> getCounter counterType) + delta)

let initializeCounters state =
    state
    |> setCounter Health InitialHealth

let restart eventHandler :Explorer<Cardinal.Direction, State>= 
    let gridLocations = 
        Utility.makeGrid (MazeColumns, MazeRows)
    let newExplorer = 
        gridLocations
        |> Maze.makeEmpty
        |> Maze.generate Utility.picker Utility.findAllCardinal
        |> createExplorer (fun m l -> (m.[l] |> Set.count) > 1) Cardinal.values ({Visited=Set.empty; Locks=Set.empty; Items=Map.empty; Visible=Set.empty; Counters = Map.empty; StartTime=System.DateTime.Now} |> initializeCounters)
    {newExplorer with 
        State = {newExplorer.State with 
                    Items = itemLocations newExplorer.Maze;
                    Visible = visibleLocations (newExplorer.Position, newExplorer.Orientation, newExplorer.Maze); 
                    Visited = [newExplorer.Position] |> Set.ofSeq}}
    |> addLocks Utility.pickMultiple

let updateVisited next state =
    {state with Visited = next |> state.Visited.Add |> Set.union state.Visible}

let updateVisible locations state =
    {state with Visible = locations}

let updateLock next state =
    if next |> state.Locks.Contains then
        {state with Locks=next |> state.Locks.Remove}
        |> changeCounter Keys -1
    else
        state

let pickupItem next state =
    {state with Items = next |> state.Items.Remove}

let pickupTreasure eventHandler next state =
    PlaySound Audio.AcquireLoot
    |> eventHandler
    state
    |> changeCounter Loot 1

let pickupTrap eventHandler next state =
    PlaySound Audio.TriggerTrap
    |> eventHandler
    state
    |> changeCounter Health -1

let pickupKey eventHandler next state =
    PlaySound Audio.AcquireKey
    |> eventHandler
    state
    |> changeCounter Keys 1

let pickupSword eventHandler next state =
    PlaySound Audio.AcquireSword
    |> eventHandler
    state

let pickupShield eventHandler next state =
    PlaySound Audio.AcquireShield
    |> eventHandler
    state

let pickupPotion eventHandler next state =
    PlaySound Audio.AcquirePotion
    |> eventHandler
    state

let pickupHourglass eventHandler next state =
    PlaySound Audio.AcquireHourglass
    |> eventHandler
    {state with StartTime = TimeBonusPerHourglass |> state.StartTime.AddSeconds}
    

let updateInventory eventHandler next state =
    match state.Items |> Map.tryFind next with
    | Some Treasure -> state |> pickupTreasure eventHandler next
    | Some Trap -> state |> pickupTrap eventHandler next
    | Some Key -> state |> pickupKey eventHandler next
    | Some Sword -> state |> pickupSword eventHandler next
    | Some Shield -> state |> pickupShield eventHandler next
    | Some Potion -> state |> pickupPotion eventHandler next
    | Some Hourglass -> state |> pickupHourglass eventHandler next
    | None -> state

    |> pickupItem next

let updateState eventHandler next explorer =
    explorer.State
    |> updateVisited next
    |> updateVisible ((next, explorer.Orientation, explorer.Maze) |> visibleLocations)
    |> updateInventory eventHandler next

let mustUnlock next (explorer: Explorer<Cardinal.Direction, State>) =
    next
    |> explorer.State.Locks.Contains

let canEnter next (explorer: Explorer<Cardinal.Direction, State>) =
    let canGo = next |> explorer.Maze.[explorer.Position].Contains
    let isLocked = explorer |> mustUnlock next
    let hasKey = explorer.State |> getCounter Keys |> (<=) 1
    canGo && if isLocked then hasKey else true


let enterLocation eventHandler next explorer =
    {explorer with 
        Position = next; 
        State = explorer |> updateState eventHandler next}

let unlockLocation eventHandler next explorer =
    PlaySound Audio.UnlockDoor
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

type Command = 
     | Turn of Cardinal.Direction
     | Move
     | Restart
     | Wait

let act (eventHandler:GameEvent->unit) command explorer =
    match command with
    | Turn direction -> if (explorer |> getExplorerState) = Alive then explorer |> turnAction eventHandler direction else explorer
    | Move           -> if (explorer |> getExplorerState) = Alive then explorer |> moveAction eventHandler else explorer
    | Restart        -> restart eventHandler
    | _              -> explorer

let mutable explorer = 
    restart()

