module ScoreScreenRenderer

open PausedExplorer
open State

let stats = 
    [("Loot",Loot,10);
    ("Keys",KeysAcquired,25);
    ("Pots",PotionsAcquired,50);
    ("Swrd",SwordsAcquired,50);
    ("Shld",ShieldsAcquired,100);
    ("Trap",TrapsSprung,-25);
    ("Door",DoorsUnlocked,25);
    ("Hrgl",HourglassesAcquired,50);
    ("Amul",Amulet,500);
    ("Exit",Stairs,250);
    ]

let scoreScreenStrings =
    [(Colors.Onyx,(0,0),fun _->"Final Score");
     (Colors.Onyx,(0,17),fun _->"Esc - Main Menu")]

let getItemScores state =
    stats
    |> Seq.map (fun (name, counter, score)->  sprintf "%4s%2i@%3i=%5i" name  (state |> getCounter counter) score (state |> getCounter counter |> (*) score), (state |> getCounter counter |> (*) score))

let getMonsterScores state = 
    state.Kills
    |> Map.toSeq
    |> Seq.map (fun (k,v)->(Monsters.descriptors.[k].Abbr,v,Monsters.descriptors.[k].Score))
    |> Seq.map (fun (name, count, score)-> sprintf "%4s%2i@%3i=%5i" name count score (count*score), (count*score))


let drawScoreScreen (state: State) =
    FrameBuffer.clear Colors.Silver
    scoreScreenStrings
    |> List.iter (fun (c,xy,s) -> Tiles.fonts.[c] |> FrameBuffer.renderString xy (state |> s))
    let row,itemTotal = 
        state
        |> getItemScores
        |> Seq.fold (fun (row, acc) (text, score) -> 
            Tiles.fonts.[Colors.Onyx]
            |> FrameBuffer.renderString (0,row) text            
            (row + 1, acc + score)) (2,0)
    Tiles.fonts.[Colors.Onyx]
    |> FrameBuffer.renderString (0,row) (itemTotal |> sprintf "Item Total%6i")
    let monsterRow,monsterTotal = 
        state
        |> getMonsterScores
        |> Seq.fold (fun (row, acc) (text, score) -> 
            Tiles.fonts.[Colors.Onyx]
            |> FrameBuffer.renderString (Constants.TileColumns/2,row) text            
            (row + 1, acc + score)) (2,0)
    Tiles.fonts.[Colors.Onyx]
    |> FrameBuffer.renderString (Constants.TileColumns/2,monsterRow) (monsterTotal |> sprintf "Mon. Total%6i")
    Tiles.fonts.[Colors.Onyx]
    |> FrameBuffer.renderString (0,row + 2) ((monsterTotal + itemTotal) |> sprintf "Grand Total%6i")
