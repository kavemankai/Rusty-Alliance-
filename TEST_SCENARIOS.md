# Deterministic scenarios

Run `godot --headless --script tests/run.gd`. A structured report is written to test-results.json. Assertions test actual state changes; rules use original catalogue values. `tests/ui_smoke.gd` separately drives visible Control buttons and tactical selection paths under a rendering desktop.

| Scenario | Current bounded evidence | Remaining acceptance |
|---|---|---|
| Movement | Shared preview/execution, obstacles/corners/elevation, stance, heap/reference equivalence and native Android paid movement | Complete terrain catalogue/geometry matrix |
| Melee | Reach, body/style choices, paid defence, disengagement, charge/bash/protection and real injuries | Full probability/balance and engagement calibration |
| Ranged | Owned typed ammo, bows/crossbows/throws, reload, cover/range/elevation and actual Android shot/reload | Complete geometric and probability matrix |
| Defence | Authored deployment, rooms/roofs/fortifications, combined squads/levies, real casualty/control changes | Multistorey geometry and richer tactical roles |
| Contract | All six objective types, generated road jobs, idempotent payment, desktop full victory loop, Android board/travel/combat controls | Exhaustive Android full victory/payment player flow |
| Logistics | Local packs/depots, transfers, care/repair/training, horse/cart ownership, forage and conservation | Broader economy/resupply balance |
| Faction war | Facility budgets, paid recruitment, reports, raids/withdrawal/patrol and roster clashes | Broad strategic balance and sophisticated manoeuvre |
| Persistent campaign | Multiple real battles plus six 45-day seeded checkpoints and deterministic replay | Unrestricted campaigns/player decisions |
| Save/load | Actual legacy fixtures, canonical profiles/items, malformed nested data, verified backups/process-kill checkpoints and Android Home/relaunch | Physical power loss, full-disk and OEM low-memory acceptance |
| Extended/scale | 270 seeded campaign days, isolated wage clock, desktop 32/80/160 profiles and synthetic Android 25,600-cell save/render | Real low-end phone thermals/battery/soak and full mandatory-rule coverage |

The extended clock fixture excludes active armies and employment to isolate event accounting. Combat defence tests sample fixed seeds and compare behaviour rather than claim probability calibration. The desktop and synthetic Android profiles are described in HARDENING_SCALE.md and ANDROID_QA.md; neither establishes physical-phone performance.

## Inventory and continuity expansion

tests/continuity_cases.gd adds 55 behavioural checks to the original 87, for 142 total. Coverage includes unique identity, independent durability, displaced backpack gear, carrying weight, equipped-transfer rejection, remote stockpile/squad rejection, adjacent 3-AP combat handover/equip, death and exact ground-item transfer, safe adjacent retreat, persistent enemy casualty/injury/ammunition/position, idempotent faction loss accounting, door and ground state, active enemy rebinding, blocked withdrawal, queued/multi-army contacts, obsolete travel callbacks and previous-release save migration. See tests/fixtures/README.md for fixture provenance. tests/ui_smoke.gd separately performs stockpile collection, character transfer and carried-item equip through visible controls before the campaign battle walkthrough.

## Logistics and defence expansion

tests/logistics_defence_cases.gd adds 66 checks, making 208 total. It covers split/merge and odd supply remainders, every transfer/access rejection, independent consumption, selected-squad purchasing, farm depots, burden, local caregivers/tools/medicine, combined squad/levy deployment and rebinding, garrison-only battles, home-bound retreat rules, actual enemy-caused levy death and equipment drops, continued defence/reserves, capture/control loss, upkeep/training/recruit cap, isolated unconscious care, lost packs and schema-2 fixtures. tests/ui_smoke.gd now also stocks a garrison, marches the company away, advances to an actual enemy strategic attack and completes the levy defence/save/load through normal controls.


## Save hardening and scale follow-up — 2026-10-26

Phases 7 and 8 add typed event/financial/assignment records, structural preflight before migration, verified temporary/backup commits, process-termination recovery coverage, large-map heap routing, cached selection redraws and six 45-day campaign/replay scenarios. See HARDENING_SCALE.md and the raw profile/extended reports for exact evidence and limitations. The physical Android gate (phase 9) and wider source/parity/release audit (phase 10) remain open. No additional JA2 source was copied or newly audited in this follow-up.
