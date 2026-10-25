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

## Next work, in order

1. **Android interaction/device gate.** Install supplied APK on mainstream hardware. Test touch select/confirm/cancel, scroll, two-finger pan/zoom, cutouts, pause/resume, OS interruption and low-memory behaviour. Measure frame pacing and input latency; record hardware and results. Device QA is currently an external blocker.
2. **State model hardening — core ownership/logistics complete.** Item identities, condition/transfers, squad/sector supply stores and schema-1→2→3 migrations are implemented and verified. Conservation, local access, canonical references and basic terrain validation are in place. Remaining: typed assignment/financial/event records, broader malformed-data tests and disk-interruption injection.
3. **Strategic battle continuity — core defence complete.** Persistent battlefields/enemies, adjacent withdrawal, encounter queueing, tactical levies and combined friendly squads are implemented and tested. Remaining: prisoner interactions beyond the captured flag, levy equipment management beyond their starting kit, deliberate deployment/fortification design and sector-specific geography.
4. **Job breadth.** Add elimination, camp assault, escort, patrol and settlement defence as actual state-driven objectives. Add contract prerequisites, counters, failure events and repeatability. No fake completion action. Current jobs are capture only.
5. **Tactical depth.** Implement deliberate deployment, disengage action, exploration/combat transition, AP carryover policy, injury locations/severity, equipment drawing/turn costs, distinct projectile ammunition, throwing items, explicit shield condition, directional geometry-derived cover, lighting and true terrain fog. Add roofs, interiors and persistent ground items.
6. **AI depth.** Improve cover choice, failed pursuit, formations, ally defence, role coordination, sound prioritisation and morale behaviour. Add strategic resources, reinforcement budgets, threat response and patrol objectives. Current factions have simple daily movement; friendly defended sectors now use real tactical battles.
7. **Scale and tests.** Profile 160×160 pathfinding, visibility and rendering. Replace repeated open-list sorting with a heap if measurements require it. Extend the ten scenarios to every mandatory rule and run multi-seed extended campaigns. Add hardware Android smoke CI when available.
8. **Source audit/parity.** Inspect remaining source systems listed in SOURCE_AUDIT.md, document exact preserved-rule expectations and differences. Keep all new implementation independent. Obtain rights review before any commercial release.

## Gate state

| Gate | Observed status |
|---|---|
| A — systems exist | Pass for implemented slice; incomplete across full contract |
| B — individual verification | 208 passing assertions for covered rules; incomplete full mechanical matrix |
| C — integration | Pass for recruitment/equipment/travel/combat/payment/recovery/persistence slice |
| D — playable game loop | Desktop normal-control scenario passes; second battle verified through legal rules driver |
| E — mobile functional | APK produced and package/signature checked; device/touch verification outstanding, **not passed** |
| F — full foundation | **Not passed**; mandatory systems above remain open |

Continue with the remaining contract types when no Android hardware is available. Never mark the full foundation complete by lowering its definition.
