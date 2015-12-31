module PlayScreenRenderer

open Location
open GameData
open Difficulty
open Constants
open State
open ExplorerState

let determineLockTile (exits:Set<Cardinal.Direction>) =
    let flags = (exits.Contains Cardinal.North, exits.Contains Cardinal.East, exits.Contains Cardinal.South, exits.Contains Cardinal.West)
    Tiles.lock |> Map.tryFind flags
        

let determineCellTile (exits:Set<Cardinal.Direction>) =
    let flags = (exits.Contains Cardinal.North, exits.Contains Cardinal.East, exits.Contains Cardinal.South, exits.Contains Cardinal.West)
    Tiles.room.[flags]

let toDirections location (exits:Set<Location>) =
    Cardinal.values
    |> List.filter (fun d->d |> Cardinal.walk location |> exits.Contains )
    |> Set.ofList

let renderLock (location:Location) (exits:Set<Location>) (isLocked:bool) =
    if isLocked then
        exits
        |> toDirections location
        |> determineLockTile
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
    | true, Some Hourglass ->
                    ExplorerTiles.Hourglass
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | true, Some LoveInterest ->
                    ExplorerTiles.LoveInterest
                    |> FrameBuffer.RenderTile (location.Column, location.Row)
    | _,_ -> ()


let renderRoom (location:Location) (exits:Set<Location>) (visited:bool) (visible:bool) (item:ItemType option) (isLocked:bool) (gameOver:bool) =
    if visible then
        Tiles.Visible
        |> FrameBuffer.RenderTile (location.Column, location.Row)
        location
        |> renderItem item isLocked gameOver
        renderWalls location exits
        renderLock location exits isLocked
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
        renderLock location exits isLocked
    elif visited then
        Tiles.Empty
        |> FrameBuffer.RenderTile (location.Column, location.Row)
        renderWalls location exits
        renderLock location exits isLocked
    else
        Tiles.Hidden
        |> FrameBuffer.RenderTile (location.Column, location.Row)
        
let statusTable = 
    [(ExplorerState.Alive,     (Tiles.fonts.[Colors.Emerald], "Alive!  "));
     (ExplorerState.Dead,      (Tiles.fonts.[Colors.Garnet],  "Dead!   "));
     (ExplorerState.Win,       (Tiles.fonts.[Colors.Gold],    "Win!    "));
     (ExplorerState.OutOfTime, (Tiles.fonts.[Colors.Garnet],  "Times Up"))]
    |> Map.ofSeq

let drawGameScreen (explorer:Explorer.Explorer<Cardinal.Direction, State>) =
    Colors.Onyx
    |> FrameBuffer.clear
    explorer.Maze
    |> Map.iter(fun k v -> renderRoom k v 
                                (k |> explorer.State.Visited.Contains) //visited
                                (k |> explorer.State.Visible.Contains) //visible
                                (if k |> explorer.State.Items.ContainsKey then Some explorer.State.Items.[k] else None) //item
                                (k |> explorer.State.Locks.Contains) //locked
                                (explorer |> getExplorerState = Alive |> not)) //game over
    Tiles.explorer.[explorer.Orientation]
    |> FrameBuffer.RenderTile (explorer.Position.Column, explorer.Position.Row)
    Tiles.fonts.[Colors.Sapphire]
    |> FrameBuffer.renderString (MazeColumns,0) (explorer.State.Visited |> Set.count |> sprintf "Room %3i")
    Tiles.fonts.[Colors.Gold]
    |> FrameBuffer.renderString (MazeColumns,1) (explorer.State |> getCounter Loot |> sprintf "Loot %3i" )
    Tiles.fonts.[Colors.Garnet]
    |> FrameBuffer.renderString (MazeColumns,2) (explorer.State |> getCounter Health |> sprintf "\u0003\u0003\u0003\u0003 %3i")
    Tiles.fonts.[Colors.Sapphire]
    |> FrameBuffer.renderString (MazeColumns,16) "\u0018\u0019\u001B\u001AMove"
    Tiles.fonts.[Colors.Sapphire]
    |> FrameBuffer.renderString (MazeColumns,17) "[Q]uit"
    Tiles.fonts.[Colors.Gold]
    |> FrameBuffer.renderString (MazeColumns,3) (explorer.State |> getCounter Keys |> sprintf "Keys %3i" )
    let (font, text) = statusTable.[explorer |> ExplorerState.getExplorerState]
    font
    |> FrameBuffer.renderString (MazeColumns, 4) text
    let timeRemaining = explorer |> ExplorerState.getTimeLeft
    if (explorer |> ExplorerState.getExplorerState) = ExplorerState.Alive then
        let timeFont = //TODO: make active pattern!
            if timeRemaining >= TimeLimit / 2 then
                Tiles.fonts.[Colors.Emerald]
            elif timeRemaining >= TimeLimit / 4 then
                Tiles.fonts.[Colors.Gold]
            else
                Tiles.fonts.[Colors.Garnet]
        timeFont
        |> FrameBuffer.renderString (MazeColumns,5) (timeRemaining |> sprintf "Time %3i")
    else
        Tiles.fonts.[Colors.Garnet]
        |> FrameBuffer.renderString (MazeColumns,5) "        "
    




