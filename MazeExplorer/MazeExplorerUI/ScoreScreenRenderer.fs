module ScoreScreenRenderer

open PausedExplorer
open State

let scoreScreenStrings =
    [(Colors.Onyx,(0,0),fun _->"Final Score");
     (Colors.Onyx,(0,2),fun state->state |> getCounter Loot |> (*) 10 |> sprintf "Loot %4i")
     (Colors.Onyx,(0,17),fun _->"Esc - Main Menu")]

let drawScoreScreen (state: State) =
    FrameBuffer.clear Colors.Silver
    scoreScreenStrings
    |> List.iter (fun (c,xy,s) -> Tiles.fonts.[c] |> FrameBuffer.renderString xy (state |> s))
