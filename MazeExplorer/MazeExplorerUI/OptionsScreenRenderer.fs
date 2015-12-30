module OptionsScreenRenderer

open GameData

// What are the options I want to set?
// A) SFX toggle/volume?
// B) Difficulty level?
// C) Hardcore/No Pause mode

let optionsScreenStrings=
    [((fun (o:GameSettings.Options) -> true                 ), Tiles.fonts.[Colors.Silver], (0, 0 ), "Options");
     ((fun (o:GameSettings.Options) -> o.Sfx                ), Tiles.fonts.[Colors.Emerald], (0, 2 ), "Sounds: ON");
     ((fun (o:GameSettings.Options) -> o.Sfx |> not         ), Tiles.fonts.[Colors.Garnet], (0, 2 ), "Sounds: OFF");
     ((fun (o:GameSettings.Options) -> o.Sfx                ), Tiles.fonts.[Colors.Tin], (0, 3 ), "[M]ute sounds");
     ((fun (o:GameSettings.Options) -> o.Sfx |> not         ), Tiles.fonts.[Colors.Tin], (0, 3 ), "Un[m]ute sounds");
     ((fun (o:GameSettings.Options) -> o.PauseAllowed       ), Tiles.fonts.[Colors.Emerald], (0, 5 ), "Pause Game: ON");
     ((fun (o:GameSettings.Options) -> o.PauseAllowed |> not), Tiles.fonts.[Colors.Garnet], (0, 5 ), "Pause Game: OFF");
     ((fun (o:GameSettings.Options) -> o.PauseAllowed       ), Tiles.fonts.[Colors.Tin], (0, 6 ), "Disallow [P]ause");
     ((fun (o:GameSettings.Options) -> o.PauseAllowed |> not), Tiles.fonts.[Colors.Tin], (0, 6 ), "Allow [P]ause");
     ((fun (o:GameSettings.Options) -> true                 ), Tiles.fonts.[Colors.Gold], (0, 17), "Esc - Go Back")]

let drawOptionsScreen options =
    FrameBuffer.clear Colors.Onyx
    optionsScreenStrings
    |> List.iter (fun (cond,f,xy,s) -> if cond(options) then f |> FrameBuffer.renderString xy s else ())



