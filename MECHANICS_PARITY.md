# Verified fidelity and differences

This is an independent implementation inspired by JA2 system relationships. **Exact numeric parity is not established for any subsystem.** PRESERVED classifications refer to the purpose/architecture, not copied formulae or tables.

Verified: ability/condition-dependent AP; paid legal path execution; weighted sector routes; timestamped arrival/contact; chronological world events; distinct current knowledge and remembered enemy coordinates; company state persisting across battle and save/load; real economic consequences; unique equipment ownership and condition; persistent hostile casualties/injuries; sector doors and ground loot; adjacent retreat and queued contacts.

Differences: original 4..26 AP formula; original capped four-point AP carryover; encounters offer opt-in command-based exploration or direct team turns; sampled LOS and original directional adjacent-cover rules; guard reactions rather than JA2 interrupt contests; original armour/damage; no firearm data; daily resource/intelligence-driven strategic group movement; original squad/depot provision rules; individual medieval levy profiles and original training thresholds rather than JA2 rank counters; six original contract objective types with strategic freight escort; four original facility layout archetypes plus terrain-based wilderness, with persistent authored deployment zones and explicit pre-combat confirmation. Any unimplemented mandatory rule remains open regardless of passing existing tests.

SOURCE_AUDIT.md records source paths/functions actually inspected. QA_REPORT.md records the tests actually run. No claim of commercially cleared legal status or complete source-mechanical reconstruction is made.

Exploration-to-combat preserves the relationship between sight/contact and turn-state changes, with independent movement pulses, recovery/bleeding values and quiet-exit policy. The company always starts contact combat with remaining AP. This deliberately differs from the reference starting-team/initiative handling; no numeric parity is claimed.

Per-team terrain fog, cached remembered geometry and bounded cover/pursuit/support decisions are independently implemented. Personal/public opponent knowledge relationships informed the audit, but the game uses shared team sight, a three-round memory horizon and original cover values. No JA2 AI score, cover formula, numeric table or map data is reproduced.

The production pass uses independent combat styles, wound severity, medicine/repair, ammo typing, transport, prisoner, convoy and strategic-budget rules. Rooms/roofs are single-level primitive geometry, and company-absent army clashes are aggregate rules over real profiles. No new numeric or source-level JA2 parity is claimed.


## Save hardening and scale follow-up — 2026-10-26

Phases 7 and 8 add typed event/financial/assignment records, structural preflight before migration, verified temporary/backup commits, process-termination recovery coverage, large-map heap routing, cached selection redraws and six 45-day campaign/replay scenarios. See HARDENING_SCALE.md and the raw profile/extended reports for exact evidence and limitations. The physical Android gate (phase 9) and wider source/parity/release audit (phase 10) remain open. No additional JA2 source was copied or newly audited in this follow-up.


Phase 10 expands the relationship audit to path plotting, height/perception, opponent/interrupt handling, finance, hiring, close/ranged combat, armour wear, care/repair, strategic reinforcement evaluation and morale. MECHANICS_MAPPING.md now reflects implemented jobs, transport, rooms and exploration instead of stale prototype deferrals. CONTRACT_ACCEPTANCE.md records mandatory gaps without labelling them optional. No numerical or legal parity claim is added.
