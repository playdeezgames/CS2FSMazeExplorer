module ExplorerPatterns

let ExplorerN =
    ["........";
     "...X....";
     "..XXX...";
     ".X.X.X..";
     "...X....";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX

let ExplorerE =
    ["........";
     "...X....";
     "....X...";
     ".XXXXX..";
     "....X...";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX

let ExplorerS =
    ["........";
     "...X....";
     "...X....";
     ".X.X.X..";
     "..XXX...";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX

let ExplorerW =
    ["........";
     "...X....";
     "..X.....";
     ".XXXXX..";
     "..X.....";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX


let Treasure =
    ["........";
     ".XXXXX..";
     "...X....";
     "...X....";
     "...X....";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX

let Key =
    ["........";
     "..XXX...";
     "..X.X...";
     "...X....";
     "..XX....";
     "...X....";
     "..XX....";
     "........"]
    |> Pattern.patternFromStringListX

    
let Sword =
    ["........";
     "...X....";
     "...X....";
     "...X....";
     "..XXX...";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX


let Shield =
    ["........";
     ".XXXXX..";
     ".XXXXX..";
     ".XXXXX..";
     "..XXX...";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX

let Hourglass =
    ["........";
     ".XXXXX..";
     "..XXX...";
     "...X....";
     "..XXX...";
     ".XXXXX..";
     "........";
     "........"]
    |> Pattern.patternFromStringListX

let Potion =
    ["........";
     "...XX...";
     "...XX...";
     "..XXXX..";
     ".XXXXXX.";
     ".XXXXXX.";
     "..XXXX..";
     "........"]
    |> Pattern.patternFromStringListX

let LoveInterest =
    ["........";
     ".XX.XX..";
     ".XXXXX..";
     ".XXXXX..";
     "..XXX...";
     "...X....";
     "........";
     "........"]
    |> Pattern.patternFromStringListX

let Amulet =
    ["........";
     "..XXXX..";
     ".X....X.";
     ".X....X.";
     ".X.XX.X.";
     "..XXXX..";
     "...XX...";
     "........"]
    |> Pattern.patternFromStringListX

let Exit =
    ["........";
     ".....XX.";
     ".....XX.";
     "...XXXX.";
     "...XXXX.";
     ".XXXXXX.";
     ".XXXXXX.";
     "........"]
    |> Pattern.patternFromStringListX
