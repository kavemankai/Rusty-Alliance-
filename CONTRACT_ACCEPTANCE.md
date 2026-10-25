# Contract acceptance audit — 2026-10-26

This is a traceable acceptance inventory, not a claim that every bullet of the production contract has passed. The contract mentions Priority 0/1 without assigning a complete per-feature priority list. Mandatory wording is retained; gaps are not made optional to close a phase. Codes: verified means covered within the bounded implementation; partial means some requested behaviour/coverage remains; external means environment or independent review is required.

| Contract area | Evidence / implementation | Acceptance limit |
|---|---|---|
| 3-4 Platform and primitive scope | Standard Godot 4.6.2 Compatibility, landscape debug APK, primitive geometry | Android measurements depend on recorded emulator/device evidence; no phone thermal claim |
| 5-6 Source study / independence | Expanded SOURCE_AUDIT.md, original implementation mapping, release-content audit and engine notices | Technical source study is covered; legal clean-room/commercial clearance is not certified |
| 9-10 Central loop / authority | Canonical Campaign.s and profile/item ownership; normal-control UI contract loop | Broader unrestricted player decision space is not exhaustively tested |
| 11-13 Strategic map / events | 256 sectors, weighted routes/contact, stable event queue, time controls | Five strategic terrain categories plus tactical archetypes; not every listed terrain has its own behaviour |
| 14-16 Profiles / hiring / jobs / squads | Distinct stats, expiry, original six job types, squad split/merge/leadership | Finite authored roster and original contract abstractions; broader personality/relationship simulation is limited |
| 17-20 Logistics / economy / factions / levies | Local supplies/depot conservation, facilities, budgets, actual troop rosters, strategic transport, defended levies | Resupply AI and economy balance remain bounded; no broad diplomacy system |
| 21-23 Tactical map / camera / movement | Logical 160x160 support, authored 18x14 encounters, orthographic camera, eight-neighbour paid paths | One-level room geometry; no multistorey tactical movement; terrain catalogue is bounded |
| 24-25 AP / turns | Ability/condition AP, activation, carryover, team turns, exploration/contact | Original guard reactions replace JA2 initiative/interrupt contests |
| 26-29 Combat / armour / injuries / morale | Paid styles/body targets, reach, typed missiles, shield/parry/evade, localized injuries, fatigue/morale and retreat | Original probability/balance values; exhaustive engagement and probability calibration not established |
| 30-32 LOS / cover / AI | Current sight vs remembered terrain/opponents, sampled LOS, directional cover, bounded personal memory/sharing/support/formations | Not voxel/body LOS or multistorey occlusion; complete geometric proof and sophisticated manoeuvre AI remain open |
| 33-35 Inventory / assignments / integration | Unique item ownership, local resource/time use, legal multi-battle progression and persistence | No claim of source inventory/medical numerical parity |
| 36-37 Touch and mobile UI | Native board gestures, controls/scroll/modal flows, Android QA report | Emulator functional checks can pass while phone safe areas, physical gestures, battery/thermals and accessibility remain unverified |
| 38 Save interruption | Versioned detached validation, temporary/backup verification, actual process kill checkpoints | Physical power loss, storage exhaustion and OEM low-memory termination require hardware acceptance |
| 39 Scale | Recorded 32/80/160 desktop profiles and Android QA observations | Largest-map routes still pause input; no claim of low-end 60 FPS, sustained thermals or every map fully built with structures |
| 40-41 Test framework/scenarios | Mechanical, UI, randomized route and six 45-day campaign reports | Not all possible terrain/combat/strategy combinations; reserve-funded extended fixtures are not balance proof |
| 42 Developer tools | Text entity/event/AI/faction inspector, route/grid/preview and automated scenario scripts | Mandatory gap: complete interactive reachable/LOS/cover/occupancy overlays and in-game predefined scenario launcher |
| 43 Build pipeline | Local checked build, Android export/signature/package/content checks; proposed CI workflow | Remote CI has not been observed running; production signing/publication not performed |
| 45-51 Full foundation/release | Bounded playable slice and versioned debug delivery | Gate F remains open while mandatory gaps above and external acceptance remain; no commercial release clearance |

Phase 10 closes the focused technical source/mapping/content audit, not every remaining game feature or external release gate. Continue from the explicit gaps rather than treating audit completion as foundation completion.
