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

type DifficultyLevel = 
    | Easy
    | Normal
    | Hard

type DifficultySettings =
    { Hourglasses: int;
    Swords:int}

let difficultySettings =
    [Easy,{Hourglasses=6;Swords=5};
    Normal,{Hourglasses=5;Swords=4};
    Hard,{Hourglasses=4;Swords=3}]
    |> Map.ofSeq

type Sfx =
    | AcquireLoot
    | AcquireHourglass
    | AcquireKey
    | AcquirePotion
    | AcquireShield
    | AcquireSword
    | TriggerTrap
    | UnlockDoor

type GameEvent =
    | PlaySound of Sfx

type ItemType = 
    | Treasure
    | Trap
    | Key
    | Sword
    | Shield
    | Hourglass
    | Potion
    | LoveInterest

type CounterType =
    | Loot
    | Health
    | Keys
    | Potions

let fixedItemList difficultyLevel =
    let difficultySetting =
        difficultySettings.[difficultyLevel]
    [(LoveInterest,1);
    (Hourglass, difficultySetting.Hourglasses);
    (Sword, difficultySetting.Swords)]
    |> List.map (fun (k,v)-> [1..v] |> List.map (fun e-> k))
    |> List.reduce (@)
    |> Seq.ofList

let variableItemGenerator =
    [(Treasure,30);
    (Trap,20);
    (Shield,5);
    (Potion,5);
    (Key,10)]
    |> WeightedGenerator.ofPairs

type State = 
    {Visited: Set<Location>; 
    Items: Map<Location,ItemType>; 
    Locks: Set<Location>;
    Visible: Set<Location>; 
    Counters : Map<CounterType,int>;
    EndTime: System.DateTime}

type PausedExplorer<'direction,'state> = Explorer<'direction,'state> * System.DateTime

type ExplorerState = 
    | Win
    | Alive
    | Dead
    | OutOfTime

type GameState =
    | TitleScreen
    | HelpScreen of PausedExplorer<Cardinal.Direction, State> option
    | OptionsScreen of PausedExplorer<Cardinal.Direction, State> option
    | PlayScreen of Explorer<Cardinal.Direction, State>
    | GameOverScreen of Explorer<Cardinal.Direction, State> * ExplorerState
    | PauseScreen of PausedExplorer<Cardinal.Direction, State>

let pauseExplorer explorer =
    (explorer, System.DateTime.Now)

let unpauseExplorer pausedExplorer = 
    let explorer, pauseTime = pausedExplorer
    {explorer with State = {explorer.State with EndTime = System.DateTime.Now + (explorer.State.EndTime - pauseTime)}}

let rec visibleLocations (location:Location, direction:Cardinal.Direction, maze:Maze.Maze) =
    let nextLocation = Cardinal.walk location direction
    if maze.[location].Contains nextLocation then
        visibleLocations (nextLocation, direction, maze)
        |> Set.add location
    else
        [location]
        |> Set.ofSeq

let generateVariableItem()= WeightedGenerator.generate (fun n->Utility.random.Next(n)) variableItemGenerator

let generateItemList difficultyLevel count =
    let fixedItems = 
        difficultyLevel
        |> fixedItemList
        |> Seq.truncate count
    let variableItems =
        [1..count - (fixedItems |> Seq.length)]
        |> Seq.map (fun e-> generateVariableItem())
    fixedItems
    |> Seq.append variableItems
    |> Seq.sortBy (fun e->Utility.random.Next())

let itemLocations difficultyLevel (maze:Maze.Maze) =
    let locations = 
        maze
        |> Map.toSeq
        |> Seq.filter (fun (location, exits) -> (exits |> Set.count) = 1)
        |> Seq.map (fun (k,v)->k)
    generateItemList difficultyLevel (locations |> Seq.length)
    |> Seq.zip locations
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
    <= 0

let getTimeLeft explorer =
    let timeRemaining = (explorer.State.EndTime - System.DateTime.Now).TotalSeconds |> int
    if timeRemaining < 0 then
        0
    else
        timeRemaining

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

let restart difficultyLevel eventHandler :Explorer<Cardinal.Direction, State>= 
    let gridLocations = 
        Utility.makeGrid (MazeColumns, MazeRows)
    let newExplorer = 
        gridLocations
        |> Maze.makeEmpty
        |> Maze.generate Utility.picker Utility.findAllCardinal
        |> createExplorer (fun m l -> (m.[l] |> Set.count) > 1) Cardinal.values ({Visited=Set.empty; Locks=Set.empty; Items=Map.empty; Visible=Set.empty; Counters = Map.empty; EndTime=System.DateTime.Now.AddSeconds(TimeLimit |> float)} |> initializeCounters)
    {newExplorer with 
        State = {newExplorer.State with 
                    Items = itemLocations  difficultyLevel newExplorer.Maze;
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
    PlaySound AcquireLoot
    |> eventHandler
    state
    |> changeCounter Loot 1

let pickupTrap eventHandler next state =
    PlaySound TriggerTrap
    |> eventHandler
    state
    |> changeCounter Health -1

let pickupKey eventHandler next state =
    PlaySound AcquireKey
    |> eventHandler
    state
    |> changeCounter Keys 1

let pickupSword eventHandler next state =
    PlaySound AcquireSword
    |> eventHandler
    state

let pickupShield eventHandler next state =
    PlaySound AcquireShield
    |> eventHandler
    state

let pickupPotion eventHandler next state =
    PlaySound AcquirePotion
    |> eventHandler
    state

let pickupHourglass eventHandler next state =
    PlaySound AcquireHourglass
    |> eventHandler
    {state with EndTime = TimeBonusPerHourglass |> state.EndTime.AddSeconds}

let updateInventory eventHandler next state =
    match state.Items |> Map.tryFind next with
    | Some Treasure -> state |> pickupTreasure eventHandler next
    | Some Trap -> state |> pickupTrap eventHandler next
    | Some Key -> state |> pickupKey eventHandler next
    | Some Sword -> state |> pickupSword eventHandler next
    | Some Shield -> state |> pickupShield eventHandler next
    | Some Potion -> state |> pickupPotion eventHandler next
    | Some Hourglass -> state |> pickupHourglass eventHandler next
    | Some LoveInterest -> state
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

type Command = 
     | Turn of Cardinal.Direction
     | Move
     | Quit
     | Wait
     | Pause
     | Help
     | Options

let act difficultyLevel (eventHandler:GameEvent->unit) command explorer =
    match command with
    | Turn direction -> if (explorer |> getExplorerState) = Alive then explorer |> turnAction eventHandler direction else explorer
    | Move           -> if (explorer |> getExplorerState) = Alive then explorer |> moveAction eventHandler else explorer
    | _              -> explorer

let mutable gameState = TitleScreen
