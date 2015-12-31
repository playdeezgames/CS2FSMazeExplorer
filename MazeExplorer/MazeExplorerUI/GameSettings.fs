module GameSettings

open Difficulty

type Options =
    {Sfx:bool;
    PauseAllowed:bool;
    DifficultyLevel:DifficultyLevel}

let mutable options =
    {Sfx=true;
    PauseAllowed=true;
    DifficultyLevel=DifficultyLevel.Normal}
