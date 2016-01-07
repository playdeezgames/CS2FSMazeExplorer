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
    | Loot // 10 score
    | Wounds
    | Health
    | Keys
    | Potions
    | Attack 
    | Defense
    | Amulet //500 score 
    | Stairs //250 score
    | KeysAcquired//25 score
    | PotionsAcquired //50 score
    | SwordsAcquired//50
    | ShieldsAcquired//100
    | TrapsSprung//-25
    | DoorsUnlocked//25
    | HourglassesAcquired//50

type State = 
    {Visited: Set<Location>; 
    Items: Map<Location,ItemType>; 
    Monsters: Map<Location,Monsters.Instance>;
    Kills: Map<Monsters.Type, int>;
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

let getKills monsterType state =
    match state.Kills |> Map.tryFind monsterType with
    | Some value -> value
    | None       -> 0
    
let incrementKills monsterType state =
    let newValue = (state |> getKills monsterType) + 1
    {state with Kills = state.Kills |> Map.add monsterType newValue}