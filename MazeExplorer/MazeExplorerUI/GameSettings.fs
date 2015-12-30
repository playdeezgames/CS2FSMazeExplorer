module GameSettings

open GameData

type Options =
    {Sfx:bool;
    PauseAllowed:bool;
    DifficultyLevel:DifficultyLevel}

let mutable options =
    {Sfx=true;
    PauseAllowed=true;
    DifficultyLevel=DifficultyLevel.Normal}
