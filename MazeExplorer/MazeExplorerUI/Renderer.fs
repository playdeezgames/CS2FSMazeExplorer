module Renderer

open Location
open GameData

let handleGameEvent (event:GameData.GameEvent) =
    match event with
    | PlaySound sfx -> Audio.playSound sfx

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
    [(GameData.Alive,     (Tiles.emeraldFont, "Alive!  "));
     (GameData.Dead,      (Tiles.garnetFont,  "Dead!   "));
     (GameData.Win,       (Tiles.goldFont,    "Win!    "));
     (GameData.OutOfTime, (Tiles.garnetFont,  "Times Up"))]
    |> Map.ofSeq

let redraw graphics =
    explorer.Maze
    |> Map.iter(fun k v -> renderRoom k v 
                                (k |> explorer.State.Visited.Contains) //visited
                                (k |> explorer.State.Visible.Contains) //visible
                                (if k |> explorer.State.Items.ContainsKey then Some explorer.State.Items.[k] else None) //item
                                (k |> explorer.State.Locks.Contains) //locked
                                (explorer |> getExplorerState = Alive |> not)) //game over
    Tiles.explorer.[explorer.Orientation]
    |> FrameBuffer.RenderTile (explorer.Position.Column, explorer.Position.Row)
    Tiles.sapphireFont
    |> FrameBuffer.renderString (MazeColumns,0) (explorer.State.Visited |> Set.count |> sprintf "Room %3i")
    Tiles.goldFont
    |> FrameBuffer.renderString (MazeColumns,1) (explorer.State |> getCounter Loot |> sprintf "Loot %3i" )
    Tiles.garnetFont
    |> FrameBuffer.renderString (MazeColumns,2) (explorer.State |> getCounter Health |> sprintf "\u0003\u0003\u0003\u0003 %3i")
    Tiles.sapphireFont
    |> FrameBuffer.renderString (MazeColumns,16) "\u0018\u0019\u001B\u001AMove"
    Tiles.sapphireFont
    |> FrameBuffer.renderString (MazeColumns,17) "[R]eset"
    Tiles.goldFont
    |> FrameBuffer.renderString (MazeColumns,3) (explorer.State |> getCounter Keys |> sprintf "Keys %3i" )
    let (font, text) = statusTable.[explorer |> GameData.getExplorerState]
    font
    |> FrameBuffer.renderString (MazeColumns, 4) text
    let timeRemaining = explorer |> GameData.getTimeLeft
    if (explorer |> GameData.getExplorerState) = GameData.Alive then
        let timeFont = 
            if timeRemaining >= GameData.TimeLimit / 2 then
                Tiles.emeraldFont
            elif timeRemaining >= GameData.TimeLimit / 4 then
                Tiles.goldFont
            else
                Tiles.garnetFont
        timeFont
        |> FrameBuffer.renderString (MazeColumns,5) (timeRemaining |> sprintf "Time %3i")
    else
        Tiles.garnetFont
        |> FrameBuffer.renderString (MazeColumns,5) "        "
    


