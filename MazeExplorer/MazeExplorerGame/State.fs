module State

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


