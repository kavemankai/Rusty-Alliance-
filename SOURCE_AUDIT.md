# Reference source audit

Repository: https://github.com/kavemankai/jaggedalliance2.git
Inspected revision: 9bec381bcaec845361e13f95098faaf294435acd
Inspection date: 2026-10-25. The reference checkout lives outside this deliverable under work/ja2-reference.

| Source location | Observed relationship | Independent implementation |
|---|---|---|
| ja2/Build/Tactical/Soldier Control.c:473, CalcActionPoints | Ability/experience establish base AP; health, breath and carried burden reduce it; minimum and maximum bounds apply. New turns permit limited carryover. | catalog.gd uses an original bounded formula and fatigue/burden modifiers. No numeric parity claimed; no carryover yet. |
| ja2/Build/Tactical/Points.c:247, ActionPointCost and preceding TerrainBreathPoints | Terrain and movement mode control AP/breath costs; weight affects exertion; costs are distinct from graphics. | tactical.gd step_cost drives A* preview and execution; original cost values. |
| ja2/Build/Strategic/Strategic Movement.c:1557, GroupArrivedAtSector; :2738, CalculateTravelTimeOfGroup; :3123, GetTravelTimeForGroup | Groups carry waypoints and arrival timestamps; remaining travel and subsequent waypoint travel compose ETA. Arrivals can trigger battle checks. | Weighted four-neighbour routing, timestamped arrivals, hostile-contact time interruption. |
| ja2/Build/Strategic/Game Events.c:213, ProcessPendingGameEvents; :428, AddStrategicEvent | Pending timestamped events are executed through callbacks within a world-time adjustment. | Explicit sorted (minute, stable event id) event queue; hours and arrivals share the same clock. |
| ja2/Build/Strategic/Game Event Hook.c:74, ExecuteStrategicEvent | Dispatch links events to strategic services. | Campaign event dispatch calls arrival, hourly assignment and daily economy/faction processing. |
| ja2/Build/TacticalAI/AIUtils.c:1164, ClosestSeenOpponent | Filters neutral/allied/inactive opponents and checks personal opponent knowledge before using current positions. | Enemy decisions access visible knowledge, last-known coordinates and acoustic coordinates. Omniscient target selection is excluded. |
| ja2/Build/SaveLoadGame.c:460, SaveGame; declarations near :421 | Save pipeline includes versioned header and random-number persistence among campaign systems. | Current JSON schema 3 saves full campaign/tactical state and integer PRNG, with schema-1/2 migration, backup recovery and canonical rebinding. |
| ja2/Build/Strategic/Town Militia.c:248, StrategicAddMilitiaToSector and following promotion/removal routines | Persistent sector data stores militia quantities by rank; promotion transfers people between ranks. | Original individual levy profiles belong to each sector, with strength derived from actual capable survivors. |
| ja2/Build/Strategic/Assignments.c:4104, TrainTownInSector | Trainer contributions accumulate local training progress; completion connects to militia training results and payment state. | Original leadership-based training improves existing levy skills at documented thresholds; no source constants or rank tables copied. |

File discovery also located Tactical/PATHAI.C, Tactical/LOS.c, Tactical/opplist.c, Laptop/finances.c and Tactical/Merc Hiring.c. Those subsystems have **not** received a line-by-line parity audit. The original request's broader source study remains incomplete.

All descriptions above are research notes. No original source code, tables, maps, mercenary profiles or assets are incorporated. See MECHANICS_PARITY.md for the deliberately limited fidelity claims.

The schema-2 inventory/continuity update uses original rules: an item has one owner, equipment references owned IDs, hostile individuals remain in persistent groups, local doors/ground placements belong to their sector, and withdrawal chooses a safe adjacent sector. This update does not establish any new numerical JA2 parity claim or import additional reference material.

The schema-3 update adds original squad/depot supply accounting and individual tactical levies. Town Militia.c and the specified training routine were inspected for persistent sector/training relationships; no numeric parity or translation is claimed. Current saves are schema 3 with migration/rebinding for all three tactical profile owners.

The contract-board update is independent original design, using existing strategic arrival and battle-result hooks. No additional JA2 source was inspected or copied for these objectives. Named-force/camp/defence payments, ordered patrols and escorted strategic freight make no numeric or mission-data parity claim.
