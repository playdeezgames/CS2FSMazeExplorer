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
    | Loot // 10 score, 500 bonus
    | Wounds
    | Health
    | Keys // 25 score
    | Potions //50 score
    | Attack 
    | Defense
    | Amulet //500 score 
    | Stairs //250 score
    // Monsters killed, 25 score, 2500 bonus - do I want this per monster type?
    // Sword acquired, 50 score, 200 bonus
    // Shields acquired, 100 score, 1000 bonus
    // Love interest acquired, 1000 score
    // Traps sprung, -25 score
    // Doors unlocked, 25 score
    // Hourglasses acquired, 50 score

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


