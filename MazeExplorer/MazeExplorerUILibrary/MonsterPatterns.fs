module MonsterPatterns

let Skeleton = 
    ["........";
     "..XXX...";
     "...X....";
     "..XXX...";
     ".X.X.X..";
     "..XXX...";
     "..X.X...";
     "........"]
    |> Pattern.patternFromStringListX

let Mummy = 
    ["........";
     "..XXX...";
     "..XXX...";
     ".XXXXX..";
     "..XXX...";
     "..XXX...";
     "..X.X...";
     "........"]
    |> Pattern.patternFromStringListX

let Zombie = 
    ["........";
     "...XX...";
     "...XX...";
     "..XXXX..";
     ".X.XX.X.";
     "...XX...";
     "..X..X..";
     "........"]
    |> Pattern.patternFromStringListX

let Ghoul = 
    ["........";
     "..XXXX..";
     ".X.XX.X.";
     ".X.XX.X.";
     "...XX...";
     "..X..X..";
     "..X..X..";
     "........"]
    |> Pattern.patternFromStringListX

let Golem = 
    ["........";
     "..XXX...";
     "..XXX...";
     ".XXXXX..";
     ".XXXXX..";
     "..XXX...";
     ".XX.XX..";
     "........"]
    |> Pattern.patternFromStringListX

let Wizard = 
    ["........";
     "...X....";
     "..XXX...";
     "...X....";
     "..XXX...";
     "...X....";
     "..X.X...";
     "........"]
    |> Pattern.patternFromStringListX

