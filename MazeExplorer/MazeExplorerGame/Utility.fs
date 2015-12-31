module Utility

open Location

let random = new System.Random()

let picker (choices:seq<'t>) =
    let pick = choices |> Seq.length |> random.Next
    choices |> Seq.item pick

let pickMultiple count (choices:seq<'t>) :seq<'t> =
    choices
    |> Seq.sortBy (fun e->random.Next())
    |> Seq.truncate count
