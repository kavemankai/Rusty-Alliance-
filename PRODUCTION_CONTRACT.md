# CODEX MASTER PRODUCTION CONTRACT
# THE BROKEN MARCHES
## A Mobile-First, Low-Fantasy Medieval Tactical Strategy RPG
### Mechanics-First Godot Development

---

# 1. MISSION

You are the autonomous development team responsible for designing, implementing, integrating, testing and delivering the complete mechanical foundation of a medieval tactical strategy RPG.

The primary mechanical reference is Jagged Alliance 2.

Reference repository:

https://github.com/kavemankai/jaggedalliance2.git

Your assignment is to build an original medieval game inspired by the interconnected strategic and tactical simulation of Jagged Alliance 2.

You are responsible for:

- Game systems architecture.
- Gameplay programming.
- Tactical combat mechanics.
- Strategic campaign simulation.
- Mercenary management.
- Tactical and strategic AI.
- World state and persistence.
- Equipment and inventory.
- Economy and logistics.
- Mobile user interaction.
- Performance engineering.
- Automated testing.
- Android builds.
- Debugging and verification.

**You are producing a functional game, not a design proposal, isolated combat prototype or graphical demonstration.**

The completed milestone must be playable using primitive graphics, contain a coherent strategic-to-tactical game loop, and provide verified mechanical behaviour.

Work autonomously and make routine development decisions without asking for user approval.

Proceed beyond planning into actual implementation.

# 2. NON-NEGOTIABLE DEVELOPMENT PRIORITIES

Follow this order:

1. Correct mechanical behaviour.
2. Strategic and tactical integration.
3. Playable end-to-end gameplay.
4. Reliable mobile touch interaction.
5. Deterministic simulation and testability.
6. Persistent campaign state.
7. Functional tactical and strategic AI.
8. Maintainable, extensible architecture.
9. Android performance and reliability.
10. Visual presentation.

Visual polish is explicitly excluded.

**The game must work correctly before it looks good.**

Do not sacrifice core mechanics to add features that merely make the project appear more complete.

Build a small but genuinely interconnected implementation before expanding system breadth.

# 3. PLATFORM AND ENGINE

Use Godot 4.x.

Prefer Godot 4.6 stable if available and compatible with the configured build environment, otherwise choose an appropriate stable Godot 4 version and document it.

Use GDScript as the default language.

C# or native extensions are permitted only where a measured engineering requirement justifies their use.

## Target platform

Android is the primary platform.

The game must be designed mobile-first rather than created for desktop and adapted afterwards.

Desktop builds may be used for development, debugging and optional future release.

## Orientation

Use landscape orientation as the default for the tactical and strategic interfaces.

This is a design recommendation rather than an immutable constraint. Only change it if there is a compelling, demonstrated usability benefit.

## Rendering

Use 3D environments with an orthographic isometric camera.

Design the rendering architecture to support a visual style similar to a modernised Jagged Alliance 2:

- Readable environments.
- Grounded medieval architecture.
- Distinct silhouettes.
- Strong tactical visibility.
- Detailed terrain.
- Clear differentiation between units and structures.

Do not implement those finished assets now.

Select a mobile-compatible rendering configuration and verify it on the available target hardware.

Do not assume Forward+ is suitable for every Android device.

# 4. VISUAL SCOPE: PRIMITIVES ONLY

This is an intentional greybox development milestone.

Use:

- Capsules for characters.
- Coloured shapes for factions.
- Cubes for buildings.
- Simple planes for floors.
- Blocks for walls and doors.
- Basic meshes for trees and rocks.
- Lines for movement paths.
- Colour overlays for reachable tiles.
- Simple icons or text for item types.
- Plain panels for management interfaces.

Do not create:

- Detailed character models.
- Character skins.
- Finished weapons.
- Texture packs.
- Music.
- Soundtracks.
- Voice acting.
- Cinematics.
- Complex animations.
- Decorative visual effects.
- Final environmental art.
- Promotional material.

These are intentionally deferred.

Primitive visuals must clearly indicate all relevant gameplay information.

The player must be able to distinguish:

- Friendly and hostile units.
- Unit type.
- Selected unit.
- Current health and action points.
- Cover.
- Movement legality.
- Tactical elevation.
- Line of sight.
- Valid targets.
- Movement paths.
- Interactable objects.
- Current strategic ownership.

**Primitive graphics are an accepted final output for this milestone. Do not treat them as something that must be replaced before delivery.**

# 5. ORIGINAL GAME RESEARCH

Inspect the provided Jagged Alliance 2 source repository.

Study the original systems and their interactions.

Relevant directories include:

- `ja2/Build/Strategic/`
- `ja2/Build/Tactical/`
- `ja2/Build/TacticalAI/`
- `ja2/Build/TileEngine/`
- `ja2/Build/Laptop/`
- `ja2/Build/SaveLoadGame.c`

Relevant subjects include:

- Strategic map organisation.
- Strategic pathfinding.
- Game time and scheduled events.
- Tactical AP calculations.
- Terrain movement costs.
- Turns and interrupts.
- Soldier statistics.
- Visibility and perception.
- Inventory.
- Weapon calculations.
- Tactical AI.
- Squad management.
- Hiring and contracts.
- Healing and assignments.
- Town ownership.
- Militia.
- Income production.
- Enemy strategic movement.
- Campaign persistence.

Study actual rules and data relationships.

Do not approximate reference behaviour from memory when the source can answer the question.

## Mechanical classification

Classify systems as:

**PRESERVED**

The fundamental mechanic remains substantially the same.

Examples: AP accounting, grid movement, sector navigation, strategic clock, persistent character state.

**ADAPTED**

The purpose is retained but the mechanic must change for medieval warfare.

Examples: firearms to bows and melee weapons, modern armour to medieval protection, vehicles to horses and wagons.

**ORIGINAL**

A mechanic needed for this game's medieval setting.

Examples: shield blocking, melee engagement, weapon reach, medieval supplies and feudal allegiance.

**DEFERRED**

Nonessential mechanics that should not delay the integrated foundation.

Document these classifications in `MECHANICS_MAPPING.md`.

# 6. LICENSING AND INDEPENDENT IMPLEMENTATION

The reference repository includes the Strategy First Source Code License Agreement.

Its source-code licence restricts commercial use and derivative works.

Do not incorporate restricted original source code, copied source-derived tables, proprietary characters, original campaign content, maps or protected assets into a commercially intended build.

Treat the reference as a research and comparison resource.

Implement the new project independently using original code and original world content.

Document reference sources and any potential derivative material.

If direct source translation is used for non-commercial research, isolate and label it clearly; do not silently merge it into the original game's commercially intended implementation.

The eventual commercial product must undergo an appropriate rights review before release.

Do not assume that possession of the source repository gives unrestricted commercial rights.

# 7. GAME VISION

## Working Title: The Broken Marches

A fractured medieval kingdom has lost its central authority.

Rival noble houses, bandit groups, religious institutions, free cities and mercenary companies compete for control.

The player begins as the commander of a small mercenary company with limited funds, limited equipment and a handful of fighters.

The player must survive through contracts, tactical victories, strategic planning and careful financial management.

Over time, the company may grow in size, reputation and political influence.

The player can:

- Hire mercenaries.
- Negotiate employment contracts.
- Form squads.
- Equip troops.
- Purchase supplies.
- Travel through a persistent kingdom.
- Accept mercenary jobs.
- Attack or defend settlements.
- Capture strategic locations.
- Earn income from contracts and controlled facilities.
- Recover wounded troops.
- Train recruits.
- Establish garrisons.
- Fight rival factions.
- Develop the company into a significant military power.

The campaign must present genuine strategic trade-offs.

An expensive elite fighter should be a meaningful investment.

A wounded veteran should represent a serious loss of immediate combat capability.

A strategically valuable settlement should produce an ongoing benefit.

Enemy factions should continue operating regardless of the player's immediate actions.

# 8. SETTING AND LOW-FANTASY RULES

Use a grounded medieval setting.

Human military conflict is the primary focus.

The initial rules should use:

- Swords.
- Axes.
- Maces.
- Spears.
- Polearms.
- Bows.
- Crossbows.
- Shields.
- Padded armour.
- Mail.
- Plate.
- Horses and wagons.
- Medieval medical care.
- Smithing and repairs.
- Food, supplies and logistical support.

Do not introduce active spellcasting, magical weapons, monsters or supernatural combat systems in the first mechanical milestone.

Design for the possibility of rare low-fantasy elements later.

Do not build a conventional class-based fantasy RPG.

The game's character identity should emerge from individual skills, equipment, experience, injuries, backgrounds and behaviour.

# 9. CORE GAMEPLAY LOOP

The required gameplay loop is:

**Recruit → Equip → Accept Contract → Organise Squad → Travel → Encounter → Tactical Battle → Resolve → Recover → Get Paid → Upgrade → Repeat**

The world must remain persistent between cycles.

The player should experience both company-level decisions and individual tactical consequences.

## Essential integration

The following must not be isolated demonstrations:

- Mercenary hiring affects company finances.
- Equipment purchases affect actual inventory.
- Inventory affects tactical combat.
- Travel affects campaign time and supplies.
- Battle injuries affect strategic capability.
- Casualties affect squad membership.
- Territorial victory changes strategic ownership.
- Settlement ownership changes resources and income.
- Wages continue being charged through time.
- Healing requires time and appropriate care.
- Saves preserve all significant consequences.

Every major gameplay system must interact with the authoritative campaign state.

# 10. AUTHORITATIVE GAME STATE

Build a deterministic simulation architecture.

Do not couple game rules to rendered objects.

Define data models for:

- Campaign.
- Strategic sector.
- Settlement.
- Faction.
- Military group.
- Mercenary.
- Contract.
- Inventory.
- Item.
- Equipment.
- Wound.
- Assignment.
- Tactical map.
- Tactical unit.
- Combat encounter.
- Scheduled event.
- Financial transaction.

Use unique, stable entity identifiers.

Implement commands that modify state through explicit validated operations.

Examples:

- `HireMercenary`
- `AssignMercenary`
- `TransferItem`
- `SetSquadRoute`
- `AdvanceWorldTime`
- `EnterTacticalBattle`
- `SpendActionPoints`
- `ExecuteAttack`
- `ResolveBattle`
- `CaptureSector`
- `ProcessWages`
- `SaveCampaign`

Use a single source of truth.

Do not duplicate authoritative values in UI nodes.

Use seeded random-number generation for reproducible scenarios.

Prefer deterministic simulation outcomes given the same initial state, command sequence and random seed.

# 11. STRATEGIC WORLD

Implement a 16 × 16 sector-based strategic world.

This gives a full strategic grid of 256 sector positions.

Use original medieval world data rather than copying the original JA2 campaign geography.

Each sector must support:

- Coordinates.
- Terrain.
- Movement costs.
- Faction ownership.
- Current military presence.
- Known enemy presence.
- Discovery state.
- Settlement information.
- Facilities.
- Defensive strength.
- Roads and travel connections.
- Underground or additional levels if later required.
- Persistent local tactical state.

Relevant terrain types include:

- Farmland.
- Grassland.
- Forest.
- Dense forest.
- Hills.
- Mountains.
- Marsh.
- River crossing.
- Road.
- Village.
- Town.
- Castle.
- Mine.
- Ruins.
- Wilderness.

Do not require all 256 sectors to have individually authored tactical maps.

Build procedural or reusable tactical templates with support for unique authored sector maps later.

Strategic map geometry and data must remain independent of detailed tactical rendering.

# 12. STRATEGIC MAP INTERFACE

Build a working kingdom map interface.

The player must be able to:

- View the complete strategic grid.
- Pan and zoom.
- Select sectors.
- Inspect towns and facilities.
- Inspect known enemy forces.
- Select friendly squads.
- Plot travel routes.
- View estimated arrival times.
- Assign destinations.
- Inspect company supplies.
- Inspect ownership.
- View the campaign clock.
- Advance time.
- Access mercenary management.

Use rectangles, colours, symbols and text.

A sector selection must open genuine simulation data.

Travel markers must represent actual active movement groups.

The map must not be a static image.

# 13. STRATEGIC TIME AND EVENT SYSTEM

Implement one authoritative world clock.

Support:

- Pause.
- Normal time.
- Time acceleration.
- Scheduled events.
- Interrupting time compression when important events occur.

Events include:

- Squad arrivals.
- Mercenary wage payments.
- Contract deadlines.
- Contract expiration.
- Food consumption.
- Training progress.
- Healing progress.
- Equipment repairs.
- Resource production.
- Enemy group movements.
- Settlement attacks.
- Reinforcements.
- Faction actions.

Do not tie strategic time directly to rendering frame rate.

Large time advances must resolve events in the correct order.

Events must not fire twice or be skipped when time compression changes.

Implement deterministic tests for these cases.

# 14. MERCENARY PROFILES

Each mercenary must be an individually persistent character.

Use an appropriate stat model inspired by JA2's detailed mercenary attributes.

Include:

- Strength.
- Agility.
- Dexterity.
- Endurance.
- Perception.
- Wisdom.
- Leadership.
- Melee skill.
- Ranged skill.
- Medical skill.
- Mechanical or smithing skill.
- Experience.
- Morale.
- Fatigue.
- Current health.
- Maximum health.
- Current wounds.

Stats must influence gameplay calculations.

Do not create attributes that are displayed but never used.

## Backgrounds and traits

Implement a data-driven system for backgrounds.

Examples:

- Former soldier.
- Hunter.
- Deserter.
- Knight.
- Blacksmith.
- Physician.
- Poacher.
- Farmer.
- Mercenary veteran.

Backgrounds should influence starting stats, abilities or drawbacks.

Characters should develop through relevant experience.

Training should be possible without combat, but should be slower or otherwise differentiated from practical field experience.

# 15. RECRUITMENT AND CONTRACTS

Implement a working mercenary market.

Each recruit must have:

- Profile.
- Skills.
- Traits.
- Hiring fee.
- Wage.
- Contract duration.
- Equipment.
- Availability.
- Relationship or morale modifiers where relevant.

The player must be able to hire, dismiss and manage mercenaries.

Hiring deducts funds.

Wages are processed through strategic time.

Contract expiration must affect employment state.

The system must correctly handle insufficient money and expiring contracts.

## Contract Board

Implement mercenary jobs.

Initial contract types:

- Bandit elimination.
- Caravan escort.
- Settlement defence.
- Patrol.
- Hostile camp assault.
- Strategic location capture.

Contracts should contain actual objectives, deadlines, payments and success/failure conditions.

Mission rewards must be based on the campaign state, not fake completion buttons.

# 16. SQUADS AND COMPANY ORGANISATION

Allow units to be grouped into squads.

Each squad has:

- Unique ID.
- Members.
- Leader.
- Current sector.
- Current assignment.
- Destination.
- Active route.
- Supplies.
- Travel status.
- Encounter status.

Support splitting and merging squads.

Preserve individual mercenary state during transfers.

The company may eventually operate multiple squads across different sectors.

The world simulation must continue for squads not currently controlled tactically.

# 17. TRAVEL AND LOGISTICS

Build proper strategic pathfinding.

Travel time must be influenced by:

- Terrain.
- Roads.
- Squad composition.
- Fatigue.
- Injuries.
- Encumbrance.
- Transport.
- Supplies.
- Relevant conditions.

Support foot travel initially.

Architect mounted and wagon travel so they can be added without rewriting movement.

## Supplies

Implement meaningful basic logistics:

- Food.
- Provisions.
- Equipment weight.
- Carrying capacity.
- Consumption over time.

Supplies should be consumed through the world clock.

Supply shortages must have actual consequences.

Avoid excessive bookkeeping that does not create meaningful strategic decisions.

# 18. ECONOMY AND SETTLEMENTS

Build a functioning campaign economy.

Track:

- Company funds.
- Recruitment payments.
- Mercenary wages.
- Contract income.
- Equipment purchases.
- Repairs.
- Supplies.
- Income from controlled resources.

Maintain a financial transaction ledger.

## Settlements

Support:

- Ownership.
- Population or workforce abstraction.
- Loyalty.
- Public order.
- Defensive strength.
- Resource production.
- Facilities.
- Strategic importance.

## Facilities

Implement meaningful categories:

- Farms.
- Mines.
- Workshops.
- Markets.
- Garrisons.
- Training facilities.

Facilities should have actual effects.

For example:

- Farms produce food.
- Mines produce income or resources.
- Workshops repair equipment.
- Markets allow purchasing.
- Garrisons protect territory.

Facility output should depend on relevant conditions where applicable.

# 19. FACTIONS AND STRATEGIC AI

Implement a persistent faction system.

Initial faction types may include:

- Royalist forces.
- Rival noble houses.
- Bandit coalitions.
- Independent settlements.
- Mercenary companies.

Each faction should store:

- Controlled territory.
- Military forces.
- Resources.
- Relationships.
- Strategic objectives.
- Active movement groups.
- Relevant intelligence.

Strategic AI must be able to:

- Move forces.
- Patrol.
- Attack sectors.
- Defend settlements.
- Reinforce threatened territory.
- React to losses.
- Contest strategic resources.

Enemy military groups must exist in the strategic world.

Do not spawn enemy armies arbitrarily without a documented simulation reason.

Implement a meaningful but bounded decision model before attempting elaborate diplomacy.

# 20. GARRISONS AND MILITIA

Translate JA2's militia and town-control mechanics into medieval levies and garrisons.

Implement:

- Levy recruitment.
- Training.
- Garrison assignments.
- Garrison wages or upkeep.
- Sector defence.
- Casualties.
- Improvement in training level.
- Defensive battle participation.

Garrisons must exist as persistent strategic entities.

They must not disappear when the player leaves the sector.

# 21. TACTICAL WORLD STRUCTURE

Build a scalable tactical grid.

Support the reference's standard 160 × 160 tactical grid dimensions.

Allow smaller maps for tests and initial encounters.

Do not create one heavyweight Godot node for every tile.

Use efficient data structures for terrain and occupancy.

Use meshes, instancing or chunked visualisation for presentation.

Support:

- Ground tiles.
- Traversable terrain.
- Blocked terrain.
- Elevation.
- Walls.
- Doors.
- Windows.
- Buildings.
- Roofs.
- Trees.
- Rocks.
- Barricades.
- Fortifications.
- Ground items.
- Entry points.
- Exit points.

Separate logical obstacles from their primitive visual representations.

# 22. ISOMETRIC CAMERA

Use an orthographic three-quarter tactical camera.

Requirements:

- Pan across battlefield.
- Pinch-to-zoom.
- Select units.
- Tap target tiles.
- Show relevant grid information.
- Hide or fade roofs when necessary.
- Keep selected units visible.
- Preserve spatial clarity.

Use a fixed tactical orientation initially.

Camera rotation is optional and should not complicate coordinate selection or pathfinding.

The camera must not determine tactical rules.

# 23. TACTICAL MOVEMENT

Implement grid-based movement and pathfinding.

Movement calculations must account for:

- Terrain costs.
- Movement mode.
- Stance.
- Elevation.
- Obstacles.
- Doors.
- Friendly occupancy.
- Enemy occupancy.
- Diagonal movement.
- Action-point budget.

The same rules must control movement previews and actual execution.

The player must see:

- Legal destinations.
- Unreachable destinations.
- Planned path.
- AP cost.
- Remaining AP after movement.

Invalid movement must be rejected.

Units must never pass through impassable structures or teleport between disconnected locations.

# 24. ACTION POINT SYSTEM

Reconstruct the fundamental JA2 action-point model.

Research the original AP calculations in the source.

Preserve the concept of variable AP based on individual abilities and condition.

The medieval adaptation must include appropriate AP costs for:

- Walking.
- Running.
- Cautious movement.
- Turning.
- Changing stance.
- Drawing weapons.
- Switching equipment.
- Melee attacks.
- Aimed ranged attacks.
- Reloading bows or crossbows.
- Opening doors.
- Climbing.
- Medical actions.
- Interacting with objects.

AP must be calculated using actual gameplay data.

Relevant modifiers include:

- Character abilities.
- Fatigue.
- Injuries.
- Equipment.
- Encumbrance.
- Terrain.
- Current stance.
- Other relevant conditions.

Where the original mechanic is retained, verify its rules against the source.

Where medieval warfare requires different rules, define and document a coherent replacement.

Prevent negative AP, illegal commands and inconsistent previews.

# 25. TACTICAL TURN SYSTEM

Implement a robust turn-based tactical state machine.

Support:

- Combat initiation.
- Team turns.
- Unit activation.
- Action execution.
- End turn.
- AI turns.
- Turn transitions.
- Interrupts or reaction opportunities.
- Victory.
- Defeat.
- Retreat.

Research JA2's transition between real-time exploration and turn-based combat.

Preserve this design philosophy where practical.

Do not assume a tactical map needs to be permanently locked in turn-based combat.

Outside combat, appropriate continuous or command-based movement may be used.

Entering combat must establish a valid turn state.

The system must not deadlock when units die or become incapacitated during a turn.

# 26. MELEE COMBAT

Build a detailed melee combat model appropriate for grounded medieval warfare.

This is a major new system and must receive substantial engineering attention.

## Weapon categories

Support:

- Unarmed.
- Daggers.
- One-handed swords.
- Axes.
- Maces.
- Spears.
- Polearms.
- Two-handed weapons.

## Weapon properties

Each weapon must have mechanically meaningful data:

- Damage.
- Damage type.
- Reach.
- Weight.
- AP cost.
- Attack accuracy.
- Defensive utility.
- Armour effectiveness.
- Durability.

## Combat calculations

Include relevant:

- Attacker skill.
- Defender skill.
- Weapon properties.
- Relative facing.
- Stance.
- Reach.
- Fatigue.
- Injury.
- Shield use.
- Positioning.
- Flanking.
- Terrain modifiers.

## Defence

Implement:

- Dodge.
- Parry.
- Block.
- Shield defence.
- Armour mitigation.

Defensive actions must have explicit eligibility and costs.

The system must prevent impossible defensive responses.

## Tactical positioning

Implement:

- Weapon reach.
- Adjacent engagement.
- Facing.
- Flanking.
- Rear attacks.
- Disengagement.
- Reaction attacks.
- Multiple-attacker pressure.

Design the system so positioning creates meaningful advantages.

Do not reduce medieval melee combat to two adjacent units repeatedly exchanging generic damage.

Use explicit formulas and deterministic tests.

# 27. RANGED COMBAT

Build a medieval ranged combat system.

Support:

- Bows.
- Crossbows.
- Javelins.
- Throwing weapons.

Relevant properties include:

- Effective range.
- Maximum range.
- Accuracy.
- Aim time.
- Ammunition.
- Reload behaviour.
- Projectile characteristics.
- Damage type.
- Armour interaction.

Aiming must affect resolution.

Range and target conditions must matter.

Crossbows must behave differently from bows.

Line of sight and environmental obstacles must be respected.

The displayed hit probability must match the actual calculation used for attack resolution.

Prevent firing without the necessary ammunition or AP.

# 28. ARMOUR, DAMAGE AND WOUNDS

Implement medieval armour categories:

- Clothing.
- Padded armour.
- Leather components.
- Mail.
- Plate.
- Helmets.
- Shields.

Damage categories:

- Cutting.
- Piercing.
- Blunt.
- Projectile.

Different armour must provide different protection against relevant damage types.

Support body locations where mechanically appropriate:

- Head.
- Torso.
- Arms.
- Legs.

## Injury

Implement:

- Health loss.
- Bleeding.
- Wound severity.
- Injury penalties.
- Incapacitation.
- Death.
- First aid.
- Long-term recovery.

Wounds must affect tactical performance.

Wounds must persist after combat.

Medical skill, supplies and time should influence recovery.

Experienced units must not return to full strength automatically at battle completion.

# 29. FATIGUE AND MORALE

Implement meaningful soldier condition systems.

Fatigue should reflect exertion, travel, combat and rest.

Morale should respond to events such as:

- Taking damage.
- Nearby casualties.
- Being surrounded.
- Fighting superior forces.
- Losing a leader.
- Successful attacks.
- Tactical advantage.
- Withdrawal.
- Defeat or victory.

Possible morale states:

- Confident.
- Stable.
- Shaken.
- Frightened.
- Panicked.
- Broken.

States must have actual mechanical consequences.

Do not add random status effects without explainable triggers.

Morale and fatigue must be visible in the developer inspector.

# 30. LINE OF SIGHT AND PERCEPTION

Implement a proper tactical perception system.

Include:

- Unit facing.
- Visibility range.
- Stance.
- Obstacles.
- Trees and vegetation.
- Windows.
- Walls.
- Elevation.
- Lighting where relevant.
- Cover and concealment.
- Sound detection.
- Last-known enemy positions.
- Shared information.
- Fog of war.

Maintain separate:

**Actual world state**

and

**Knowledge available to a specific unit or faction.**

Tactical AI must not access information unavailable through its legitimate perception model.

Implement debug overlays for sight lines, vision ranges and awareness states.

# 31. COVER AND TERRAIN ADVANTAGE

Implement a tactical cover model.

Cover must influence visibility, exposure or attack resolution where relevant.

Support distinctions such as:

- No cover.
- Partial cover.
- Strong cover.
- Concealment.
- Elevated position.
- Defensive obstacle.

Cover values must derive from map geometry and logical structures.

Changing a stance should alter exposure when appropriate.

Units should benefit from legitimate defensive positioning.

The game must distinguish between being unseen and being protected by an obstacle.

# 32. TACTICAL AI

Build functional tactical AI inspired by JA2's layered decision-making.

Enemy units must be able to:

- Patrol.
- Guard.
- Investigate sounds.
- Detect threats.
- Remember last-known positions.
- Seek cover.
- Reposition.
- Choose targets.
- Select melee or ranged attacks.
- Reload.
- Retreat.
- Defend allies.
- Use terrain.
- Exploit flanking.
- Respond to morale.
- Respond to injuries.

All actions must obey the same tactical rules as the player's units.

The AI must use the actual AP and movement systems.

Do not grant the AI unlimited AP or unrestricted targeting knowledge.

## Group behaviour

Support coordinated tactical concepts:

- Spearmen holding defensive positions.
- Shielded fighters protecting archers.
- Ranged units maintaining distance.
- Melee units closing with enemies.
- Defenders protecting doors.
- Units responding to allied distress.

Implement a debug inspector showing why an AI action was selected.

Do not depend exclusively on scripted, hardcoded scenarios.

# 33. INVENTORY AND EQUIPMENT

Build a persistent item system.

Support:

- Main-hand equipment.
- Off-hand equipment.
- Shields.
- Head protection.
- Body armour.
- Carried weapons.
- Ammunition.
- Medical supplies.
- Tools.
- Food.
- Miscellaneous inventory.
- Ground items.
- Looting.
- Item transfers.
- Encumbrance.
- Item condition.

Every item must exist as actual simulation data.

A unit's inventory must remain consistent through:

- Recruitment.
- Strategic travel.
- Tactical deployment.
- Combat.
- Looting.
- Returning to the world map.
- Saving and loading.

Provide simple functional inventory panels.

# 34. MEDICAL, REPAIR AND TRAINING ASSIGNMENTS

Support strategic assignments:

- Rest.
- Medical treatment.
- Training.
- Equipment repair.
- Guard duty.
- Garrison training.
- Scouting.

Assignments must consume world time.

Character skills should influence results.

Medical assignments should require suitable resources or facilities.

Equipment repairs should be constrained by condition, time and available resources.

Training should improve relevant skills according to documented progression rules.

# 35. STRATEGIC–TACTICAL INTEGRATION

This requirement is essential.

The tactical layer and strategic layer must not behave like separate games.

All persistent entities must use shared authoritative state.

## Required integrated gameplay sequence

The player must be able to:

1. Start a campaign.
2. Receive starting money and a small company.
3. Inspect available mercenaries.
4. Recruit fighters.
5. Purchase equipment.
6. Equip units.
7. Form a squad.
8. Accept a contract.
9. Select a strategic destination.
10. Plot travel.
11. Advance time.
12. Consume provisions.
13. Arrive at a hostile sector.
14. Trigger a tactical encounter.
15. Deploy the correct squad.
16. Move through the tactical environment.
17. Use appropriate AP.
18. Fight using melee and ranged combat.
19. Encounter legitimate tactical AI.
20. Win, lose or retreat.
21. Apply injuries and casualties.
22. Update inventory and ammunition.
23. Return to the strategic map.
24. Resolve contract rewards.
25. Apply sector control changes.
26. Process recovery assignments.
27. Pay wages.
28. Continue campaigning.
29. Save progress.
30. Reload the campaign.
31. Resume with consistent world and mercenary state.

No essential step may use a fake result or hardcoded success screen.

All transitions must operate through actual implemented systems.

# 36. MOBILE-FIRST CONTROLS

Every essential gameplay action must be possible on an Android touchscreen.

Do not require:

- Keyboard shortcuts.
- Right-click.
- Mouse hover.
- Mouse wheel.
- Precision pointer movements.
- Simultaneous complex gestures.

Design controls specifically for touchscreens.

## Tactical interaction

Implement:

- Tap to select.
- Tap destination to preview movement.
- Confirm movement where appropriate.
- Tap enemy to inspect or target.
- Contextual attack controls.
- Clear AP previews.
- Tap-to-open action menus.
- Stance controls.
- Inventory access.
- End-turn control.
- Drag to pan.
- Pinch to zoom.
- Ability to cancel an action without accidentally executing it.

Long-press interactions may reveal additional information, but essential controls must remain discoverable.

## Strategic interaction

Implement:

- Tap to select sector.
- Tap to inspect squad.
- Touch-based route plotting.
- Pinch-to-zoom and drag-to-pan.
- Accessible time controls.
- Clear alerts.
- Functional squad and mercenary panels.

## Touch feedback

Show selected units, valid targets, movement previews and contextual actions.

Avoid actions being accidentally triggered when the player intends to pan or inspect.

Do not simplify the underlying mechanics merely to reduce the UI complexity.

**Simplify interaction, not simulation.**

# 37. MOBILE USER INTERFACE

Use Godot Control nodes for UI.

Design for landscape phone screens.

Ensure:

- Readable text.
- Large enough touch targets.
- Safe-area support.
- Scalable layouts.
- Expandable panels.
- Functional scrolling.
- Appropriate modal behaviour.
- No hover-only information.
- Clear confirmation for destructive decisions.
- Good visibility of the battlefield.

The player should not need to read the entire character sheet during normal combat.

Use progressive disclosure.

Show essential information first.

Detailed statistics should remain available in expandable panels.

## Required screens

- Main menu.
- New campaign.
- Load campaign.
- Strategic map.
- Mercenary management.
- Contracts.
- Inventory.
- Company finances.
- Tactical battlefield.
- Tactical inventory.
- Pause/settings.
- Battle results.
- Developer inspector.

All displayed controls must function.

# 38. SAVE SYSTEM AND MOBILE INTERRUPTION

Implement versioned campaign saves.

Save relevant state including:

- World clock.
- Faction state.
- Sector ownership.
- Mercenary profiles.
- Health and injuries.
- Inventory.
- Money.
- Contracts.
- Supplies.
- Squads.
- Assignments.
- Active strategic movement.
- Active events.
- Facility production.
- Campaign progress.
- Random generator state when required for deterministic resumption.

Support manual save and load.

Support automatic saving at safe boundaries.

Handle Android pause and resume correctly.

Do not corrupt a save when the application is interrupted during a write.

Prefer atomic or recoverable save operations.

Include save migration support for future schema changes.

Test loading saved data from actual gameplay states.

# 39. ANDROID PERFORMANCE

Target mainstream Android phones.

Aim for responsive performance and preferably 60 FPS under normal gameplay conditions.

Use an acceptable lower-performance profile if necessary.

Performance must be measured rather than assumed.

## Tactical optimisation

Use:

- Lightweight tile data.
- Efficient occupancy structures.
- Batched or instanced geometry.
- Limited active simulation updates.
- Cached or incrementally updated pathfinding data.
- Controlled AI decision frequency.
- Appropriate object pooling.
- Efficient visibility calculations.

Do not create thousands of unnecessary physics bodies.

Only the active tactical environment should require detailed rendering.

The strategic simulation should be able to progress without rendering tactical sectors.

Aim for reliable frame pacing and responsive touch interaction.

Do not claim Android performance has been verified without actual device measurements.

# 40. TESTING FRAMEWORK

Build a comprehensive automated test suite.

Tests must verify gameplay rules and state changes, not just code compilation.

Use deterministic fixtures.

## Tactical tests

Verify:

- AP generation.
- AP expenditure.
- Movement legality.
- Terrain movement.
- Pathfinding.
- Door interaction.
- Elevation.
- Melee reach.
- Flanking.
- Shield blocking.
- Armour mitigation.
- Ranged accuracy.
- Ammunition consumption.
- Damage.
- Wounds.
- Bleeding.
- Morale.
- Fatigue.
- Turn progression.
- AI action legality.
- Visibility and fog of war.

## Strategic tests

Verify:

- Sector data.
- Squad creation.
- Squad splitting.
- Strategic routing.
- Arrival times.
- Wage calculation.
- Contract expiration.
- Supply consumption.
- Healing.
- Training.
- Repair.
- Resource production.
- Faction movement.
- Encounter creation.
- Territory changes.

## Integration tests

Verify:

- Hiring affects money and roster.
- Equipping affects tactical loadout.
- Battle losses persist.
- Injuries persist.
- Used items remain consumed.
- Sector victories affect the world map.
- Strategic time advances correctly.
- Campaign saves preserve relevant state.

Use explicit expected results.

Where rules are adapted from JA2, cite the reference mechanic in development documentation.

Where rules are original, document formulas and edge cases.

# 41. AUTOMATED GAMEPLAY SCENARIOS

Build a scenario runner.

Required scenarios:

**1. Tactical Movement Test**

Mercenary traverses mixed terrain and changes stance.

Verify route and AP.

**2. Melee Combat Test**

Sword-and-shield fighter engages a spearman.

Verify weapon reach, AP, defence and damage.

**3. Ranged Combat Test**

Archer engages enemies at different distances and elevations.

Verify accuracy, visibility, ammunition and armour.

**4. Defence Test**

A group defends a building.

Verify walls, doors, cover, AI movement and line of sight.

**5. Contract Test**

Player hires troops, accepts a contract, travels, fights and receives payment.

**6. Logistics Test**

A squad travels for several days.

Verify wages, supplies, fatigue and recovery.

**7. Faction War Test**

Rival factions move military forces and contest sectors.

Verify strategic AI and ownership.

**8. Persistent Campaign Test**

Player completes multiple battles, captures territory and maintains an active company.

Verify continuity.

**9. Save/Load Test**

Save during strategic progression and reload.

Verify equivalent game state.

**10. Extended Simulation Test**

Advance the strategic simulation through a long sequence of events.

Detect duplicate events, invalid states, resource accounting errors and AI failures.

Each test should produce structured pass/fail results.

# 42. DEBUG AND DEVELOPER TOOLS

Create a functional development overlay.

Include:

- Selected entity inspector.
- Character stat inspector.
- AP calculation display.
- Movement cost breakdown.
- Combat hit calculation.
- Armour and damage breakdown.
- Tactical AI state.
- Last-known enemy positions.
- Strategic faction activity.
- Event queue.
- World time.
- Active contracts.
- Inventory state.
- Random seed.
- Save state inspection.

Allow launching predefined test scenarios.

Support overlays for:

- Tactical grid.
- Pathfinding.
- Reachable tiles.
- LOS.
- Cover.
- AI targets.
- Tile occupancy.
- Strategic routes.

Developer tools may be included in debug builds and disabled in release configurations.

These tools are part of the required deliverable.

# 43. ANDROID BUILD PIPELINE

Configure repeatable Android builds.

Prefer GitHub Actions or equivalent CI where repository permissions permit.

The pipeline should:

1. Check out the project.
2. Install the chosen Godot version.
3. Install matching export templates.
4. Import project resources.
5. Run script and scene validation.
6. Run available automated tests.
7. Export an Android debug APK.
8. Verify the APK package.
9. Upload the APK as a build artifact.

Do not upload a successful artifact if mandatory tests have failed.

Where an Android test device or emulator is available, perform installation and smoke testing.

If only local Godot testing is available, report device verification as outstanding.

Do not require a release signing key for ordinary debug builds.

Do not publish to Google Play without explicit authorisation.

# 44. DEVELOPMENT EXECUTION ORDER

Follow the implementation stages below.

## Stage 0 — Repository and source analysis

Inspect the JA2 source.

Confirm licensing boundaries.

Create a separate Godot project.

Identify the mechanical reference systems.

Produce a concise source audit.

## Stage 1 — Simulation core

Implement:

- Game state.
- Data models.
- Command system.
- Event queue.
- Random seed control.
- Save architecture.
- Deterministic tests.

## Stage 2 — Tactical foundation

Implement:

- Tactical grid.
- Isometric camera.
- Unit placement.
- Movement.
- Pathfinding.
- AP.
- Turns.
- Unit selection.
- Basic primitive UI.

## Stage 3 — Medieval combat

Implement:

- Weapons.
- Melee attacks.
- Reach.
- Defence.
- Shields.
- Ranged attacks.
- Ammunition.
- Armour.
- Wounds.

## Stage 4 — Tactical AI

Implement:

- Perception.
- Visibility.
- Target selection.
- Movement decisions.
- Attacks.
- Cover.
- Retreat.
- Coordinated behaviour.

## Stage 5 — Strategic world

Implement:

- Sector map.
- World time.
- Squads.
- Movement.
- Recruitment.
- Contracts.
- Supplies.
- Finances.

## Stage 6 — Strategic-to-tactical integration

Implement:

- Encounter generation.
- Tactical deployment.
- Battle completion.
- Persistent casualties.
- World state changes.
- Campaign continuation.

## Stage 7 — Strategic depth

Implement:

- Factions.
- Strategic AI.
- Towns.
- Resource production.
- Militia.
- Garrisons.
- Training.
- Healing.
- Repairs.
- Morale.
- Experience.

## Stage 8 — Mobile interface

Complete and test all essential touchscreen workflows.

Mobile usability must also be considered throughout earlier implementation, not only in this stage.

## Stage 9 — Testing and repair

Run all mechanical tests and full campaign scenarios.

Correct failed tests and gameplay blockers.

## Stage 10 — Android delivery

Build, inspect and deliver a debug APK and complete source project.

Do not stop after Stage 0 or the first successfully launched scene.

# 45. PROGRESSIVE ACCEPTANCE GATES

Use explicit acceptance gates.

## Gate A — Systems exist

Data structures, services and interfaces are implemented.

This does not mean the features work.

## Gate B — Systems are individually verified

Unit tests establish expected calculations and behaviour.

## Gate C — Systems are integrated

Strategic and tactical behaviour correctly modify shared game state.

## Gate D — Game is playable

A complete contract-based campaign loop works through normal user interaction.

## Gate E — Mobile is functional

Core gameplay operates through touchscreen controls and an Android build has been produced.

## Gate F — Foundation is complete

Mandatory mechanical systems pass relevant tests.

A feature cannot be marked complete merely because code or a menu exists.

Use the actual verified state.

# 46. AVOID FALSE COMPLETION

The following are unacceptable:

- Decorative maps with no strategic simulation.
- Tactical units that move without real pathfinding.
- Fake AP values.
- Enemy AI that uses omniscient information.
- Equipment that does not alter combat.
- Contracts that cannot fail.
- Battles whose outcomes do not affect the campaign.
- Static inventory lists.
- Hardcoded victory screens.
- Wages that do not deduct funds.
- Resource production that does not use the world clock.
- Saves that omit important state.
- Android UI requiring keyboard input.
- Automated tests that only confirm classes instantiate.
- Passing build checks presented as proof of mobile playability.

Do not introduce decorative complexity as a substitute for genuine systems.

# 47. PROJECT DOCUMENTATION

Maintain the following files:

**AGENTS.md**

Permanent engineering rules, development standards and autonomous execution instructions.

**SOURCE_AUDIT.md**

Reference architecture, relevant functions and source findings.

**GAME_SPEC.md**

Authoritative design of the medieval game.

**MECHANICS_MAPPING.md**

Relationship between JA2 mechanics and medieval replacements.

**MECHANICS_PARITY.md**

Verified fidelity for preserved systems and documented differences.

**IMPLEMENTATION_PLAN.md**

Ordered implementation tasks and acceptance criteria.

**TEST_SCENARIOS.md**

Scenario definitions and expected results.

**BUILD_STATUS.md**

Verified implementation progress, known issues and current build state.

**QA_REPORT.md**

Test results, coverage and limitations.

**LEGAL_PROVENANCE.md**

Reference material, source licensing and reused-material declarations.

Update these files as work progresses.

Use them to preserve continuity if execution is interrupted.

# 48. AUTONOMOUS WORKING RULES

You are authorised to make normal technical decisions.

Do not request approval for:

- Architecture.
- Data structures.
- Algorithms.
- File organisation.
- Test tooling.
- Primitive geometry.
- Debug UI layout.
- Internal refactoring.
- Routine implementation details.

When a decision materially changes gameplay, choose the option most consistent with the specification and document it.

Do not ask for user intervention unless a genuine external blocker requires it.

You must not:

- Delete unrelated work.
- Force-push existing branches.
- Expose secrets.
- Incur paid service costs.
- Publish the game commercially.
- Bypass repository or tool permissions.

Make recoverable commits.

Do not depend on one uninterrupted execution context.

If the session is interrupted or a limit is reached, leave the exact state and next steps in the project documents.

# 49. REQUIRED WORKING STYLE

Use the following continuous engineering cycle:

**Inspect → Design → Implement → Run → Test → Diagnose → Repair → Retest → Commit → Continue**

Do not implement massive groups of unrelated systems without verification.

Integrate features as they are completed.

Prioritise getting one complete gameplay path working before expanding every optional mechanic.

Once the central loop works, systematically deepen the mechanics.

Avoid stopping to produce extensive speculative design documents.

Documentation exists to make execution more accurate, not to replace implementation.

Do not claim success without observed evidence.

# 50. DEFINITION OF DONE

The mechanically complete foundation must allow the player to:

- Start a new medieval campaign.
- Inspect an interactive 16 × 16 strategic map.
- Recruit mercenaries.
- View individual skills and statistics.
- Organise squads.
- Purchase and equip weapons and armour.
- Accept contracts.
- Assign strategic travel.
- Consume supplies.
- Advance time.
- Trigger tactical engagements.
- Deploy units.
- Move using real AP and pathfinding calculations.
- Fight in melee.
- Use bows and crossbows.
- Use shields and armour.
- Exploit terrain, cover and elevation.
- Engage functioning tactical AI.
- Experience morale and fatigue.
- Suffer persistent wounds and casualties.
- Return from battle.
- Earn contractual payment.
- Capture or defend sectors.
- Experience independently operating factions.
- Receive income from strategic resources.
- Train and recover soldiers.
- Pay wages.
- Continue campaigning.
- Save and reload progress.
- Play through a functional Android touch interface.
- Run automated mechanical and gameplay tests.

All mandatory Priority 0 and Priority 1 systems must pass their documented acceptance criteria before the full foundation is declared complete.

Optional mechanics must be clearly identified if they remain unfinished.

# 51. FINAL DELIVERABLES

Deliver:

1. A complete Godot source project.
2. A functional strategic campaign layer.
3. A functional tactical combat layer.
4. A working medieval mercenary management system.
5. Persistent campaign progression.
6. Functional tactical and strategic AI.
7. Primitive but usable game interfaces.
8. Complete mobile touch controls for the implemented features.
9. Automated mechanical and integration tests.
10. A repeatable Android build pipeline.
11. A verified Android APK where tooling permits.
12. A project handover.
13. A clear list of any outstanding functionality or verification limitations.

The result should be ready for future content and artwork production without requiring the core game to be rebuilt.

# 52. FINAL EXECUTION DIRECTIVE

Begin immediately.

Inspect the Jagged Alliance 2 source repository.

Understand the original mechanics and the dependencies between them.

Use those findings to implement an original, low-fantasy medieval mercenary strategy RPG in Godot.

Target Android phones from the beginning.

Use landscape-oriented, touch-first interaction.

Use primitive 3D geometry and plain functional UI.

Do not spend time on assets, skins, textures, animation or visual polish.

Concentrate on:

- Mechanical depth.
- Correct calculations.
- Strategic simulation.
- Tactical combat.
- Interconnected systems.
- Reliable AI.
- Persistent state.
- Automated testing.
- Android playability.

Do not stop at planning.

Do not stop at a working combat scene.

Do not stop at a strategic map.

Do not stop at a successful APK export.

Continue implementing and verifying the required systems as far as the available execution environment permits.

If interrupted, preserve all work and document the exact continuation point.

**YOUR DELIVERABLE IS A REAL, PLAYABLE MEDIEVAL MERCENARY STRATEGY RPG FOUNDATION.**

**IT SHOULD FUNCTION LIKE A DEEP STRATEGY GAME EVEN WHILE IT LOOKS LIKE A COLLECTION OF COLOURED BOXES.**