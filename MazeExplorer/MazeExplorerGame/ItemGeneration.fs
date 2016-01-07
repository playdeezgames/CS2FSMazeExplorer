module ItemGeneration

open State
open Difficulty

let fixedItemList difficultyLevel =
    let difficultySetting =
        difficultySettings.[difficultyLevel]
    [(LoveInterest,1);
    (ItemType.Amulet,1);
    (Potion,difficultySetting.Potions);
    (Exit,1);
    (Hourglass, difficultySetting.Hourglasses);
    (Sword, difficultySetting.Swords)]
    |> List.map (fun (k,v)-> [1..v] |> List.map (fun e-> k))
    |> List.reduce (@)
    |> Seq.ofList

let itemMonsters =
    [(Treasure,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(None, 3);]);
    (Trap,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(None, 2);]);
    (Key,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(Some Monsters.Mummy, 1);(None, 2);]);
    (Sword,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(None, 3);]);
    (Shield,[(Some Monsters.Zombie, 3);(Some Monsters.Mummy, 2);(None, 5)]);
    (Hourglass,[(Some Monsters.Zombie, 3);(Some Monsters.Mummy, 2);(Some Monsters.Ghoul, 1);]);
    (Potion,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(Some Monsters.Ghoul, 1);(None, 2);]);
    (ItemType.Amulet,[(Some Monsters.Golem, 1)]);
    (Exit,[(None, 1)]);
    (LoveInterest,[(Some Monsters.Wizard, 1)])]
    |> Map.ofSeq
    |> Map.map (fun k v ->v |> Map.ofSeq)

let variableItemGenerator =
    [(Treasure,25);
    (Trap,20);
    (Shield,10);
    (Key,15)]
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
