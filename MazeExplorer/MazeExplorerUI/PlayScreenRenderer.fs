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

let itemTiles =
    [((true,Some Key            ), ExplorerTiles.Key);
     ((true,Some Treasure       ), ExplorerTiles.Treasure);
     ((true,Some Trap           ), ExplorerTiles.Trap);
     ((true,Some Sword          ), ExplorerTiles.Sword);
     ((true,Some Shield         ), ExplorerTiles.Shield);
     ((true,Some Potion         ), ExplorerTiles.Potion);
     ((true,Some ItemType.Amulet), ExplorerTiles.Amulet);
     ((true,Some Exit           ), ExplorerTiles.Exit);
     ((true,Some Hourglass      ), ExplorerTiles.Hourglass);
     ((true,Some LoveInterest   ), ExplorerTiles.LoveInterest)]
    |> Map.ofSeq

let renderItem item isLocked gameOver location =
    itemTiles
    |> Map.tryFind ((gameOver || not isLocked), item)
    |> Option.bind (fun e-> e|> FrameBuffer.RenderTile (location.Column, location.Row) |> Some)
    |> ignore

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
     (ExplorerState.Exited,    (Tiles.fonts.[Colors.Gold],    "Exited! "));
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

let drawMonsterStats (explorer:Explorer.Explorer<Cardinal.Direction, State>) =
    let next = explorer.Orientation |> Cardinal.walk explorer.Position
    if (next |> explorer.State.Visible.Contains) && (next |> explorer.State.Locks.Contains |> not) then
        explorer.State.Monsters
        |> Map.tryFind next
        |> Option.bind (fun instance-> (instance, Monsters.descriptors.[instance.Type]) |> Some)
        |> Option.bind (fun (instance , descriptor) -> 
            Tiles.fonts.[Colors.Gold] |> FrameBuffer.renderString (FirstStatsColumn,7) descriptor.Name
            (instance, descriptor) |> Some)
        |> Option.bind (fun (instance, descriptor) ->
            Tiles.fonts.[Colors.Garnet] |> FrameBuffer.renderString (FirstStatsColumn,8) (descriptor.Health - instance.Damage |> sprintf "\u0003%3i")
            (instance, descriptor) |> Some)
        |> Option.bind (fun (instance, descriptor) ->
            ExplorerTiles.Sword |> FrameBuffer.RenderTile (FirstStatsColumn,9)
            Tiles.fonts.[Colors.Silver] |> FrameBuffer.renderString (FirstStatsColumn+1,9) (descriptor.Attack |> sprintf "%3i")
            (instance, descriptor) |> Some)
        |> Option.bind (fun (instance, descriptor) ->
            ExplorerTiles.Shield |> FrameBuffer.RenderTile (SecondStatsColumn,9)
            Tiles.fonts.[Colors.Aquamarine] |> FrameBuffer.renderString (SecondStatsColumn+1,9) (descriptor.Defense |> sprintf "%3i")
            (instance, descriptor) |> Some)
        |> ignore
    else
        ()

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
    explorer
    |> drawMonsterStats
    let (font, text) = statusTable.[explorer |> ExplorerState.getExplorerState]
    font
    |> FrameBuffer.renderString (FirstStatsColumn, 4) text
    let timeRemaining = explorer |> ExplorerState.getTimeLeft
    match explorer |> ExplorerState.getExplorerState, timeRemaining with
    | Alive, LotsOfTime       -> Some Tiles.fonts.[Colors.Emerald]
    | Alive, StillTimeLeft    -> Some Tiles.fonts.[Colors.Gold]
    | Alive, RunningOutOfTime -> Some Tiles.fonts.[Colors.Garnet]
    | _, _                    -> None
    |> Option.bind (fun e-> e |> FrameBuffer.renderString (MazeColumns,5) (timeRemaining |> sprintf "Time %3i") |> Some)
    |> ignore

