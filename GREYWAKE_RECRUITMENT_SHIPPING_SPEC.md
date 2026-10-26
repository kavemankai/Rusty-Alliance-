# Greywake recruitment shipping specification

Project: The Broken Marches — The Fall of Greywake. Target: Godot 4.6.2, GDScript, desktop first.
Approved user design, supplied 2026-10-26. This document records the requirements implemented by this milestone; current verification and remaining upstream dependencies are in GREYWAKE_RECRUITMENT_STATUS.md.

## Scope and locked rules

Greywake is a separate scenario (`fall_of_greywake`). Original campaign geography, recruitment, contracts, combat, AI, seven-skill progression, ownership, wages and renewal accounting remain unchanged. The authoritative twelve-profile workshop roster is in data/greywake_roster.json; its independent acceptance fixture is tests/fixtures/greywake-roster.txt.

Opening mainland recruitment uses 2,400 crowns, an empty company and a six-person transport. At least **two** paid mercenaries are required before departure. All selected fighters arrive together at Dock Town with actual owned equipment. Elite profiles are visible but exceed the opening purse. Local levies, rebels and political allies remain distinct from paid mercenaries. After departure a surviving one-person company remains playable; no free replacements, money or resurrection are granted.

Professional reinforcements come from the mainland. Ships arrive every four campaign days on a fixed calendar. Missing a ship never moves the calendar, creates a make-up ship, extends an offer or grants a refund.

## Named implementation defaults

| Parameter | Default |
| --- | --- |
| First arrival | Day 4, 06:00; absolute minute 4,680 |
| Later arrivals | Day 8, 12, 16, 20 at 06:00 |
| Arrival interval | 5,760 minutes |
| Maximum offshore wait | 1,440 minutes |
| Docked recruitment window | 2,880 minutes |
| Manifest | 2–4 persistent candidates |
| Hiring location | Authored Dock Town sector reference |
| Opening purse | 2,400 crowns |

Day 1 starts at absolute minute zero; the established campaign starts at 08:00, minute 480. Never calculate the first arrival relative to session start or the first port visit. Clock balancing defaults are constants in sim/greywake_shipping.gd. Candidate weighting is provisional: the first slot is cheap, subsequent slots choose a remaining professional with probability one third when one is eligible; otherwise a cheap archetype is selected.

## Vessel lifecycle and exclusive deadlines

A vessel has one authoritative status: `scheduled`, `offshore`, `docked`, `departed`, `turned_back` or `cancelled`.

Valid ordinary transitions: scheduled→docked when accessible; scheduled→offshore when blocked; offshore→docked before its deadline; offshore→turned_back at its deadline; docked→departed at its recruitment deadline. A supported authored cancellation is terminal. Terminal vessels never reopen.

A Day 8 06:00 vessel has an offshore deadline Day 9 06:00. Recovery at Day 8 23:00 or Day 9 05:59 permits docking. Recovery exactly Day 9 06:00 is too late. Hiring likewise requires current time strictly before the offer's expiry. Late docking receives its full 48 hours from actual docking time. A blockade on an already docked vessel suspends hiring immediately, retains its original departure time, and never creates another offshore wait. Lifting it only restores unexpired offers.

## Authoritative port control

The single Greywake access query combines sector ownership, permitted harbour administrations, a legitimate authored passage grant, and explicit harbour closure reasons. Squad presence never grants access. The starting port is open. Hostile occupation blocks it. Explicit closures store only reasons independent of ownership; they do not duplicate sector control.

Military recovery uses existing tactical victory and sector-control transitions. After authoritative access changes, examine waiting vessels, dock exactly once if current time precedes the deadline, establish the actual docking expiry and announce arrival. Negotiated recovery is an integration hook for a later authored outcome, never a free player action. Suspicion, inspections and tariffs do not implicitly become full blockades. Port logistics must not rewrite any of the three ending conditions.

## Persistent manifests and identities

Generate a manifest exactly once when a vessel reaches Greywake, including during blockade. Each offer records a unique offer ID, vessel ID, template ID, fixed candidate ID/name, fee, wage, statistics/equipment preview, status and hired person reference. Opening screens never reroll manifests. Hiring all passengers never refills a vessel.

Named passengers reference canonical Greywake records, never copied people. They cannot occupy two active offers or return after hiring, death, capture or permanent unavailability. Repeatable offers reserve monotonically increasing person identities when generated; owned equipment is created only on successful hiring. Unused reservations are skipped permanently. Each hired individual owns separate gear, wages, injuries and progression.

## Atomic hiring

After opening departure all hiring requires a docked vessel offer. Validate before mutation: Greywake scenario and completed departure; no tactical battle or unresolved encounter anywhere; docked vessel and available unexpired offer; accessible Dock Town; existing stationary hiring squad physically at Dock Town; eligible candidate without duplicates; sufficient crowns; roster and equipment limits.

Success obtains or creates the canonical person, charges once, establishes existing seven-day employment/wage rules, assigns the squad, instantiates or retains owned gear once, marks the offer hired, records the transaction and schedules employment. Failure must leave funds, membership, item IDs, employment events, identity counters and offers unchanged. Opening recruitment is a distinct mainland path and does not require a docked Greywake vessel.

## UI and notifications

Dock Town must show harbour access, next arrival, current vessel status, exact offshore or recruitment deadline, available candidate previews/costs and the location requirement. The final island map needs a separate port recruitment marker; that map remains an upstream milestone. The current staging port displays a ship status marker instead.

- **MAINLAND VESSEL WAITING OFFSHORE**: identify Dock Town and the exact waiting deadline; state that its captain will return to the mainland if the harbour stays sealed. Do not reveal passenger identities.
- **HARBOUR REOPENED**: announce landing and the exact recruitment departure.
- **REINFORCEMENTS LOST**: announce return to the mainland and that no new mercenaries landed.

## Saves and scheduler

Preserve Greywake manual/autosave slots and original-save migrations. Namespaced `shipping` contains `next_sequence`, `next_arrival_at`, `port_blockade`, `passage_granted` and persisted `vessels`. Vessels contain IDs, original arrival, single status, offshore deadline, actual docking time, recruitment deadline and offers. Offers contain IDs, candidate identity, fixed preview, status and person reference. Validate timing, references, eligibility, allocator bounds and pending events strictly.

Use `greywake_ship_arrival`, `greywake_offshore_deadline` and `greywake_recruitment_departure`, never generic travelling-squad `arrival`. The campaign scheduler owns time. Arrival schedules the next vessel from the original arrival plus 5,760; blocked arrival schedules plus 1,440; docking schedules actual docking plus 2,880. Event IDs and lifecycle guards make repeated/obsolete callbacks harmless. Offshore expiry wins at its exact timestamp. Multi-day advances process shipping, wages, employment and other existing deadlines chronologically. Shipping callbacks never advance time. Battles and pause do not independently consume waiting time.

## Required acceptance scenarios

1. Open-port Day 4 06:00 arrival.
2. Blockaded Day 4 arrival waits offshore.
3. Recovery at 23 hours 59 minutes docks.
4. Recovery at exactly 24 hours fails.
5. Missing a ship preserves Day 8 arrival.
6. Late docking grants 48 hours.
7. Docked blockade suspends recruitment without resetting expiry.
8. Reopening restores original unexpired offers.
9. Manifest survives save/load identically.
10. Named person hired once.
11. Repeatable people/items have separate persistent identities.
12. Expired hire rejects without mutation.
13. Inland squad hire rejects without mutation.
14. Post-departure unrestricted shortcuts reject.
15. Failed purchase consumes no funds, IDs or items.
16. Reloaded offshore deadline matches continuous play.
17. Twelve-day advance processes each intermediate event once.
18. Tactical encounter/pause does not consume shipping time.
19. Recovery does not duplicate vessels or rewrite history.
20. Original recruitment and save/load continue to pass.
21. Corrupt shipping references are rejected safely.
22. Opening confirmation requires at least two fighters.
23. One-person survivors remain playable after departure.
24. A remote squad cannot receive a hire during another ongoing battle.

## Boundaries and unresolved dependencies

The authored 10×10 island, overseas travel presentation, contracts, garrisons/military AI, historical evidence, faction consequences, actual victory routes/endings, economy balancing and physical Android acceptance are separate work. No free political resolution or unrelated narrative is authorized here. Recovery must eventually have ordinary paid work and travel where world state permits; report softlocks instead of silently changing the economy. The hooded patron's identity must never be revealed. The heir, assassination and uprising routes may overlap, but recruitment does not implement or decide their endings.
