# Continuation plan

The production contract is larger than the delivered slice. Preserve working integration while expanding it; do not mistake present tests for full acceptance coverage.

## Verified slice

- Godot 4.6.2 project, original simulation code and original world fixtures.
- Campaign state, deterministic RNG, ordered clock, commands, backup saves and active-battle rebinding.
- Real recruitment, purchases/equipment, squads, route travel, supplies, contracts, battle resolution, ownership, income, wages and assignments.
- Turn-based tactical pathfinding/AP, facing, melee reach, missile reload/ammunition, armour/defence, wounds/bleeding, morale/fatigue, perception and bounded AI.
- Primitive orthographic 3D, Control interfaces and normal-control end-to-end regression.
- Signed debug APK and repeatable local build script. Remote workflow supplied, not run.

## Next work, in order

1. **Android interaction/device gate.** Install supplied APK on mainstream hardware. Test touch select/confirm/cancel, scroll, two-finger pan/zoom, cutouts, pause/resume, OS interruption and low-memory behaviour. Measure frame pacing and input latency; record hardware and results. Device QA is currently an external blocker.
2. **State model hardening.** Replace catalogue-key equipment ownership with unique item-instance IDs, per-item condition and item transfers. Add per-squad supplies, explicit assignment/financial/event records as typed data models, schema migrations and nested tactical-save validation. Retain schema-1 loading through migration. Test duplicates, invalid saves and interrupted writes.
3. **Strategic battle continuity.** Preserve sector tactical state and structures between visits; maintain survivors of a retreat in persistent enemy groups. Current retreat leaves the strategic enemy strength unchanged. Replace the fixed retreat-to-Ashford rule with valid egress sectors. Prevent overlapping squad arrival events and queue simultaneous encounters. Make friendly levies participate in tactical defence.
4. **Job breadth.** Add elimination, camp assault, escort, patrol and settlement defence as actual state-driven objectives. Add contract prerequisites, counters, failure events and repeatability. No fake completion action. Current jobs are capture only.
5. **Tactical depth.** Implement deliberate deployment, disengage action, exploration/combat transition, AP carryover policy, injury locations/severity, equipment drawing/turn costs, distinct projectile ammunition, throwing items, explicit shield condition, directional geometry-derived cover, lighting and true terrain fog. Add roofs, interiors and persistent ground items.
6. **AI depth.** Improve cover choice, failed pursuit, formations, ally defence, role coordination, sound prioritisation and morale behaviour. Add strategic resources, reinforcement budgets, threat response and patrol objectives. Current factions have only simple daily target movement and abstract garrison clashes.
7. **Scale and tests.** Profile 160×160 pathfinding, visibility and rendering. Replace repeated open-list sorting with a heap if measurements require it. Extend the ten scenarios to every mandatory rule and run multi-seed extended campaigns. Add hardware Android smoke CI when available.
8. **Source audit/parity.** Inspect remaining source systems listed in SOURCE_AUDIT.md, document exact preserved-rule expectations and differences. Keep all new implementation independent. Obtain rights review before any commercial release.

## Gate state

| Gate | Observed status |
|---|---|
| A — systems exist | Pass for implemented slice; incomplete across full contract |
| B — individual verification | 87 passing assertions for covered rules; incomplete full mechanical matrix |
| C — integration | Pass for recruitment/equipment/travel/combat/payment/recovery/persistence slice |
| D — playable game loop | Desktop normal-control scenario passes; second battle verified through legal rules driver |
| E — mobile functional | APK produced and package/signature checked; device/touch verification outstanding, **not passed** |
| F — full foundation | **Not passed**; mandatory systems above remain open |

Continue from step 2 when no Android hardware is available. Never mark the full foundation complete by lowering its definition.
