module ItemGeneration

open State
open Difficulty

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
    [(Treasure,25);
    (Trap,20);
    (Shield,15);
    (Potion,5);
    (Key,10)]
    |> WeightedGenerator.ofPairs

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
