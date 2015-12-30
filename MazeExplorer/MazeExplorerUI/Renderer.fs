module Renderer

open GameData

let redraw graphics =
    match gameState with
    | TitleScreen                              -> TitleScreenRenderer.drawTitleScreen()
    | HelpScreen _                             -> HelpScreenRenderer.drawHelpScreen()
    | OptionsScreen _                          -> GameSettings.options |> OptionsScreenRenderer.drawOptionsScreen
    | PlayScreen explorer                      -> explorer |> PlayScreenRenderer.drawGameScreen
    | GameOverScreen (explorer, explorerState) -> explorer |> PlayScreenRenderer.drawGameScreen
    | PauseScreen _                            -> PauseScreenRenderer.drawPauseScreen()

