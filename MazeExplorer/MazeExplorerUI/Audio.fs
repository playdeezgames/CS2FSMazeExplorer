module Audio

let soundPlayers =
    [(GameData.AcquireLoot,"Loot.wav");
    (GameData.AcquireHourglass,"Hourglass.wav");
    (GameData.AcquireKey,"Key.wav");
    (GameData.AcquirePotion,"Potion.wav");
    (GameData.AcquireShield,"Shield.wav");
    (GameData.AcquireSword,"Sword.wav");
    (GameData.UnlockDoor,"Unlock.wav");
    (GameData.TriggerTrap,"Trap.wav")]
    |> Seq.map (fun (k,v) -> (k, new System.Media.SoundPlayer(v)))
    |> Map.ofSeq

let playSound sfx =
    soundPlayers.[sfx].Play()