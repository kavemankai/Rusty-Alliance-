# Mechanical classification — audited 2026-10-26

PRESERVED describes the fundamental relationship; no subsystem claims exact numeric JA2 parity. ADAPTED retains a role with original medieval rules. ORIGINAL is independently designed for this game. DEFERRED entries explicitly distinguish future expansions from mandatory acceptance gaps. Source evidence is in SOURCE_AUDIT.md; detailed limitations are in CONTRACT_ACCEPTANCE.md.

| System | Class | Current implementation / limit |
|---|---|---|
| Sector map, routes, shared strategic clock | PRESERVED | Original 16x16 world, weighted travel, scheduled arrivals and contact interruption |
| Persistent individuals, employment and wages | PRESERVED | Original profiles, local recruitment, seven-day contracts, daily wages and typed ledger; no agency/aircraft arrival model |
| Timestamped event dispatch | PRESERVED | Stable time/ID ordering; original event records and services |
| Inventory ownership and durability | PRESERVED | Unique owned item IDs; equipment references; co-location/AP constraints; no source item data |
| Save continuity | PRESERVED | Full state/PRNG, version migrations and canonical rebinding; original verified JSON/backup protocol |
| AP and movement costs | ADAPTED | Original bounded AP/carryover, terrain/elevation/posture/mode costs; no numeric parity or animation startup costs |
| Turns, perception and personal/public knowledge | ADAPTED | Original team turns, individual AI memory, limited sharing, no-AP-refill contact; paid guard reactions replace interrupt contests |
| Ranged weapons and ammunition | ADAPTED | Bow/crossbow/javelin, typed compatible owned stacks, paid reload; no firearm tables or modern ballistics |
| Armour, wounds and treatment | ADAPTED | Original damage-type protection, per-item wear, localized severity and local aid; one-level geometry |
| Militia to levies | ADAPTED | Persistent local profiles, gear, casualties, training, upkeep and actual defence |
| Medical/repair/training assignments | ADAPTED | Hourly local skills/materials and actual repair objects; original rates/allocation |
| Economy/facilities/strategic military AI | ADAPTED | Original income, supplies, budgets, troop recruitment, reports, patrol/raids and aggregate roster clashes |
| Horses and wagons | ADAPTED | Owned strategic assets, forage/burden and split/merge conservation; fighters dismount tactically |
| Escort, patrol, capture, eliminate, camp and defence jobs | ORIGINAL | Real route/battle hooks, protected caravan actors, idempotent payments, deadlines and procedural road postings |
| Shields/parry/evade/reach/facing | ORIGINAL | Paid positioning and defence, deliberate disengage, charge/bash/ally protection |
| Squad/depot medieval supplies | ORIGINAL | Separate food/medicine/tools, local transfers, conservation and local care |
| Prisoner custody and ransom/rescue | ORIGINAL | Actual profiles, local custody, release/ransom/enlistment and victory rescue |
| Roofs, rooms, construction and approaches | ORIGINAL | Single-level authored geometry, persistent cutaways, fortifications/light and four entry approaches |
| Exploration/combat mode | ADAPTED | Discrete scouting pulses, patrols, interruption, saved orders, pause-on-load and quiet return; no physics locomotion |
| Formations and local support | ORIGINAL | Paid line/column/wedge movement, bounded sharing, shields/aid/rally; not unrestricted coordinated manoeuvre AI |
| Marches geography, catalogue, people and values | ORIGINAL | Project-authored world/profiles/primitives; no source campaign/maps/tables/assets |
| Multistorey maps, mounted tactical combat, supernatural/modern systems | DEFERRED expansion | Not represented as implemented; underground levels are conditional future scope |
| Comprehensive reachable/LOS/cover/occupancy debug overlays and scenario launcher | ORIGINAL; acceptance incomplete | Text inspector, grid/preview/routes and tests exist; full requested interactive overlay suite does not |
| Physical touch/thermal/battery/low-memory acceptance | Verification gate; open | Emulator evidence is kept distinct from mainstream-phone measurements |
