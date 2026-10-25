# QA report — 2026-10-26

## Observed results

| Check | Result |
|---|---|
| Godot 4.6.2 standard import / script execution | Passed |
| Deterministic mechanical/integration suite | 577 passed, 0 failed |
| Extended campaigns and route equivalence | 796 passed, 0 failed; six seeds, 45 days each |
| Visibility/AI | 28 new checks: independent fog, remembered unseen changes, legacy/cache persistence, unknown-obstacle routing, flank/elevation/window cover, legal sheltered AI steps, hidden-position-independent pursuit, searched/expired memories and wounded ally support |
| Phase 3 exploration | 38 new checks: scouting entry, invalid-action guards, movement/patrol pulses, either-side and immediate detection, AP/position continuity, quiet exit, bleeding/death, pending/blocked orders, garrison/combined profiles, malformed records and legacy continuation |
| Phase 2 maps | 74 new checks: four geometry signatures, spawn connectivity, formation save/load, legal company and garrison victories on each map, real door actions, retreat/re-entry loot/terrain, reinforcement collisions, metadata validation and legacy retention |
| Phase 1 deployment | 39 new checks: placement/facing, AP/RNG/clock freeze, illegal actions, canonical saved formations, combined squads/full garrison, no-space recovery and legacy combat continuation |
| Desktop rendered UI scenario | 0 failures; real buttons and selection callbacks, no battle-result injection |
| First legal-action contract battle | Victory in 3 simulation-driver rounds for seed 731; casualties are retained |
| Repeated campaign contract scenario | Returned to market, recruited replacements, resupplied, recovered, won second battle |
| Save/load | Strategic exact-state and tactical reference/RNG checks pass; backup fallback checked |
| Item ownership and transfers | Unique IDs, independent condition, backpack weight, equip/unequip, co-location and combat adjacency/AP checks |
| Retreat continuity | Dead enemies remain dead; survivor injury/ammo/reload/equipment/position, open door and ground loot persist through save/re-entry |
| Save migration | Actual schema-1 and schema-2 strategic/tactical fixtures upgrade and roundtrip as schema 3; old counters become trained profiles, supply totals are conserved |
| Squad logistics | Separate stores, co-location/stationary transfers, split/merge and odd-remainder conservation, local farm output, travel burden and local medical/repair resources |
| Tactical levies and combined squads | Same-sector squads deploy together; levy-only defence wins through legal actions; wounds/death/capture, ownership loss, upkeep/training and continued defence are verified |
| Concurrent contacts | Queueing, invalid-contact cleanup, multi-army tick processing and stale-route rejection |
| Extended clock | Thirty days, 30 wage entries, no duplicate hourly event |
| Android debug export | Successful, signed; package org.brokenmarches.foundation |
| APK inspection | min SDK 24, target 35; package architecture and signature checks |
| Physical Android / emulator | Not run: no adb device or installed emulator available |
| Remote CI | Configuration supplied; not dispatched or observed |

Rendered strategic, inventory, supplies, garrison, contract-board, deployment and four authored-map screenshots were inspected. They show actual runtime geometry and controls. Controls use 48-unit minimum button heights and scrolling panels. These observations do not establish hardware touch comfort or safe-area support.

## Repairs verified during development

- Corrected JSON float/integer arithmetic in rendering and normalized loaded integer data.
- Rebound loaded tactical units to campaign character dictionaries.
- Removed campaign↔battle strong-reference cycle; final runs have no leaked-resource warnings.
- Moved hit-chance evaluation ahead of fatigue/durability mutations; a 20-seed test confirms preview contact rolls.
- Prevented auto-loot from duplicating weapons already taken from the ground.
- Preserved valid save backups when the current file is corrupt.
- Added actual guard/scout/garrison assignment effects; all listed character base attributes now influence a rule.
- Added scheduled employment/deadline events alongside chronological hourly progression.
- Distinguished fixture setup failures from implementation failures when garrison tests unintentionally triggered a player encounter.

## Limits and open risks

This is not comprehensive coverage of the master contract. Multistorey geometry, precise interrupt parity, physical Android persistence/UX and hardware acceptance remain incomplete. The requested single-level roof/lighting/formation, protected-escort, levy-equipment and strategic-transport features are now covered by the production pass. AI uses shared team knowledge and last-known positions, but is deliberately simple. LOS uses sampled cells; all geometric corner/elevation cases have not been proven. Desktop 160×160 routing, visibility, redraw and frame samples are measured in HARDENING_SCALE.md; they do not prove Android performance.

UI automation runs on desktop and uses pointer events plus selection methods. The first walkthrough covers item management, local supply deposit/load and capture. The second starts with one existing enemy group placed a sector from Ashford as a documented test fixture; all recruitment, stocking, company travel, clock advances, garrison deployment, combat, aid and save/load then use normal controls. The existing group advances through real strategic AI; no victory or payment is injected. A third quiet-road fixture removes hostile forces and then uses normal controls to accept an escort/patrol, travel through ordered stops, save/load mid-route, deliver freight and return for patrol payment. The second also accepts and earns a settlement defence posting. Company and garrison contacts now use actual placement, save/load and Begin combat controls before fighting. Company facing is changed through its free setup control. This is not physical Android touch evidence. Application-level write/backup interruption and actual process termination are now tested; Android OS/power-loss and real full-disk hardware acceptance remain untested. Schema 1→2→3 migrations, ownership/canonical profiles and basic geometry validation are checked; arbitrary malformed-data coverage is not exhaustive.

The continuity suite verifies legal death/looting, retreat, save/re-entry and exact hostile identity/condition. The logistics/defence suite adds 66 checks for separate stores, local skills, conserved migration, garrison profiles and control/casualty consequences. It includes legal enemy attacks causing actual levy deaths, continued home defence after retreat, garrison-only legal-action victories, legacy undeployed reserves and deterministic incapacitation fixtures for capture/defeat edges. Existing rule coverage remains in the expanded mechanical suite. The contracts suite adds 44 checks for all six objective types, exact delivery and idempotency, ordered patrol return, saved road/combat progress, off-site target tracking, actual camp combat, garrison defence payments, ownership loss, deadline failure, withdrawal/defeat/disbanding freight loss, repeat posting cooldown and malformed objective data. A neutralized target remains pending while its actual battle awaits resolution.

Final acceptance: gates C/D pass for the delivered slice. Gate E is pending hardware validation and Gate F remains incomplete. Follow IMPLEMENTATION_PLAN.md before extending acceptance claims.

Phase 1 changes only deployment on the existing encounter template. Phase 2 adds four facility archetypes and wilderness terrain fallbacks. A controlled three-fighter/two-hostile fixture and a separate three-levy defence each win through legal simulation actions on every facility archetype. Door persistence uses a documented adjacency fixture followed by the actual door action; unique loot is placed as a controlled ground-item fixture and then persists through real retreat, saving, travel and re-entry. Reinforcement tests retain existing hostile positions while allocating free authored spawns. Older schema-1/2 tactical fixtures and an old-shape schema-3 active save resume combat without placement or AP resets. A blocked-entry fixture remains unconfirmed, survives save/load and can withdraw.

The rendered UI suite additionally opens each facility archetype as a controlled contact fixture, selects a legal tile through the 3D picker, confirms placement, saves/loads the formation, begins combat and executes a paid movement through normal controls. These gallery fixtures do not inject wins. Existing normal-control battles continue on farm and settlement layouts. Android hardware evidence remains unavailable.

Phase 3 UI evidence uses a documented open, low-perception fixture to isolate the scouting controls. Normal Scout before contact, Wait / scout, movement, Save/Load and a longer movement order cause an actual sight-triggered interruption and reveal the normal End turn controls. A separate LOS-barrier fixture executes three real combat rounds and uses Resume exploration without changing AP. Screenshots show actual exploration/contact states. This verifies command-based exploration; continuous real-time operation and peaceful-sector tactical entry are not implemented or claimed.

Visibility/AI rule fixtures use controlled perception, positions and low cover to isolate information boundaries. Two otherwise identical campaigns move a still-hidden mercenary to different coordinates; the enemy takes the same steps toward the same remembered location without consuming attack RNG. The camp assault contract fixture now hires Ada before approaching; under the stronger AI, a two-fighter fixture could lose the real battle. The legal-action test suite retains real battle outcomes rather than injecting victory.

Rendered fog evidence places a unique ground item and rock outside company sight, checks that their corresponding render nodes do not exist, saves/loads, then scouts toward them through normal controls and checks that actual observation creates their geometry. Remembered terrain uses cached snapshots; this is not a lighting model. No large-map FPS or Android hardware claim is made.

Production pass: 91 additional mechanical/integration checks bring the suite to 522. The melee cases cover paid style/body strikes, actual localized injury effects and treatment, safe disengagement, defence selection, broken shields, carryover caps/first activation, ammunition compatibility, thrown-item ownership, charge, bash and paid shield interception. Production cases cover peaceful entry/build/save/leave, timed movement and pause-on-load, approaches/rooms/variants/night light, local levy equipment, prisoner transactions and real rescue, transport conservation/forage, generated risk-priced work, protected cart/driver destruction and repair, faction income/upkeep/recruit budgets, intelligence expiry, army-clash casualties/loot, patrol return legs, local communications, formations and rally limits.

The normal-control UI suite additionally exercises peaceful timed movement/building, transport, levy mail equipment, new postings, prisoner ransom/enlistment, paid melee choices/disengagement, protected cart movement, and the final charge/bash/ally-protection sequence with combat save/load. Fixtures arrange adjacency or captivity where needed; they do not inject contract payments or victories. Prepared camp fixtures now use four fighters or four levies after the injury/carryover changes. AI ally medical support uses actual local medicine and AP. These results do not establish hardware Android touch, interruption reliability or large-map performance.


## Save hardening and scale follow-up — 2026-10-26

Phases 7 and 8 add typed event/financial/assignment records, structural preflight before migration, verified temporary/backup commits, process-termination recovery coverage, large-map heap routing, cached selection redraws and six 45-day campaign/replay scenarios. See HARDENING_SCALE.md and the raw profile/extended reports for exact evidence and limitations. The physical Android gate (phase 9) and wider source/parity/release audit (phase 10) remain open. No additional JA2 source was copied or newly audited in this follow-up.


Current delivery: 0.10.0-hardening-scale (versionCode 10). Final evidence: 577 mechanical checks, 796 extended checks, each with 0 failures; rendered UI 0 failures; APK export and v2/v3 signature verification pass. Versioned packages retain the previous delivered APK. See HARDENING_SCALE.md.
