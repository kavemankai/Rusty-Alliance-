# Implemented rules, schema 2

Setting: original human mercenary company in the fractured Marches. No supernatural units or spells. Strategic coordinates shown one-based; stored sector IDs are y×16+x.

Campaign.s stores 256 sectors, stable mercenary/squad/group/job IDs, factions, funds, food, medicine, tools, stash, transaction ledger, timestamped events, PRNG state and encounter/battle state. Units are dictionaries; scene nodes never own gameplay values. Each inventory/stash entry is a unique item with ID, catalogue kind, integer quantity and condition. Equipment slots reference owned item IDs; combat/UI derive weapon, armour and condition through catalog accessors. There are no independent profile loadout values to drift out of sync. Enemy profiles belong to persistent group fighter rosters.

The Ashford stockpile has a strategic location. Taking, depositing and buying there require a stationary local squad. Transfers between fighters require the same sector; in combat the source must be active, the recipient adjacent, and the handover costs 3 AP. Equipped gear must be unequipped first. Switching gear keeps the previous item in the backpack; all carried gear adds encumbrance. Individual weapons, shields, armour and helmets wear through attacks, blocks, parries or absorbed damage, and repairs target an actual damaged item. Ammunition is an owned stack whose quantity decreases when fired.

## Clock and economy

Time is integer minutes, initially day 1 08:00. Events sort by timestamp then monotonically increasing ID. Arrival interrupts an advance at contact. Hourly updates charge one food per hired living fighter, apply assignments and fatigue. Midnight charges wages and levy upkeep; farms produce 50×loyalty×order/10,000 food, mines 100×that factor crowns. Debt is allowed and reduces morale. An hour with insufficient food reduces morale by 5 and adds 8 fatigue.

Recruitment costs the profile fee; wages continue separately. Seven-day employment expires through scheduled events. Renewal costs seven wages and extends seven days (an additional renewal fee, not prepaid wages). Two five-day capture contracts pay only through a real victorious battle at their target. No manual success control exists.

Travel uses four-neighbour weighted shortest paths. Road/grass/forest/hills/marsh base minutes: 45/70/100/115/140. The slowest member's fatigue, injury and burden set a group multiplier; food shortage adds 30%. ETA is an estimate: the next leg recomputes conditions on arrival. Foot transport only.

Medical care consumes one medical supply per treatment hour and heals 2+best active medical skill/15; current medical pooling is company-wide. Training yields 1+wisdom/40 points/hour, plus two at training grounds; 12 points improves melee by one, capped at 95. Repair consumes tools and uses smithing; workshops add four. Rest heals one HP/hour when not bleeding. Guard raises owned sector order. Scout reveals neighbouring sectors; high perception reveals a second ring. Garrison assignment improves levy training by leadership. Food/tools/medicine/stash are currently shared company abstractions.

## Tactical rules

18×14 encounter template; logical grids support 160×160. Orthographic 3D, Compatibility renderer, MultiMesh floor, no per-tile physics. Wall, closed door and occupied destination block pathfinding; window blocks movement and passes sight. Diagonal corner cutting is rejected. Base movement 2 AP; hill costs 3, brush 4; rising one level adds 2; diagonal multiplies by 1.4 rounded up. Crouch adds 1, prone adds 3, run subtracts 1 (minimum 1), cautious adds 1. Preview and execution share step_cost.

Original AP formula: floor((10+agility/12+dexterity/24+experience×0.6) × (0.45+0.55×HP/maxHP) × (1−fatigue/180) × burden multiplier). Clamp 4..26; HP≤10 gives zero. Low morale reduces AP by 30%. Strength affects carrying capacity and melee damage; endurance affects travel/run exertion. Leadership supports daily morale and levy training. All listed base attributes have a simulation use.

Team turns refill AP without carryover. Bleeding ticks at own-team turn start and hourly outside combat. Unconscious units at HP≤10 cannot act; HP=0 is death. Player turn → enemy rules-driven actions → next player turn; outcome derives from capable survivors. Retreat requires a capable fighter and a safe adjacent sector (company/free ownership and no active hostile force). The actual arrival sector is preferred. Withdrawal adds 10 fatigue and keeps losses. Defeated survivors with no valid egress are marked captured and cannot be rehired; further prisoner interactions are not implemented. Enemy turns are synchronous and bounded.

Each visited battlefield retains its tile data, doors and ground placements in the sector. Enemy units share profiles with their strategic group, preserving wounds, health, ammunition, equipment, reload state and positions through retreat/save/re-entry. Group strength is derived from capable, uncaptured fighters. On a strategic move, the group retains people/equipment but clears old local positions. Death moves actual owned equipment onto the ground; looting transfers that same item. Victory collects remaining loot into survivor backpacks rather than teleporting it into Ashford. Multiple contacts from a strategic tick queue; obsolete route callbacks are rejected by a route token and timestamp. Friendly squads do not yet deploy together into a combined battle.

Hit percentage is clamp(50+skill×0.6−target agility×0.25+weapon accuracy+aim×7−fatigue/5−lost HP/5+morale modifier+experience×2+elevation×5+position modifiers,5,95). Ranged attacks additionally apply range, cover, concealment and stance penalties. Rear melee adds 22; nearby additional attackers add pressure. The displayed probability is the initial contact roll; eligible AP-funded block/parry/dodge can negate a successful contact. Bow reload costs 2 AP; crossbow reload costs 7. Ammunition is shared by missile category at present.

Armour reduces original damage by damage type; random body location changes head protection and damage. Cutting/piercing/projectiles cause persistent bleeding. Weapon durability affects damage and can be repaired. Medical action costs 5 AP and one medicine. Defence costs 2 AP and requires consciousness, morale and an eligible facing. Guard reserves current AP for melee disengagement or visible ranged reactions.

Visibility uses perception, facing, stance, concealment, walls/windows and elevation. Known opponents are distinct from actual units; AI can use remembered positions and sounds. Full unexplored terrain fog and lighting are outstanding. Current AI is a bounded patrol/investigate/approach/fire/reload/retreat policy, not JA2's full tactical decision model.

## Persistence and input

JSON version 2, integer PRNG, temporary write/flush, previous-generation .bak then rename. Load normalizes JSON integer values and rebinds both friendly and hostile tactical profiles to their canonical campaign owner, plus the active sector battlefield arrays. Schema 1 is upgraded on detached parsed data; loading does not rewrite the original save. Tests use actual previous-release strategic, tactical and corpse/loot saves. Validation rejects duplicate ownership, equipment without an owner, item-ID allocator reuse, mismatched tactical/strategic profiles and malformed terrain. Unsupported versions are rejected; additional future migrations and broader malformed-data/OS write-interruption tests remain open.

All essential implemented actions use on-screen controls. Tap previews before movement/attack; drag pans; pinch and +/- zoom. Panels scroll and destructive dismissal/retreat ask confirmation. Application pause writes autosave. Hardware cutout handling and multitouch behaviour still need device QA.
