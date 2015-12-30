module GameEvents

open GameData

let handle (event:GameData.GameEvent) =
    match event with
    | PlaySound sfx -> Audio.playSound sfx


