module PauseScreenRenderer

let pauseScreenStrings =
    [(Tiles.fonts.[Colors.Garnet],(10,9),"***PAUSED***");
    (Tiles.fonts.[Colors.Gold],(8,17),"SPACE -  Unpause")]

let drawPauseScreen () =
    FrameBuffer.clear Colors.Carnelian
    pauseScreenStrings
    |> List.iter (fun (f,xy,s) -> f |> FrameBuffer.renderString xy s)
