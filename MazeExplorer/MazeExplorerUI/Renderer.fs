module Renderer

open GameData

let redraw graphics =
    match GameData.gameState with
    | TitleScreen                              -> TitleScreenRenderer.drawTitleScreen()
    | HelpScreen _                             -> HelpScreenRenderer.drawHelpScreen()
    | OptionsScreen _                          -> OptionsScreenRenderer.drawOptionsScreen()
    | PlayScreen explorer                      -> explorer |> PlayScreenRenderer.drawGameScreen
    | GameOverScreen (explorer, explorerState) -> explorer |> PlayScreenRenderer.drawGameScreen

