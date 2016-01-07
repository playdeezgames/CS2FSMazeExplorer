module Initialization

open Location
open Explorer
open State
open Constants
open ItemGeneration
open Monsters

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

let addMonsters (rng:int->int) (explorer:Explorer<Cardinal.Direction, State>) =
    let monsters = 
        explorer.State.Items 
        |> Map.toSeq
        |> Seq.map (fun (xy,item)-> (xy, ItemGeneration.itemMonsters.[item] |> WeightedGenerator.generate rng))
        |> Seq.filter (fun (xy,monsterType) -> monsterType |> Option.isSome)
        |> Seq.map (fun (xy,monsterType) -> (xy,{Type=monsterType |> Option.get;Damage=0}))
        |> Map.ofSeq
    {explorer with State ={explorer.State with Monsters = monsters}}

let rec visibleLocations (location:Location, direction:Cardinal.Direction, maze:Maze.Maze) =
    let nextLocation = Cardinal.walk location direction
    if maze.[location].Contains nextLocation then
        visibleLocations (nextLocation, direction, maze)
        |> Set.add location
    else
        [location]
        |> Set.ofSeq

let createExplorer = Explorer.create (fun l->Utility.random.Next()) (fun d->Utility.random.Next())

let makeGrid (columns, rows) = 
    [for c in [0..columns-1] do
        for r in [0..rows-1] do
            yield {Column=c; Row=r}]

let findAllCardinal = Neighbor.findAll Cardinal.walk Cardinal.values

let restart difficultyLevel eventHandler :Explorer<Cardinal.Direction, State>= 
    let gridLocations = 
        makeGrid (MazeColumns, MazeRows)
    let difficultySetting = Difficulty.difficultySettings.[difficultyLevel]
    let newExplorer = 
        gridLocations
        |> Maze.makeEmpty
        |> Maze.generate Utility.picker findAllCardinal
        |> createExplorer (fun m l -> (m.[l] |> Set.count) > 1) Cardinal.values ({Visited=Set.empty; 
                                                                Locks=Set.empty; 
                                                                Items=Map.empty; 
                                                                Visible=Set.empty; 
                                                                Kills = Map.empty; 
                                                                Counters = Map.empty;
                                                                Monsters = Map.empty; 
                                                                EndTime=System.DateTime.Now.AddSeconds (difficultySetting.TimeLimit |> float)} 
                                                                |> initializeCounters)
    {newExplorer with 
        State = {newExplorer.State with 
                    Items = itemLocations  difficultyLevel newExplorer.Maze;
                    Visible = visibleLocations (newExplorer.Position, newExplorer.Orientation, newExplorer.Maze); 
                    Visited = [newExplorer.Position] |> Set.ofSeq}
                    |> setCounter TimeBonus difficultySetting.TimeBonus
                    |> setCounter TimeLimit difficultySetting.TimeLimit
                    |> setCounter Health difficultySetting.InitialHealth
                    |> setCounter DefenseSavingThrow difficultySetting.DefenseSavingThrow}
    |> addMonsters (fun n->Utility.random.Next(n))
    |> addLocks Utility.pickMultiple


