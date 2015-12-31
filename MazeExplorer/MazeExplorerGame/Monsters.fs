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
    Defense: int}

type Instance =
    {Type: Type; Damage: int;}

let descriptors =
    [(Skeleton, {Name="Skeleton"; Health=2; Attack=1; Defense=0});
    (Zombie, {Name="Zombie"; Health=3; Attack=2; Defense=0});
    (Mummy, {Name="Mummy"; Health=4; Attack=3; Defense=1});
    (Ghoul, {Name="Ghoul"; Health=5; Attack=4; Defense=2});
    (Golem, {Name="Golem"; Health=6; Attack=5; Defense=3});
    (Wizard, {Name="Wizard"; Health=7; Attack=4; Defense=3})]
    |> Map.ofSeq
