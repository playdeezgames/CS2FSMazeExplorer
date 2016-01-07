module Monsters

type Type =
    | Skeleton//5 pts = 10 * (H) * (A + D) / 2
    | Zombie//10 pts
    | Mummy//45 pts
    | Ghoul//60 pts
    | Golem//120 pts
    | Wizard//150 pts

type Descriptor = 
    {Name: string;
    Health: int;
    Attack: int;
    Defense: int;
    Score: int;
    Abbr: string}

type Instance =
    {Type: Type; Damage: int}

let descriptors =
    [(Skeleton, {Name="Skeleton"; Health=1; Attack=1; Defense=0; Score = 5; Abbr="Skel"});
    (Zombie, {Name="Zombie"; Health=2; Attack=1; Defense=0; Score = 10; Abbr="Zomb"});
    (Mummy, {Name="Mummy"; Health=3; Attack=2; Defense=1; Score = 45; Abbr="Mumm"});
    (Ghoul, {Name="Ghoul"; Health=3; Attack=2; Defense=2; Score = 60; Abbr="Ghul"});
    (Golem, {Name="Golem"; Health=4; Attack=3; Defense=3; Score = 120; Abbr="Golm"});
    (Wizard, {Name="Wizard"; Health=5; Attack=3; Defense=3; Score = 150; Abbr="Wizd"})]
    |> Map.ofSeq
