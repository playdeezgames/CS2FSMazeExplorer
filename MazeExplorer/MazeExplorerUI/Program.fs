open System.Windows.Forms
open System.Drawing
open System
open GameState

let createRefreshTimer (window:Form) =
    let timer = new Timer()
    timer.Interval <- 1000
    timer.Enabled <- true
    timer.Tick.AddHandler (fun _ _ -> match gameState with | PlayScreen _ -> window.Invalidate() | _ -> ())
    window

let gameIcon = new Icon(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("icon.ico"));

[<EntryPoint>]
[<STAThread>]
let main argv = 
    new Size(768, 432)
    |> GameWindow.create gameIcon "Maze Explorer" (createRefreshTimer) Renderer.redraw Input.keyDown
    |> Application.Run
    0