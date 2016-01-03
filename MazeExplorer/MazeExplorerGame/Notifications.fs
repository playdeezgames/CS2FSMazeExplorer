module Notifications

type Sfx =
    | AcquireLoot
    | AcquireHourglass
    | AcquireKey
    | AcquirePotion
    | AcquireShield
    | AcquireSword
    | TriggerTrap
    | UnlockDoor
    | Blocked
    | DrinkPotion
    | Amulet
    | Death
    | Exit
    | Fight
    | LoveInterest

type GameEvent =
    | PlaySound of Sfx



