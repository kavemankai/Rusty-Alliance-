# CODEX IMPLEMENTATION — THE BROKEN MARCHES: GREYWAKE OPENING EXPERIENCE v0.1

You are the lead Godot developer for **The Broken Marches — The Fall of Greywake**.

**Repository:** https://github.com/kavemankai/Rusty-Alliance-.git  
**Engine:** Godot 4.6.2  
**Language:** GDScript  
**Platform priority:** Windows desktop, keyboard and mouse  
**Secondary target:** Android compatibility  
**Milestone:** Greywake Opening Experience v0.1

## Mission

Transform the existing functional Greywake recruitment-and-shipping build into a cohesive, playable opening campaign experience.

The player must be able to:

1. Start a new Greywake campaign from the title screen.
2. Experience the mysterious employer's contract briefing.
3. Recruit a starting mercenary company through an illustrated interactive tavern.
4. Inspect real character statistics, backgrounds, equipment, hiring costs and wages.
5. Confirm a company of two to six mercenaries.
6. Watch a short boat-crossing cinematic.
7. Arrive on Greywake's handcrafted, gridless island map.
8. Receive the introductory **Dockside Trouble** contract.
9. Enter an actual tactical battle against dockside bandits.
10. Complete or lose the encounter with persistent consequences.
11. Return to the island map, with normal company management and mainland recruitment available.

**This must be implemented in the actual game, not as a mockup or separate prototype.**

Preserve existing working systems and add only the minimum new functionality necessary.

---

## PHASE 0 — Mandatory repository audit

Before modifying anything, read the following files in full:

- `AGENTS.md`
- `README.md`
- `BUILD_STATUS.md`
- `GREYWAKE_RECRUITMENT_STATUS.md`
- `GREYWAKE_RECRUITMENT_SHIPPING_SPEC.md`
- `GREYWAKE_SKILLS.md`
- `GREYWAKE_QA.md`
- `ASSET_COVERAGE.md`
- `ASSET_QA.md`
- `data/greywake_roster.json`
- `data/greywake_scenario.json`
- `sim/campaign.gd`
- `sim/recruitment.gd`
- `sim/greywake_shipping.gd`
- `sim/contracts.gd`
- `sim/battlefields.gd`
- `ui/main.gd`
- `ui/world_map.gd`
- `ui/battle_view.gd`
- Relevant tests, save-validation code and export configuration.

Review the latest repository state. The previous inspection identified build `0.14.0-greywake-recruitment`, but newer changes may exist.

Establish exactly what is implemented before starting. Run the existing baseline tests and record the results.

**Do not rebuild systems that already work.** Preserve the original campaign and all existing save compatibility.

---

## PHASE 1 — Opening flow controller

Implement a reliable, persistent opening sequence with these states:

```text
TITLE_SCREEN
     ↓
EMPLOYER_BRIEFING
     ↓
TAVERN_RECRUITMENT
     ↓
COMPANY_CONFIRMATION
     ↓
BOAT_CROSSING
     ↓
GREYWAKE_ARRIVAL
     ↓
DOCKSIDE_CONTRACT
     ↓
FIRST_TACTICAL_ENCOUNTER
     ↓
GREYWAKE_CAMPAIGN
```

Use a clearly defined state machine or equivalent architecture.

The visual sequence should use short fade-to-black and fade-in transitions. Avoid excessive transition durations or unnecessary loading screens.

Allow normal saving and loading where appropriate. The player must not lose selected recruits, spend money twice or replay completed opening transactions after loading.

Cinematic presentation state must not become a second authority for simulation data.

### Title screen

Display:

**THE BROKEN MARCHES**  
*The Fall of Greywake*

Buttons: New Game, Continue, Settings and Exit.

If the existing title screen supports the original campaign, preserve that access. The Greywake campaign must remain a separately selectable scenario.

Use the approved Greywake title illustration where available.

---

## PHASE 2 — The hooded employer

### Scene composition

First-person viewpoint, seated at a wooden tavern table. A mysterious hooded figure sits opposite the player.

Visual elements: face mostly concealed; candlelight; tankard; pouch of coins; dark medieval tavern interior; subtle ambient effects; dialogue panel along the bottom.

Keep this mostly static. No full character animation system is required.

### Important narrative rules

The player's contract has **already been accepted**. Do not ask the player whether they accept the job.

The employer is anonymous and unknowable.

Do not create a secret identity reveal, hidden mastermind, later betrayal, investigation into the employer, fourth political route or additional employer quests.

The employer exists only to establish the premise and starting resources.

### Dialogue

Implement the briefing through a data-driven dialogue sequence. Use this draft as the starting text:

**The Stranger:**

> Greywake Isle. Baron Edric Vane.
>
> He is to be removed from power.
>
> How you accomplish that is your concern.
>
> The island has suffered under his rule for years. There are those who would see its rightful heir restored, others who would see Vane buried, and others still who would tear his government apart.
>
> You will have two thousand four hundred crowns to assemble your company.
>
> Your passage is arranged. A vessel departs before dawn.
>
> Choose your people carefully. You will have little help once you reach Greywake.

The player advances the text and the scene transitions to the recruitment tavern.

Do not impose a new hard campaign deadline based on this dialogue. Preserve the established political history and three possible overthrow routes.

---

## PHASE 3 — Interactive tavern recruitment

This is the most important presentation feature of the milestone.

### Design

Create an illustrated, fixed-camera medieval tavern. The tavern contains several visually distinct groups of potential recruits.

Required vignettes:

- **Peasant table:** Several inexpensive fighters drinking, laughing and behaving boisterously.
- **Lone heavily armoured mercenary:** A powerful knight-type professional sitting alone with a drink.
- **Professional mercenary table:** Two experienced fighters talking, laughing or playing cards.
- **Tavern fistfight:** A capable mercenary brawling with another fighter.
- **Additional characters:** Place remaining candidates naturally throughout the tavern: near the hearth, by the window, beside the bar, watching the room, or tending to another patron.

The tavern is a **single interactive tableau**, not a fully simulated 3D environment.

Use visual hotspots over actual individual recruits or clear recruit groups. Clicking a candidate opens their profile. Hovering over an available recruit should provide a readable desktop indication. Avoid overcrowding the scene.

### Authoritative roster

Use the actual data from `data/greywake_roster.json`.

The previous approved roster contained:

- **Cheap:** Militia Spearman; Militia Crossbowman.
- **Mid:** Mara; Oswin; Ada; Bram.
- **High:** Elin; Nessa; Garran; Sabine.
- **Elite:** Roderic; Ysra.

Re-read the current data before implementation. If the authoritative roster has changed, follow the current approved repository data.

**Do not use provisional concept-art character names or invented prices.** The UI must read actual game data.

### Recruitment card

Clicking a character must show:

- Name and portrait.
- Background and tier.
- Brief biography where authored.
- Seven attributes and seven skills.
- Primary weapon, secondary equipment, armour and shield.
- Hiring fee and daily wage.
- Current affordability.
- Recruit or Remove action.

Use the existing simulation's character and equipment records. Do not create a parallel recruitment economy.

### Starting company

Preserve the implemented rules:

- Starting purse: 2,400 crowns.
- Minimum two fighters; maximum six fighters.
- Unique named recruits; individually identified repeatable recruits.
- Elite recruits remain visible even when unaffordable.
- Hiring fees deducted accurately.
- Selection can be reversed before departure under existing refund rules.
- Existing equipment ownership is preserved.

Show a persistent company manifest containing selected mercenaries, number recruited, hiring cost, remaining crowns, combined daily wages and simple financial warnings.

The **Set Sail** button is disabled until the minimum company requirement is met.

Once departure is confirmed, use the existing authoritative Greywake embarkation command. Do not reimplement its financial or roster mutations in the UI.

---

## PHASE 4 — Art integration

A separate Greywake art package has been produced: `Greywake_Opening_Art_ProductionPack_v02.zip`.

If the archive is present in the workspace or supplied as an attachment, inspect its manifest and README before using it.

It contains concept-derived scene plates, portrait references, interface elements and previews. These assets are not necessarily production-final; some were separated and enlarged from composite artwork.

### Art integration rules

1. Use existing artwork where it is suitable.
2. Do not invent missing file paths or pretend an unavailable asset exists.
3. Import usable image assets into a clearly organised `assets/greywake/` structure.
4. Keep dynamic dialogue, names, prices, labels and statistics as native Godot UI.
5. Do not rely on inaccurate text already baked into concept illustrations.
6. Keep portraits associated with the real roster IDs.
7. Flag any portrait that does not visually match the approved character.
8. Preserve asset provenance and applicable licensing information.
9. Do not substitute a low-resolution crop as if it were a final high-resolution illustration.
10. If the archive is unavailable, build functional scene layouts using temporary placeholders and document the missing art.

Use consistent colours, typography, spacing, transitions and frames across the opening sequence.

The art direction is grounded medieval low fantasy: weathered materials, realistic armour, dark coastal landscapes, warm candlelight and restrained use of decorative elements.

---

## PHASE 5 — Boat-crossing cinematic

After confirming the company:

1. Fade the tavern to black.
2. Show a short boat-crossing scene.
3. Display Greywake in the distance.
4. Show a short narrative caption.
5. Fade to the island map.

Proposed caption:

> By morning, Greywake rose from the mist.
>
> Somewhere beyond those cliffs, Baron Vane ruled an island that someone had paid you to take from him.

Keep the sequence brief and skippable. For v0.1, use a still illustration with optional subtle camera movement, ambient ocean sound if suitable audio exists and minimal visual effects.

Do not build a naval traversal simulation. The boat is a presentation transition. The actual authoritative arrival must continue to use the existing Greywake landing logic.

---

## PHASE 6 — Greywake island map

Replace the current Greywake Dock Town staging screen with a small, handcrafted strategic island map.

### Map principles

- Desktop-first landscape presentation.
- No visible square grid.
- Illustrated island coastline.
- Recognisable roads, terrain and settlements.
- Selectable locations.
- Readable company position.
- Visible travel routes and contract markers.
- Dock Town as the starting location.
- Castle Greyhold as the central seat of power.

The repository currently anticipates an approximately **10×10 internal Greywake island region**. Treat that as the implementation baseline unless the latest authoritative design says otherwise.

The visible map should remain compact and handcrafted. Do not enlarge Greywake into a sprawling procedural continent.

### Important technical constraint

The existing simulation uses a 16×16 sector backing structure.

Prefer retaining that structure while implementing Greywake-specific accessible terrain, location data and map presentation. Do not rewrite every save, pathfinding and tactical system merely to change the map's dimensions.

However, the island boundary must be enforced in the simulation. Water and off-island sectors cannot be traversed by company routes, army AI or ordinary overland travel. A decorative sea texture alone is insufficient.

### Required initial locations

Create data-backed locations for Dock Town, Harth Village, Old Abbey, Smuggler's Cove, Greyhold Castle, East Barracks, Northern Watchtower and selected roads, farmland and wilderness connectors.

Preserve established campaign geography and narrative relationships. The first milestone may make only a subset of locations fully interactive, but routes and map selection must be valid.

Do not generate unapproved quests or political outcomes merely to populate the map.

### Migration requirement

The present Greywake build uses a Dock Town staging scenario with persistent saves.

Implement an explicit upgrade path for those Greywake saves if practical. If an existing staging save cannot be safely migrated, preserve it without corrupting or silently replacing its geography and explain the compatibility limitation.

Original campaign saves must remain unchanged.

---

## PHASE 7 — Introductory contract: Dockside Trouble

After the boat cinematic and island reveal, present an introductory contract alert.

**Contract:** Dockside Trouble.

A group of bandits is extorting dockworkers near the warehouses. The port authority or local dockworkers offer the newly arrived mercenary company a modest reward for dealing with the situation.

This encounter must teach the existing tactical combat system through normal gameplay.

### Battlefield

Create an authored dockside tactical map including stone dock surface, wooden jetty, warehouse exterior, stacked crates and barrels, cover positions, clear walking routes, water boundaries, friendly deployment area and enemy starting positions.

Use existing battlefield geometry, collision, movement and line-of-sight rules. Do not make visual props behave differently from their collision or cover data.

### Enemy design

Start with two low-level bandits for the first prototype:

- One poorly equipped melee thug.
- One tougher but still manageable melee opponent.

Balance the encounter against the weakest legal starting company, including two cheap mercenaries. Stronger companies should have an easier time because their recruitment decisions matter.

Do not secretly adjust hit probabilities, enemy health or damage based on the player's hiring costs.

### Tutorial prompts

Teach the following in sequence when relevant:

1. Select a fighter.
2. Move to a legal location.
3. Understand Action Points.
4. Choose an attack.
5. Interpret attack chance and enemy threat.
6. End a turn.
7. Use cover or defensive preparation.
8. Resolve the encounter.

Tutorial guidance must be dismissible and should not prevent legal alternative actions. Do not force players into a scripted combat outcome. Avoid introducing all advanced combat mechanics simultaneously.

---

## PHASE 8 — Consequences and fail-forward

The tutorial is a real battle. It must use the existing authoritative combat system.

### Victory

Bandits defeated or driven away; contract reward paid once; loot and injuries persist; company returns to the island map; Dock Town remains usable; initial campaign activities become available.

### Withdrawal

Surviving mercenaries retreat under ordinary rules; injuries and losses persist; no victory reward; bandit state remains consistent; campaign continues.

### Defeat with survivors

Survivors retain injuries and equipment according to existing rules; no free healing or resurrection; contract records the correct outcome; campaign may continue through recovery, recruitment and other available activities.

### Total company destruction

Existing defeat and persistence rules apply. No automatic restoration of the initial company.

The minimum-two rule applies only to initial departure. A surviving one-person company remains a valid campaign state.

### Recovery economy

The existing Greywake staging implementation has an acknowledged recovery gap.

Add only the minimum grounded, paid activity needed to avoid an otherwise unavoidable softlock after the tutorial. Do not silently grant funds, supplies, recruits or healing. Preserve existing wage and renewal accounting.

Report any remaining economic softlocks identified during tests.

---

## PHASE 9 — Preserve mainland recruitment and blockade behaviour

All currently implemented mainland recruitment mechanics remain authoritative.

Preserve:

- Day 4, 06:00 first reinforcement vessel.
- Four-day subsequent arrivals.
- Two to four candidates per vessel.
- Persistent deterministic manifests.
- 24-hour offshore waiting during blockade.
- Exclusive offshore deadline.
- 48-hour recruitment window after actual docking.
- Hiring only when physically eligible at Dock Town.
- Unique named character identities.
- Repeatable cheap hirelings with separate identities.
- No free replacements.
- Existing save validation.

Connect the island's Dock Town location to the existing Greywake shipping service.

A military change of harbour control must correctly update recruitment accessibility. Do not introduce a new shipping implementation just because the harbour now appears on an illustrated map.

Do not fabricate a political mission or negotiation option to reopen the port.

---

## PHASE 10 — Windows desktop controls

Optimise the opening and tactical experience for desktop.

| Action | Input |
|---|---|
| Select character/location | Left mouse |
| Close/cancel selection | Right mouse or Esc |
| Camera pan | Middle mouse drag |
| Zoom | Mouse wheel |
| Navigate dialogue | Left-click / Enter |
| Skip completed cinematic | Esc / Space |
| End tactical turn | Space, when not conflicting with UI focus |
| Open relevant information | Contextual mouse click |

Keep controls configurable where feasible and do not break existing Android gestures. Ensure all UI works at 1280×720 and scales reasonably to larger desktop resolutions.

Use hover states, tooltips, visible focus and readable text. Avoid oversized touch-only buttons where a smaller desktop control is more appropriate.

---

## PHASE 11 — Architecture and implementation standards

Prefer small, maintainable components.

Suggested responsibilities:

- Opening-flow controller — narrative stage progression.
- Dialogue scene — employer presentation.
- Tavern recruitment view — illustrated scene and hotspots.
- Recruitment profile panel — character data and hiring actions.
- Voyage scene — presentation-only transition.
- Greywake map view — no-grid strategic rendering and interactions.
- Dockside tutorial controller — contextual player guidance.
- Existing campaign and recruitment systems — authoritative simulation.

Do not introduce unnecessary frameworks or rebuild the UI architecture wholesale. Separate immutable authored content from mutable campaign state. Do not create hidden alternative sources of truth.

Avoid unnecessary changes to the original campaign. Keep the original tactical mechanics, inventory ownership, seven-skill character system, saving, AI and shipping simulation intact.

Do not introduce copied proprietary artwork or copyrighted game assets without permission.

---

## PHASE 12 — Testing and acceptance

Before claiming completion, test the following.

### Opening flow

- New Greywake game enters the correct briefing.
- Employer dialogue advances correctly.
- Recruitment tavern loads.
- All twelve approved recruit options are represented.
- Each displayed price and stat matches authoritative data.
- Unaffordable recruits cannot be hired.
- Starting company requires two to six mercenaries.
- Refunds and equipment ownership remain correct.
- Departing cannot be repeated to duplicate funds or items.
- Boat scene leads to Greywake arrival.
- Skipping dialogue or cinematic does not skip required state changes.

### Strategic island

- Dock Town is the starting location.
- The map contains no visible square grid.
- All accessible locations have valid simulation references.
- Water and off-island terrain are impassable.
- Travel and routing respect terrain and connectivity.
- Greywake shipping continues functioning.
- No original campaign geography is altered.

### Tutorial

- A legal two-person starting company can enter combat.
- Friendly deployment is valid.
- Bandits use normal AI and combat rules.
- All tutorial guidance triggers correctly.
- Players remain free to make alternative legal actions.
- Victory, withdrawal and defeat persist correctly.
- Rewards cannot be claimed repeatedly.
- Dead mercenaries cannot be duplicated or resurrected through recruitment.
- Returning to the strategic map retains the actual company state.

### Persistence and regression

- Save/load during opening selection.
- Save/load after company confirmation.
- Save/load after arrival.
- Save/load before and after tutorial battle.
- Existing shipping and blockade cases.
- Original campaign saves and battles.
- Existing core simulation tests.
- Existing Greywake recruitment tests.
- Desktop package smoke test.
- Android compatibility where a test environment is available.

Execute the repository's existing test suites and add focused new tests for the opening. Report exact test counts, failures and unverified scenarios.

Do not describe a feature as complete merely because a mockup renders or a script parses.

---

## Required delivery

Implement the milestone directly in the repository. Create or update appropriate scenes, scripts, assets, data and tests.

Update documentation to distinguish fully implemented features, playable but incomplete features, temporary artwork, missing assets, untested behaviour and deferred Greywake campaign content.

Provide:

1. Summary of implemented changes.
2. Files created or modified.
3. Actual working player flow.
4. Tests executed and their results.
5. Windows build/export instructions.
6. Screenshots of the actual running game where available.
7. Remaining issues and next development priorities.
8. Commit hash and branch information for completed repository work.

Do not claim that changes were committed or pushed unless those actions succeeded.

---

## Development priority

Implement in this order:

**Milestone A — Working narrative and recruitment flow**  
Employer briefing → Interactive tavern → Existing recruitment → Boat transition → Arrival.

**Milestone B — Greywake strategic map**  
Small illustrated island → Dock Town → Valid routes → Preserved recruitment/shipping.

**Milestone C — Dockside tactical tutorial**  
Authored battlefield → Bandit encounter → Contextual lessons → Persistent outcomes.

**Milestone D — Polish and verification**  
Artwork, transitions, desktop UI, save compatibility, regression testing and packaged Windows validation.

Complete each milestone's functional checks before introducing complexity from the next one. If an asset or campaign detail is missing, use a clearly documented placeholder instead of inventing authoritative data.

Do not let missing artwork prevent functional progress.

---

## Scope exclusions

Do not implement the entire Greywake campaign in this milestone.

Do not implement:

- The prince-restoration finale.
- The assassination finale.
- The peasant-uprising finale.
- The full political simulation.
- All future Greywake contracts.
- A full 3D tavern simulation.
- An ocean travel simulator.
- New mercenary skills or weapon trees.
- A redesigned combat engine.
- A new payroll or renewal economy.
- A new save architecture.
- A second mainland recruitment system.

Preserve the unknown employer's narrative role without adding secret lore.

---

## Definition of success

The player can launch a new campaign, receive the contract, choose a personally selected band of mercenaries in an illustrated tavern, travel to Greywake, inspect the island, fight their first bandits and continue playing with the actual persistent consequences of their decisions.

The experience must feel like **the opening chapter of a complete medieval mercenary campaign**, not a collection of disconnected debug screens.

The existing game simulation should remain intact beneath the improved presentation.

**Begin by inspecting the current repository, executing the baseline tests, then implement Milestone A and continue through the remaining milestones wherever the available dependencies permit. Do not stop at a design document or mockup.**
