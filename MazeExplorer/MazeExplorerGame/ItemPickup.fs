module ItemPickup

open State
open Notifications
open Constants

let pickupItem next state =
    {state with Items = next |> state.Items.Remove}

let pickupTreasure eventHandler next state =
    PlaySound AcquireLoot
    |> eventHandler
    state
    |> changeCounter Loot 1

let pickupTrap eventHandler next state =
    PlaySound TriggerTrap
    |> eventHandler
    state
    |> changeCounter Wounds 1

let pickupKey eventHandler next state =
    PlaySound AcquireKey
    |> eventHandler
    state
    |> changeCounter Keys 1

let pickupSword eventHandler next state =
    PlaySound AcquireSword
    |> eventHandler
    state
    |> changeCounter Attack 1

let pickupShield eventHandler next state =
    PlaySound AcquireShield
    |> eventHandler
    state
    |> changeCounter Defense 1

let pickupPotion eventHandler next state =
    PlaySound AcquirePotion
    |> eventHandler
    state
    |> changeCounter Potions 1

let pickupHourglass eventHandler next state =
    PlaySound AcquireHourglass
    |> eventHandler
    {state with EndTime = TimeBonusPerHourglass |> state.EndTime.AddSeconds}

let pickupLoveInterest eventHandler next state =
    //TODO - needs a sound!
    state
    |> changeCounter Health (state |> getCounter Health)



