module Renderer

open GameData
open GameState

let redraw graphics =
    match gameState with
    | TitleScreen                              -> TitleScreenRenderer.drawTitleScreen()
    | HelpScreen _                             -> HelpScreenRenderer.drawHelpScreen()
    | OptionsScreen _                          -> GameSettings.options |> OptionsScreenRenderer.drawOptionsScreen
    | PlayScreen explorer                      -> explorer |> PlayScreenRenderer.drawGameScreen
    | PauseScreen _                            -> PauseScreenRenderer.drawPauseScreen()
    | ScoreScreen state                        -> state |> ScoreScreenRenderer.drawScoreScreen

