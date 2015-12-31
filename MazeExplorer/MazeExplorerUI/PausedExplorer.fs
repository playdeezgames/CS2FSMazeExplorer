module PausedExplorer

open Explorer
open State

type PausedExplorer<'direction,'state> = Explorer<'direction,'state> * System.DateTime

let pauseExplorer explorer =
    (explorer, System.DateTime.Now)

let unpauseExplorer pausedExplorer = 
    let explorer, pauseTime = pausedExplorer
    {explorer with State = {explorer.State with EndTime = System.DateTime.Now + (explorer.State.EndTime - pauseTime)}}



