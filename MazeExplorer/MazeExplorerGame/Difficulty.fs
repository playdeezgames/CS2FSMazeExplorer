module Difficulty

open Constants

type DifficultyLevel = 
    | Easy
    | Normal
    | Hard

type DifficultySettings =
    { Hourglasses: int;
    Swords:int}

let difficultySettings =
    [Easy,{Hourglasses=EasyHourglassCount;Swords=EasySwordCount};
    Normal,{Hourglasses=NormalHourglassCount;Swords=NormalSwordCount};
    Hard,{Hourglasses=HardHourglassCount;Swords=HardSwordCount}]
    |> Map.ofSeq



