module PlayScreenRenderer

open Location
open GameData
open Difficulty
open Constants
open State
open ExplorerState
open Monsters

let FirstStatsColumn = MazeColumns
let SecondStatsColumn = FirstStatsColumn + (TileColumns - MazeColumns) / 2
let UIKey = new Tile.Tile(ExplorerPatterns.Key, Colors.Transparent, Colors.Copper)

let determineLockTile (hasKey:bool) (exits:Set<Cardinal.Direction>) =
    let flags = (exits.Contains Cardinal.North, exits.Contains Cardinal.East, exits.Contains Cardinal.South, exits.Contains Cardinal.West)
    Tiles.lock |> Map.find hasKey |> Map.tryFind flags

let determineCellTile (exits:Set<Cardinal.Direction>) =
    let flags = (exits.Contains Cardinal.North, exits.Contains Cardinal.East, exits.Contains Cardinal.South, exits.Contains Cardinal.West)
    Tiles.room.[flags]

let toDirections location (exits:Set<Location>) =
    Cardinal.values
    |> List.filter (fun d->d |> Cardinal.walk location |> exits.Contains )
    |> Set.ofList

let renderLock (location:Location) (exits:Set<Location>) (isLocked:bool) (hasKey:bool) =
    if isLocked then
        exits
        |> toDirections location
        |> determineLockTile hasKey
        |> Option.get
        |> FrameBuffer.RenderTile (location.Column, location.Row)
    else
        ()

let renderWalls (location:Location) (exits:Set<Location>) =
    exits
    |> toDirections location
    |> determineCellTile
    |> FrameBuffer.RenderTile (location.Column, location.Row)

let renderItem item isLocked gameOver location =
    match (gameOver || not isLocked), item with
    | true, Some Key ->
                    ExplorerTiles.Key
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some Treasure ->
                    ExplorerTiles.Treasure
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some Trap ->
                    ExplorerTiles.Trap
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some Sword ->
                    ExplorerTiles.Sword
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some Shield ->
                    ExplorerTiles.Shield
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some Potion ->
                    ExplorerTiles.Potion
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some ItemType.Amulet ->
                    ExplorerTiles.Amulet
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some Exit ->
                    ExplorerTiles.Exit
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some Hourglass ->
                    ExplorerTiles.Hourglass
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some LoveInterest ->
                    ExplorerTiles.LoveInterest
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | _,_ -> ()

let renderMonster instance isLocked location =
    if isLocked |> not then
        Tiles.monsters.[instance.Type]
        |> FrameBuffer.RenderTile (location.Column, location.Row)
    else
        ()

let renderRoom (location:Location) (exits:Set<Location>) (visited:bool) (visible:bool) (item:ItemType option) (monster: Monsters.Instance option) (isLocked:bool) (hasKeys:bool) (hasAmulet:bool) (gameOver:bool) =
    if visible then
        Tiles.Visible
        |> FrameBuffer.RenderTile (location.Column, location.Row)
        if monster.IsSome then
            location
            |> renderMonster (monster |> Option.get) isLocked
        else
            location
            |> renderItem item isLocked gameOver
        renderWalls location exits
        renderLock location exits isLocked hasKeys
    elif gameOver then
        if visited then
            Tiles.Empty
            |> FrameBuffer.RenderTile (location.Column, location.Row)
        else
            Tiles.NeverVisited
            |> FrameBuffer.RenderTile (location.Column, location.Row)
        location
        |> renderItem item isLocked gameOver
        renderWalls location exits
        renderLock location exits isLocked hasKeys
    elif visited then
        Tiles.Empty
        |> FrameBuffer.RenderTile (location.Column, location.Row)
        renderWalls location exits
        if monster.IsSome then
            location
            |> renderMonster (monster |> Option.get) isLocked
        elif hasAmulet then
            location
            |> renderItem item isLocked gameOver
        else
            ()
        renderLock location exits isLocked hasKeys
    else
        Tiles.Hidden
        |> FrameBuffer.RenderTile (location.Column, location.Row)
        
let statusTable = 
    [(ExplorerState.Alive,     (Tiles.fonts.[Colors.Emerald], "Alive!  "));
     (ExplorerState.Dead,      (Tiles.fonts.[Colors.Garnet],  "Dead!   "));
     (ExplorerState.Win,       (Tiles.fonts.[Colors.Gold],    "Win!    "));
     (ExplorerState.OutOfTime, (Tiles.fonts.[Colors.Garnet],  "Times Up"))]
    |> Map.ofSeq

let renderExplorer orientation location =
    Tiles.explorer.[orientation]
    |> FrameBuffer.RenderTile (location.Column, location.Row)

let playScreenStrings =
    [(Colors.Gold,       (SecondStatsColumn    ,  0), fun s-> s |> getCounter Loot    |> sprintf "$%3i");
     (Colors.Copper,     (FirstStatsColumn  + 1,  1), fun s-> s |> getCounter Keys    |> sprintf "%3i");
     (Colors.Amethyst,   (SecondStatsColumn + 1,  1), fun s-> s |> getCounter Potions |> sprintf "%3i");
     (Colors.Silver,     (FirstStatsColumn  + 1,  2), fun s-> s |> getCounter Attack  |> sprintf "%3i");
     (Colors.Aquamarine, (SecondStatsColumn + 1,  2), fun s-> s |> getCounter Defense |> sprintf "%3i");
     (Colors.Garnet,     (FirstStatsColumn     ,  0), fun s-> ((s |> getCounter Health)-(s |> getCounter Wounds))    |> sprintf "\u0003%3i");
     (Colors.Sapphire,   (FirstStatsColumn     , 16), fun s->  "\u0018\u0019\u001B\u001AMove");
     (Colors.Sapphire,   (FirstStatsColumn     , 17), fun s->  "[Q]uit")]

let playScreenTiles =
    [(UIKey,                (FirstStatsColumn  ,1));
     (ExplorerTiles.Potion, (SecondStatsColumn ,1));
     (ExplorerTiles.Sword,  (FirstStatsColumn  ,2));
     (ExplorerTiles.Shield, (SecondStatsColumn ,2))]

let (|LotsOfTime|StillTimeLeft|RunningOutOfTime|) timeRemaining =
    if timeRemaining > TimeLimit / 2 then
        LotsOfTime
    elif timeRemaining > TimeLimit / 4 then
        StillTimeLeft
    else
        RunningOutOfTime

let drawGameScreen (explorer:Explorer.Explorer<Cardinal.Direction, State>) =
    Colors.Onyx
    |> FrameBuffer.clear
    explorer.Maze
    |> Map.iter(fun k v -> renderRoom k v 
                                (k |> explorer.State.Visited.Contains) //visited
                                (k |> explorer.State.Visible.Contains) //visible
                                (if k |> explorer.State.Items.ContainsKey then Some explorer.State.Items.[k] else None) //item
                                (if k |> explorer.State.Monsters.ContainsKey then Some explorer.State.Monsters.[k] else None) //monster
                                (k |> explorer.State.Locks.Contains) //locked
                                (explorer.State |> getCounter Keys > 0) //has keys
                                (explorer.State |> getCounter Amulet > 0) //has amulet
                                (explorer |> getExplorerState = Alive |> not)) //game over
    explorer.Position
    |> renderExplorer explorer.Orientation
    playScreenStrings
    |> List.iter (fun (c,xy,xform) -> Tiles.fonts.[c] |> FrameBuffer.renderString xy (explorer.State |> xform))
    playScreenTiles
    |> List.iter (fun (t,xy) -> t |> FrameBuffer.RenderTile xy)
    let (font, text) = statusTable.[explorer |> ExplorerState.getExplorerState]
    font
    |> FrameBuffer.renderString (FirstStatsColumn, 4) text
    let timeRemaining = explorer |> ExplorerState.getTimeLeft
    let timePrintingFunction = FrameBuffer.renderString (MazeColumns,5) (timeRemaining |> sprintf "Time %3i")
    match explorer |> ExplorerState.getExplorerState, timeRemaining with
    | Alive, LotsOfTime       -> Tiles.fonts.[Colors.Emerald] |> timePrintingFunction
    | Alive, StillTimeLeft    -> Tiles.fonts.[Colors.Gold] |> timePrintingFunction
    | Alive, RunningOutOfTime -> Tiles.fonts.[Colors.Garnet] |> timePrintingFunction
    | _, _                    -> ()
    




