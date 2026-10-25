# Continuation plan

The production contract is larger than the delivered slice. Preserve working integration while expanding it; do not mistake present tests for full acceptance coverage.

## Verified slice

- Godot 4.6.2 project, original simulation code and original world fixtures.
- Campaign state, deterministic RNG, ordered clock, commands, backup saves and active-battle rebinding.
- Real recruitment, purchases/equipment, squads, route travel, supplies, contracts, battle resolution, ownership, income, wages and assignments.
- Turn-based tactical pathfinding/AP, facing, melee reach, missile reload/ammunition, armour/defence, wounds/bleeding, morale/fatigue, perception and bounded AI.
- Primitive orthographic 3D, Control interfaces and normal-control end-to-end regression.
- Signed debug APK and repeatable local build script. Remote workflow supplied, not run.
- Schema 2: unique owned item instances, backpack/equipment operations, co-located transfers, per-item durability and backward migration using actual schema-1 save fixtures.
- Persistent enemy rosters, local door/terrain/ground state, adjacent safe retreat, queued contacts and stale-arrival rejection.
- Schema 3: squad packs and sector depots, conservation through split/merge/transfers, local treatment/repair, farm output and provision weight, with schema-1/2 migration.
- Persistent tactical levy profiles, combined friendly squads, garrison-only defence, upkeep/training, casualties/control loss and continued defence after company withdrawal.

## Work areas and acceptance gates

The numbered work areas below are not the user-facing phase sequence. Current phase status: 7 save hardening and 8 desktop scale/extended verification are implemented; 9 physical Android acceptance and 10 wider source/parity/release audit remain open.

1. **Android interaction/device gate.** Install supplied APK on mainstream hardware. Test touch select/confirm/cancel, scroll, two-finger pan/zoom, cutouts, pause/resume, OS interruption and low-memory behaviour. Measure frame pacing and input latency; record hardware and results. Device QA is currently an external blocker.
2. **State model hardening — core ownership/logistics complete.** Item identities, condition/transfers, squad/sector supply stores and schema-1→2→3 migrations are implemented and verified. Conservation, local access, canonical references and basic terrain validation are in place. Typed assignment/financial/event records, structural preflight, malformed-data tests and application/process-interruption injection are now implemented; see HARDENING_SCALE.md.
3. **Strategic battle continuity — requested company/prisoner scope implemented.** Local levy equipment, release/ransom/enlistment, victory-triggered rescue, owned strategic transport and paid fortifications are integrated. Army clashes preserve individual casualties and actual gear. See REQUEST_PROGRESS.md for precise boundaries.
4. **Job breadth — requested escort scope implemented.** Escort contracts own persistent cart/driver profiles that deploy into combat. Movement needs a nearby living driver; loss or withdrawal fails the job. Cart repair consumes tools/AP. Daily procedural deliveries and patrols price route length and known risk.
5. **Tactical depth — requested melee/world pass implemented.** Deliberate disengagement; styles/body targets/defensive choices; localized injuries and treatment; shield wear; typed ammunition; actual thrown gear; draw costs and four-AP carryover are implemented. Peaceful entry/leave, timed exploration, roofed one-level room footprints/cutaways, more facility variants, selectable edges and paid construction are integrated. The final combat pass adds charges, shield bashes, directional adjacent-ally interception and support actions. More storeys, mounted tactical combat and richer animation are expansion work, not supplied here.
6. **AI depth — requested scope implemented.** Formations use actual movement/AP, AI can raise shields/treat bleeding and support nearby injured allies, individual sightings share within six tiles, sounds have recency/range priority, rally supplements panic retreat, and night/torch visibility plus oriented construction cover affect rules. Strategic factions earn/spend resources, recruit at staffed bases, react to expiring nearby reports, patrol between objectives and resolve real roster casualties when armies clash. Further sophistication remains possible; no exact JA2 parity or unrestricted grand-strategy intelligence is claimed.
7. **Scale and tests.** Desktop 32/80/160 map profiles, large-map heap routing and six 45-day campaigns are implemented. Full mandatory-rule parity and physical Android performance remain outside these bounded checks. Add hardware Android smoke CI when available.
8. **Source audit/parity.** Inspect remaining source systems listed in SOURCE_AUDIT.md, document exact preserved-rule expectations and differences. Keep all new implementation independent. Obtain rights review before any commercial release.

## Gate state

| Gate | Observed status |
|---|---|
| A — systems exist | Pass for implemented slice; incomplete across full contract |
| B — individual verification | 577 passing assertions for covered rules; incomplete full mechanical matrix |
| C — integration | Pass for recruitment/equipment/travel/combat/payment/recovery/persistence slice |
| D — playable game loop | Desktop normal-control scenario passes; second battle verified through legal rules driver |
| E — mobile functional | APK produced and package/signature checked; device/touch verification outstanding, **not passed** |
| F — full foundation | **Not passed**; mandatory systems above remain open |

Phase 1 deployment is implemented and verified. Phase 2 sector-specific maps is implemented and verified for the documented archetypes. Continue with the remaining tactical/AI depth or device gate; the full foundation remains incomplete. Never mark the full foundation complete by lowering its definition.

The user-requested sequence 1-6 and combat feature pass is tracked separately in REQUEST_PROGRESS.md. Hardware and full-foundation gates remain open.


## Save hardening and scale follow-up — 2026-10-26

Phases 7 and 8 add typed event/financial/assignment records, structural preflight before migration, verified temporary/backup commits, process-termination recovery coverage, large-map heap routing, cached selection redraws and six 45-day campaign/replay scenarios. See HARDENING_SCALE.md and the raw profile/extended reports for exact evidence and limitations. The physical Android gate (phase 9) and wider source/parity/release audit (phase 10) remain open. No additional JA2 source was copied or newly audited in this follow-up.
