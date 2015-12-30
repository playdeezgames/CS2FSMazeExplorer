module OptionsScreenRenderer

open GameData
open GameSettings

let always options =
    true

let isSfx value options=
    options.Sfx = value

let isPauseAllowed value options=
    options.PauseAllowed = value

let isDifficulty value options =
    options.DifficultyLevel = value

let optionsScreenStrings=
    [(always              , Colors.Silver , (0, 0 ), "Game Options");
     (isSfx true          , Colors.Emerald, (0, 2 ), "Sounds: ON");
     (isSfx false         , Colors.Garnet , (0, 2 ), "Sounds: OFF");
     (isSfx true          , Colors.Tin    , (0, 3 ), "[M]ute sounds");
     (isSfx false         , Colors.Tin    , (0, 3 ), "Un[m]ute sounds");
     (isPauseAllowed true , Colors.Emerald, (0, 5 ), "Pause Game: ON");
     (isPauseAllowed false, Colors.Garnet , (0, 5 ), "Pause Game: OFF");
     (isPauseAllowed true , Colors.Tin    , (0, 6 ), "Disallow [P]ause");
     (isPauseAllowed false, Colors.Tin    , (0, 6 ), "Allow [P]ause");
     (isDifficulty Easy, Colors.Emerald    , (0, 8 ), "Difficulty: Easy");
     (isDifficulty Normal, Colors.Gold    , (0, 8 ), "Difficulty: Normal");
     (isDifficulty Hard, Colors.Garnet    , (0, 8 ), "Difficulty: Hard");
     (always, Colors.Tin    , (0, 9 ), "[\u0018/\u0019] Change Difficulty");
     (always, Colors.Copper    , (0, 10 ), "(Difficulty changes will not")
     (always, Colors.Copper    , (0, 11 ), "affect games in progress)");
     (always              , Colors.Aquamarine   , (0, 17), "Esc - Go Back")]

let drawOptionsScreen options =
    FrameBuffer.clear Colors.Amethyst
    optionsScreenStrings
    |> List.iter (fun (cond,c,xy,s) -> if cond(options) then Tiles.fonts.[c] |> FrameBuffer.renderString xy s else ())



