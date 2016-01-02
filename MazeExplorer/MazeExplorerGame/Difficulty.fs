module Difficulty

open Constants

type DifficultyLevel = 
    | Easy
    | Normal
    | Hard

type DifficultySettings =
    { Hourglasses: int;
    Potions: int;
    Swords:int}

let difficultySettings =
    [Easy,{Hourglasses=EasyHourglassCount;Swords=EasySwordCount; Potions=EasyPotionCount};
    Normal,{Hourglasses=NormalHourglassCount;Swords=NormalSwordCount; Potions=NormalPotionCount};
    Hard,{Hourglasses=HardHourglassCount;Swords=HardSwordCount; Potions=HardPotionCount}]
    |> Map.ofSeq



