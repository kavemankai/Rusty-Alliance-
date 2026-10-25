# QA report — 2026-10-25

## Observed results

| Check | Result |
|---|---|
| Godot 4.6.2 standard import / script execution | Passed |
| Deterministic mechanical/integration suite | 291 passed, 0 failed |
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

Rendered strategic, inventory, supplies, garrison, contract-board and deployment screenshots were inspected. They show actual runtime geometry and controls. Controls use 48-unit minimum button heights and scrolling panels. These observations do not establish hardware touch comfort or safe-area support.

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

This is not comprehensive coverage of the master contract. Buildings, full fog, formations, precise interrupt parity, independently targetable escort carts, levy equipment management, transport modes and several persistence/UX requirements remain incomplete. AI uses shared team knowledge and last-known positions, but is deliberately simple. LOS uses sampled cells; all geometric corner/elevation cases have not been proven. Logical 160×160 allocation is checked; scale frame time is not.

UI automation runs on desktop and uses pointer events plus selection methods. The first walkthrough covers item management, local supply deposit/load and capture. The second starts with one existing enemy group placed a sector from Ashford as a documented test fixture; all recruitment, stocking, company travel, clock advances, garrison deployment, combat, aid and save/load then use normal controls. The existing group advances through real strategic AI; no victory or payment is injected. A third quiet-road fixture removes hostile forces and then uses normal controls to accept an escort/patrol, travel through ordered stops, save/load mid-route, deliver freight and return for patrol payment. The second also accepts and earns a settlement defence posting. Company and garrison contacts now use actual placement, save/load and Begin combat controls before fighting. Company facing is changed through its free setup control. This is not physical Android touch evidence. Android interruption and disk-failure injection remain untested. Schema 1→2→3 migrations, ownership/canonical profiles and basic geometry validation are checked; arbitrary malformed-data coverage is not exhaustive.

The continuity suite verifies legal death/looting, retreat, save/re-entry and exact hostile identity/condition. The logistics/defence suite adds 66 checks for separate stores, local skills, conserved migration, garrison profiles and control/casualty consequences. It includes legal enemy attacks causing actual levy deaths, continued home defence after retreat, garrison-only legal-action victories, legacy undeployed reserves and deterministic incapacitation fixtures for capture/defeat edges. Existing rule coverage remains in the expanded 291-check suite. The contracts suite adds 44 checks for all six objective types, exact delivery and idempotency, ordered patrol return, saved road/combat progress, off-site target tracking, actual camp combat, garrison defence payments, ownership loss, deadline failure, withdrawal/defeat/disbanding freight loss, repeat posting cooldown and malformed objective data. A neutralized target remains pending while its actual battle awaits resolution.

Final acceptance: gates C/D pass for the delivered slice. Gate E is pending hardware validation and Gate F remains incomplete. Follow IMPLEMENTATION_PLAN.md before extending acceptance claims.

Phase 1 changes only deployment on the existing encounter template. Phase 2 sector-specific map layouts have not been implemented or claimed. Older schema-1/2 tactical fixtures and an old-shape schema-3 active save resume combat without placement or AP resets. A blocked-entry fixture remains unconfirmed, survives save/load and can withdraw.
