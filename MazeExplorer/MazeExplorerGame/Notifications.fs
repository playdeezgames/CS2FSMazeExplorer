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

type GameEvent =
    | PlaySound of Sfx



