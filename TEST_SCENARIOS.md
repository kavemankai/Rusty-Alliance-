# Deterministic scenarios

Run `godot --headless --script tests/run.gd`. A structured report is written to test-results.json. Assertions test actual state changes; rules use original catalogue values. `tests/ui_smoke.gd` separately drives visible Control buttons and tactical selection paths under a rendering desktop.

| Requested scenario | Implemented fixture and expected result | Remaining scope |
|---|---|---|
| 1 Tactical movement | Exact cost 4 for two grass steps, exact AP deduction, stance surcharge, walls, door opening, occupied-door closure rejection, diagonal wall detour, hill ascent cost 5 | Full terrain catalogue, turning cost within movement, friendly pass-through policy |
| 2 Melee combat | Spear reach 2 accepted, sword reach 2 rejected; rear bonus; AP-funded shield/parry/dodge observed across 60 seeds; armour mitigates same-seed aggregate damage | Complete disengage pressure and engagement matrix |
| 3 Ranged combat | Aim increases accuracy; ammo consumed; unloaded shot rejected; bow/crossbow reload differences; cover penalty; 20-seed contact roll matches preview | Complete distance/elevation matrix, missile categories, javelin consumption |
| 4 Defence | Walls/doors/LOS; real persistent levies, combined friendly squads, garrison-only attack, legal combat casualties, ownership loss and continued defence after company withdrawal; UI walkthrough | Rich building/fortification roles and deliberate deployment |
| 5 Contract | Hire → equip → accept → route → contact → legal battle → capture/payment; duplicate reward rejected; normal UI replay also passes | Additional job variants |
| 6 Logistics | Separate squad/depot stores, conservative split/merge/transfers, remote/moving refusal, local medical skill and resources, local farm production, weight, shortages, wages/upkeep, recovery/training/repair | Transport modes, deeper logistics balance and resupply AI |
| 7 Faction war | Existing groups move; bounded weaker attack loses to persistent levy defence | Broad rival war / reinforcement strategy |
| 8 Persistent campaign | First battle result → return to market → recruit/resupply/recover → second target and real battle → second contract paid | Larger long-lived campaigns and content |
| 9 Save/load | Tactical RNG/clock/injuries/loadout; friendly/enemy/levy rebinding; exact roundtrip; backup; actual schema-1/2 fixtures migrate to schema 3; supply totals/old garrisons preserved; duplicate membership/ownership rejected | Physical Android / power-loss / actual full-disk hardware cases |
| 10 Extended simulation | Thirty days, exactly 30 midnight ledger wage entries, exact elapsed time, only one recurring hourly event remains | Full faction/encounter campaign soak with player decisions |

The extended clock fixture excludes active armies and employment to isolate event accounting. Combat defence tests sample fixed seeds and compare behaviour rather than claim probability calibration. The 160×160 assertion verifies lightweight logical capacity, not runtime performance at that size.

## Inventory and continuity expansion

tests/continuity_cases.gd adds 55 behavioural checks to the original 87, for 142 total. Coverage includes unique identity, independent durability, displaced backpack gear, carrying weight, equipped-transfer rejection, remote stockpile/squad rejection, adjacent 3-AP combat handover/equip, death and exact ground-item transfer, safe adjacent retreat, persistent enemy casualty/injury/ammunition/position, idempotent faction loss accounting, door and ground state, active enemy rebinding, blocked withdrawal, queued/multi-army contacts, obsolete travel callbacks and previous-release save migration. See tests/fixtures/README.md for fixture provenance. tests/ui_smoke.gd separately performs stockpile collection, character transfer and carried-item equip through visible controls before the campaign battle walkthrough.

## Logistics and defence expansion

tests/logistics_defence_cases.gd adds 66 checks, making 208 total. It covers split/merge and odd supply remainders, every transfer/access rejection, independent consumption, selected-squad purchasing, farm depots, burden, local caregivers/tools/medicine, combined squad/levy deployment and rebinding, garrison-only battles, home-bound retreat rules, actual enemy-caused levy death and equipment drops, continued defence/reserves, capture/control loss, upkeep/training/recruit cap, isolated unconscious care, lost packs and schema-2 fixtures. tests/ui_smoke.gd now also stocks a garrison, marches the company away, advances to an actual enemy strategic attack and completes the levy defence/save/load through normal controls.


## Save hardening and scale follow-up — 2026-10-26

Phases 7 and 8 add typed event/financial/assignment records, structural preflight before migration, verified temporary/backup commits, process-termination recovery coverage, large-map heap routing, cached selection redraws and six 45-day campaign/replay scenarios. See HARDENING_SCALE.md and the raw profile/extended reports for exact evidence and limitations. The physical Android gate (phase 9) and wider source/parity/release audit (phase 10) remain open. No additional JA2 source was copied or newly audited in this follow-up.
