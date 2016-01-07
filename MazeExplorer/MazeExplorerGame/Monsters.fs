module Monsters

type Type =
    | Skeleton
    | Zombie
    | Mummy
    | Ghoul
    | Golem
    | Wizard

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
    [(Skeleton, {Name="Skeleton"; Health=1; Attack=1; Defense=0; Score = 20; Abbr="Skel"});
    (Zombie, {Name="Zombie"; Health=2; Attack=1; Defense=0; Score = 40; Abbr="Zomb"});
    (Mummy, {Name="Mummy"; Health=3; Attack=2; Defense=1; Score = 180; Abbr="Mumm"});
    (Ghoul, {Name="Ghoul"; Health=3; Attack=2; Defense=2; Score = 240; Abbr="Ghul"});
    (Golem, {Name="Golem"; Health=4; Attack=3; Defense=3; Score = 480; Abbr="Golm"});
    (Wizard, {Name="Wizard"; Health=5; Attack=3; Defense=3; Score = 600; Abbr="Wizd"})]
    |> Map.ofSeq
