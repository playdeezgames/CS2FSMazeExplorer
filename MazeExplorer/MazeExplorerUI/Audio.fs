module Audio

open GameData

let soundPlayers =
    [(AcquireLoot,      "Loot.wav"     );
     (AcquireHourglass, "Hourglass.wav");
     (AcquireKey,       "Key.wav"      );
     (AcquirePotion,    "Potion.wav"   );
     (AcquireShield,    "Shield.wav"   );
     (AcquireSword,     "Sword.wav"    );
     (UnlockDoor,       "Unlock.wav"   );
     (TriggerTrap,      "Trap.wav"     )]
    |> Seq.map (fun (k,v) -> (k, new System.Media.SoundPlayer(v)))
    |> Map.ofSeq

let playSound sfx =
    if GameSettings.options.Sfx then
        soundPlayers.[sfx].Play()
    else
        ()