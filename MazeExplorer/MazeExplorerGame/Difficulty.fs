module Difficulty

open Constants

type DifficultyLevel = 
    | Easy
    | Normal
    | Hard

type DifficultySettings =
    { Hourglasses: int;
    Potions: int;
    Swords:int;
    TimeLimit: int;
    TimeBonus: int;
    InitialHealth: int;
    DefenseSavingThrow: int}

let difficultySettings =
    [Easy,{Hourglasses = EasyHourglassCount; Swords = EasySwordCount; Potions = EasyPotionCount; TimeLimit = TimeLimitEasy; TimeBonus = TimeBonusEasy; InitialHealth = InitialHealthEasy; DefenseSavingThrow = DefenseSavingThrowEasy};
    Normal,{Hourglasses=NormalHourglassCount;Swords=NormalSwordCount; Potions=NormalPotionCount; TimeLimit = TimeLimitNormal; TimeBonus = TimeBonusNormal; InitialHealth = InitialHealthNormal; DefenseSavingThrow = DefenseSavingThrowNormal};
    Hard,{Hourglasses=HardHourglassCount;Swords=HardSwordCount; Potions=HardPotionCount; TimeLimit = TimeLimitHard; TimeBonus = TimeBonusHard; InitialHealth = InitialHealthHard; DefenseSavingThrow = DefenseSavingThrowHard}]
    |> Map.ofSeq



