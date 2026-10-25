# The Broken Marches engineering rules

Godot 4.6.2 standard, GDScript, Compatibility renderer, Android landscape. Read BUILD_STATUS.md before continuing. User's production contract is preserved in PRODUCTION_CONTRACT.md.

- Implement original rules and content. JA2 is research only; never copy source or tables. See LEGAL_PROVENANCE.md.
- Campaign.s is authoritative. Tactical company units reference the same mercenary dictionaries. Rebind after loading JSON.
- Schema 3 inventories own unique item dictionaries; equipment references owned IDs. There are no duplicated profile loadout values. Use catalog accessors. Enemy profiles belong to group fighters, levy profiles to sector.levies. Rebind mercenaries, enemies and levies after loading.
- Food/medicine/tools belong to squad.supplies or sector.supplies. Never reintroduce a remote global pool. Split/merge must conserve quantities; transfers require stationary co-location and controlled depots. Tactical first aid uses the actor's own pack or home depot.
- Garrison strength is derived from capable uncaptured profiles, not a counter. Co-located squads and local levies share a tactical engagement. Levies remain home when mercenaries withdraw, and defeated packs stay at the battle sector.
- Base stockpile access requires Ashford; character transfers require co-location, and combat transfers require adjacency plus 3 AP. Preserve IDs when equipping, transferring, looting or repairing.
- Battlefields own layout/version/deployment_zones/enemy_spawns alongside tiles/ground. Preserve all metadata through field_state(); never regenerate a visited sector or attach new geometry to a legacy active save.
- Rules belong in sim/, presentation in ui/. Commands reject invalid actions before spending resources.
- New mechanics need deterministic behavioural checks. Run tests/run.gd and tests/ui_smoke.gd. An exit code alone is insufficient: reject SCRIPT ERROR and ERROR output.
- Movement preview and execution must use the same step_cost. Displayed accuracy uses hit_chance before condition/fatigue mutations.
- Preserve RNG state, ordered events, injuries, inventory and active encounters. Keep backups when saving.
- Use primitive geometry only. Do not add finished assets or spend time on visual polish.
- Do not call foundation complete while required contract systems or Android device verification remain outstanding.
- Keep changes recoverable with local commits. Never delete unrelated work, force push, spend money, expose credentials or publish commercially.
- Update source audit, test evidence, parity and continuation instructions when behaviour changes.

No parallel agents are required for this repository.
