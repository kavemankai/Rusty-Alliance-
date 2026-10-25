# QA report — 2026-10-25

## Observed results

| Check | Result |
|---|---|
| Godot 4.6.2 standard import / script execution | Passed |
| Deterministic mechanical/integration suite | 142 passed, 0 failed |
| Desktop rendered UI scenario | 0 failures; real buttons and selection callbacks, no battle-result injection |
| First legal-action contract battle | Victory in 3 simulation-driver rounds for seed 731; casualties are retained |
| Repeated campaign contract scenario | Returned to market, recruited replacements, resupplied, recovered, won second battle |
| Save/load | Strategic exact-state and tactical reference/RNG checks pass; backup fallback checked |
| Item ownership and transfers | Unique IDs, independent condition, backpack weight, equip/unequip, co-location and combat adjacency/AP checks |
| Retreat continuity | Dead enemies remain dead; survivor injury/ammo/reload/equipment/position, open door and ground loot persist through save/re-entry |
| Save migration | Actual schema-1 strategic/tactical/corpse fixtures upgrade and roundtrip as schema 2 |
| Concurrent contacts | Queueing, invalid-contact cleanup, multi-army tick processing and stale-route rejection |
| Extended clock | Thirty days, 30 wage entries, no duplicate hourly event |
| Android debug export | Successful, signed; package org.brokenmarches.foundation |
| APK inspection | min SDK 24, target 35; package architecture and signature checks |
| Physical Android / emulator | Not run: no adb device or installed emulator available |
| Remote CI | Configuration supplied; not dispatched or observed |

Rendered strategic and tactical screenshots were inspected. They show actual runtime geometry and controls. Both interfaces use fixed 48-unit minimum button heights and scrolling side panels. These observations do not establish hardware touch comfort or safe-area support.

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

This is not comprehensive coverage of the master contract. Buildings, full fog, advanced formations, precise interrupt parity, all job types, tactical garrisons and several inventory/persistence requirements remain incomplete. AI uses shared team knowledge and last-known positions, but is deliberately simple. LOS uses sampled cells; all geometric corner/elevation cases have not been proven. Scenario tests use fixed maps/seeds. Logical 160×160 allocation is checked; scale frame time is not.

UI automation runs on desktop and uses desktop pointer events plus control selection methods. It now exercises stockpile collection, transfer to a different fighter, equipping and restoring a carried weapon before the campaign walkthrough. It is not physical Android touch evidence. Application-pause save code exists, but Android interruption and disk-failure injection remain untested. Schema 1 migrates to schema 2; unsupported versions are rejected. Ownership/canonical profile and basic tactical geometry validation are checked, but arbitrary malformed-data coverage is not exhaustive.

The continuity tests include actual legal combat death/looting followed by a deterministic wounded-survivor fixture, withdrawal, save/reload and re-entry. They verify the surviving hostile roster by identity and exact health, bleeding, ammunition, reload state, condition and position. Actual previous-release fixture files test backward compatibility, including old corpse/loot duplication risk. Faction loss accounting is checked for duplicate casualty counts. Existing 87 checks remain covered by the expanded 142-check suite.

Final acceptance: gates C/D pass for the delivered slice. Gate E is pending hardware validation and Gate F remains incomplete. Follow IMPLEMENTATION_PLAN.md before extending acceptance claims.
