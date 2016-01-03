module Audio

open GameData
open Notifications

let soundPlayers =
    [(AcquireLoot,      "Loot.wav"        );
     (AcquireHourglass, "Hourglass.wav"   );
     (AcquireKey,       "Key.wav"         );
     (AcquirePotion,    "Potion.wav"      );
     (AcquireShield,    "Shield.wav"      );
     (AcquireSword,     "Sword.wav"       );
     (UnlockDoor,       "Unlock.wav"      );
     (Blocked,          "Blocked.wav"     );
     (DrinkPotion,      "DrinkPotion.wav" );
     (Amulet,           "Amulet.wav"      );
     (Death,            "Death.wav"       );
     (Exit,             "Exit.wav"        );
     (Fight,            "Fight.wav"       );
     (LoveInterest,     "LoveInterest.wav");
     (TriggerTrap,      "Trap.wav"       )]
    |> Seq.map (fun (k,v) -> (k, new System.Media.SoundPlayer(v)))
    |> Map.ofSeq

let playSound sfx =
    if GameSettings.options.Sfx then
        soundPlayers.[sfx].Play()
    else
        ()