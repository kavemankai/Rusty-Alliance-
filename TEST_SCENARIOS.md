# Deterministic scenarios

Run `godot --headless --script tests/run.gd`. A structured report is written to test-results.json. Assertions test actual state changes; rules use original catalogue values. `tests/ui_smoke.gd` separately drives visible Control buttons and tactical selection paths under a rendering desktop.

| Requested scenario | Implemented fixture and expected result | Remaining scope |
|---|---|---|
| 1 Tactical movement | Exact cost 4 for two grass steps, exact AP deduction, stance surcharge, walls, door opening, occupied-door closure rejection, diagonal wall detour, hill ascent cost 5 | Full terrain catalogue, turning cost within movement, friendly pass-through policy |
| 2 Melee combat | Spear reach 2 accepted, sword reach 2 rejected; rear bonus; AP-funded shield/parry/dodge observed across 60 seeds; armour mitigates same-seed aggregate damage | Complete disengage pressure and engagement matrix |
| 3 Ranged combat | Aim increases accuracy; ammo consumed; unloaded shot rejected; bow/crossbow reload differences; cover penalty; 20-seed contact roll matches preview | Complete distance/elevation matrix, missile categories, javelin consumption |
| 4 Defence | Walls block LOS, windows pass it, doors alter geometry, levies defeat weaker strategic attackers, AI obeys occupancy/AP | Full defended-building battle and tactical levy deployment |
| 5 Contract | Hire → equip → accept → route → contact → legal battle → capture/payment; duplicate reward rejected; normal UI replay also passes | Additional job variants |
| 6 Logistics | Food consumption, starvation penalty, midnight wage charge, debt morale, medical recovery, training and repairs consume time/resources | Separate squad stores, transport modes |
| 7 Faction war | Existing groups move; bounded weaker attack loses to persistent levy defence | Broad rival war / reinforcement strategy |
| 8 Persistent campaign | First battle result → return to market → recruit/resupply/recover → second target and real battle → second contract paid | Larger long-lived campaigns and content |
| 9 Save/load | Tactical RNG/clock/injuries/loadout persisted; unit references rebound; exact strategic state roundtrip; malformed main recovers backup; missing/unsupported/incomplete saves rejected | Schema migration, arbitrary corrupted nested battle saves |
| 10 Extended simulation | Thirty days, exactly 30 midnight ledger wage entries, exact elapsed time, only one recurring hourly event remains | Full faction/encounter campaign soak with player decisions |

The extended clock fixture excludes active armies and employment to isolate event accounting. Combat defence tests sample fixed seeds and compare behaviour rather than claim probability calibration. The 160×160 assertion verifies lightweight logical capacity, not runtime performance at that size.
