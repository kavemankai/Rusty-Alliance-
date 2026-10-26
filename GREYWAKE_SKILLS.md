# Greywake skill system — implementation and open acceptance

2026-10-26 · 0.13.0-skills-preview

**The shared skill system and recruiting infrastructure are implemented. The finalized Greywake scenario is not complete: the workshop's twelve-template names/statistics/fee/wage table was not included in the handover and is not available as readable conversation data.** `data/greywake_roster.json` deliberately contains no fabricated roster. New Greywake creation remains disabled until a valid finalized table is supplied. Synthetic test profiles are confined to tests and are excluded from playable exports.

The handover is the design baseline; numerical tuning remains subject to playtesting. None of the provisional mechanics below substitutes for the missing workshop statistics.

## Characters and compatibility

Seven attributes remain Strength, Agility, Dexterity, Endurance, Perception, Wisdom and Leadership. The seven skills are Melee, Ranged, Medical, Smithing, Stealth, Fieldcraft and Athletics. Weapon performance continues using the existing weapon catalogue, Melee/Ranged, action types and defence modes. There are no individual weapon skill trees.

`sim/catalog.gd` creates all people with the three additional skills. Existing schema-1, schema-2 and schema-3 saves are normalized on detached parsed data before adoption; old equipment, item IDs, injuries, kills, experience and employment records are retained. All canonical profiles, including enemies, levies and convoy actors, receive the added fields.

Legacy values for the three new skills default to **40**, a neutral baseline. Existing attributes/four skills and the original named roster are unchanged. Benefits begin above that baseline. Explicit malformed added-skill values, training banks and training timestamps are rejected rather than silently replaced. New skills are integers in 0..100; normal training caps a skill at 95.

## Functional effects

| Skill | Actual rule | Safeguards |
|---|---|---|
| Stealth | In a tile with concealment, cautious/crouched/prone people reduce detection radius by one tile per 12 points above 40, capped at four. Running forfeits this benefit; close detection has a two-tile floor when this bonus is applied. | Uses the actual LOS/concealment check for people; does not hide terrain, bypass walls, invent visibility or supply hidden positions to AI. Open ground gives no Stealth bonus. |
| Fieldcraft | In fields explicitly marked wilderness, grass/brush/hill/mud/forest movement with base cost above two is reduced by one AP per 25 points above 40, capped at two and never below two. A scouting assignment at 70+ can discover sectors two neighbour links away, matching the existing high-Perception scouting radius. | Shared `step_cost` drives both path solvers, AP preview and execution. No discount on unknown provisional terrain, roads, floors, urban fields or carts. Old fields without layout metadata are not reclassified. Scouting requires an actual scheduled hour and reveals nearby strategic geography through existing scouting rules; it does not alter tactical fog or enemy memory. |
| Athletics | Running fatigue per paid step is reduced by one per 20 points above 40, with a minimum of one fatigue. Deliberate disengagement surcharge drops from four AP to a minimum of two. Strategic retreat fatigue drops from ten toward a minimum of four. | Combat and exploration share the same fatigue calculation. Withdrawal preview and execution share the same surcharge; legal adjacent destination, remaining movement AP and existing guard/reaction rules still apply. No free movement or AP refill is introduced. |

Withdrawal estimates use charted/provisional terrain and perceived threats. Hidden obstacles or terrain discounts cannot leak through the displayed AP quote; execution still validates actual legality and resources before the deliberate-withdrawal surcharge. Known terrain has exact preview/execution agreement, while unknown terrain remains provisional like the normal route preview.

## Training and progression

The company screen displays all seven skills and offers `Train <skill>` controls. Training assignments accept a selected skill; omitting it retains the character's prior selection, initially Melee.

Each person owns their selected skill, a seven-entry partial-progress bank and the last rewarded simulation hour. Switching skills preserves separate partial credit; it cannot move credit to another skill. Twelve points raise the selected skill by one. The existing Wisdom rate and training-facility bonus are retained. Training requires a capable employed character, stationary assignment, food availability and advancing simulation time. A character can receive training progress at most once in a simulation hour, even across save/load or assignment changes.

Selecting a skill, changing stance/mode, failed movement, recruiting, waiting without eligible training, or repeatedly issuing a free command does not award experience. Training increases only the selected skill, not experience level. Existing kill-based experience remains individual. No new XP is granted for walking loops, scouting already-known terrain, or repeated no-cost interactions.

## Recruiting and separate scenarios

`sim/recruitment.gd` validates exactly twelve templates: two repeatable Cheap, four unique Mid, four unique High and two unique Elite. Each row must explicitly supply seven attributes, seven skills, a hiring fee and a daily wage. Named template IDs/names must be unique; Elite hiring fees must exceed the **2,400-crown Greywake opening purse**.

The original campaign keeps its 1,200-crown purse, six named mercenaries, Mara/Oswin starting company and original world/content. Greywake is a separate explicitly selected new campaign with its own state, an empty company to fill from the validated roster, ten unique named profiles and two repeatable archetypes. It currently reuses the implemented strategic world; no additional Greywake geography or boat-arrival content was supplied or claimed.

New-scenario configuration is permitted only on a pristine new campaign instance. Loaded/active campaigns cannot be reset into Greywake to recover opening funds. Normal Greywake saves and autosaves use `greywake.json` and `greywake-autosave.json`; original campaign save paths remain separate. Both manual-load and autosave-continuation controls preserve the scenario.

Each accepted cheap hire pays its fee, receives a monotonic person ID, unique name and uniquely identified owned equipment, and schedules its own employment expiry. Stats initially match the selected template; dictionaries, equipment, injuries, experience and training are not shared. Failed recruitment changes no money, IDs, people, inventory or events. Ten named people are created once and cannot be duplicated by another hire. Existing fired recruits remain individuals with their histories; repeating a cheap template creates a new person.

The existing save envelope supports at most 4,096 mercenary profiles. Repeatable cheap hiring has no two-person/template quota; this pre-existing technical save limit is still enforced. Identity counters and named-template membership are validated on reload.

## Renewal accounting investigation

The current system charges **hiring fee** once and wages daily. Renewal separately charges `daily wage × 7` immediately, extends expiry by seven days, and does **not** stop daily wages. For original Mara, renewing costs 140 upfront; the next midnight still charges the original company's 40 total daily wages. An explicit regression check records this behaviour.

No renewal accounting was changed in this pass. Treating that upfront charge as a prepaid wage balance versus a separate renewal fee requires a clear design decision; the existing UI wording should not be interpreted as proof that daily wages have been prepaid. The new character panel explicitly separates initial hiring fee and daily wage.

## Acceptance evidence and remaining blocker

| Acceptance item | Status |
|---|---|
| Seven attributes/seven skills, functional effects | Implemented and covered by new simulation checks |
| Older saves, ownership and character history | Schema-1/2/3 cases and migration checks pass within the tested scenarios |
| Repeatable individuals, unique named profiles, starting selection | Infrastructure tested with an explicitly synthetic twelve-row roster; actual workshop roster remains missing |
| Selected training and no free/repeated XP | Tested, including same-hour rejection and per-skill bank isolation |
| Original campaign, paths, fog and AI knowledge | Existing suites retained; new checks cover Stealth knowledge and skill-aware movement AP |
| Android skill controls and recruiting | Native emulator checks use real input; Greywake recruiting uses a documented synthetic save fixture, not a shipped production roster |
| Exact twelve finalized workshop templates/statistics | **BLOCKED ON INPUT**: paste the authoritative names, stats, fees, wages and any starting equipment details |
| Full Greywake acceptance | **Not complete** until that table is integrated and retested |

Exact test counts, package checks and emulator evidence are recorded in GREYWAKE_QA.md. Physical-device performance/thermals and broader balance remain unverified.

Roster data uses rows with `id`, `name`, `tier` (`cheap/mid/high/elite`), `repeatable`, `background`, `weapon`, `fee`, `wage`, seven-key `attributes` and seven-key `skills`. Optional starting details supported are `armour`, `shield`, `helmet`, `max_hp` and `experience`. The workshop table can be supplied as ordinary text; it does not have to be authored as JSON.
