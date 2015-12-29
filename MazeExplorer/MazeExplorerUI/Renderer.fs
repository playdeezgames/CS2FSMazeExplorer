module Renderer

let redraw graphics =
    match GameData.gameState with
    | GameData.TitleScreen                              -> graphics |> TitleScreenRenderer.redraw
    | GameData.HelpScreen _                             -> graphics |> HelpScreenRenderer.redraw
    | GameData.OptionsScreen _                          -> graphics |> OptionsScreenRenderer.redraw
    | GameData.PlayScreen explorer                      -> explorer |> PlayScreenRenderer.drawGameScreen
    | GameData.GameOverScreen (explorer, explorerState) -> explorer |> PlayScreenRenderer.drawGameScreen

