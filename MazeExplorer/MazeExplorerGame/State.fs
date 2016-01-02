﻿module State

open Location
open Constants

type ItemType = 
    | Treasure
    | Trap
    | Key
    | Sword
    | Shield
    | Hourglass
    | Potion
    | LoveInterest
    | Amulet
    | Exit

let itemMonsters =
    [(Treasure,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(None, 3);]);
    (Trap,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(None, 2);]);
    (Key,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(Some Monsters.Mummy, 1);(None, 2);]);
    (Sword,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(None, 5);]);
    (Shield,[(Some Monsters.Zombie, 3);(Some Monsters.Mummy, 2);(None,2)]);
    (Hourglass,[(Some Monsters.Zombie, 3);(Some Monsters.Mummy, 2);(Some Monsters.Ghoul, 1);]);
    (Potion,[(Some Monsters.Skeleton, 3);(Some Monsters.Zombie, 2);(None, 6);]);
    (Amulet,[(Some Monsters.Golem, 1)]);
    (Exit,[(None, 1)]);
    (LoveInterest,[(Some Monsters.Wizard, 1)])]
    |> Map.ofSeq
    |> Map.map (fun k v ->v |> Map.ofSeq)

type CounterType =
    | Loot
    | Wounds
    | Health
    | Keys
    | Potions
    | Attack
    | Defense
    | Amulet

type State = 
    {Visited: Set<Location>; 
    Items: Map<Location,ItemType>; 
    Monsters: Map<Location,Monsters.Instance>;
    Locks: Set<Location>;
    Visible: Set<Location>; 
    Counters : Map<CounterType,int>;
    EndTime: System.DateTime}

let getCounter counterType (state:State) =
    match state.Counters |> Map.tryFind counterType with
    | Some value -> value
    | None       -> 0

let setCounter counterType value (state:State) =
    {state with Counters= state.Counters |> Map.add counterType value}

let changeCounter counterType delta  (state:State)=
    state
    |> setCounter counterType ((state |> getCounter counterType) + delta)

let initializeCounters state =
    state
    |> setCounter Wounds InitialWounds
    |> setCounter Health InitialHealth
    |> setCounter Attack InitialAttack
    |> setCounter Potions InitialPotions


