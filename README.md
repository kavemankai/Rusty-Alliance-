# The Broken Marches

Original Godot 4.6.2 / GDScript medieval mercenary strategy game. This is a **playable integrated foundation slice**, not the complete production contract. Primitive 3D tactical board, touch-oriented controls, 16×16 campaign, persistent company, six contract types and independent strategic forces.

The current update implements the requested melee/world/company/escort/AI/strategy production pass and adds explicit offensive/defensive combat choices. See REQUEST_PROGRESS.md for the feature checklist. The exploration update supplies optional command-based scouting and sight-triggered combat transitions. The map update added distinct settlement, farm, mine and camp battlefields with authored placement zones and persistent terrain/loot. Unvisited sectors choose their layout from facility and terrain; visited sectors retain their map. Pre-battle deployment lets you place friendly fighters in the highlighted zone, choose facing and press Begin combat. Unconfirmed formations save/load; old active battles resume in combat. The preceding update added state-driven elimination, camp assault, escort, patrol and settlement-defence jobs alongside capture. The prior update added per-squad provisions, local depots, local medical care, persistent tactical levies and combined friendly-squad battles, on top of the item/continuity systems. Schema-1 and schema-2 saves migrate automatically to schema 3 without modifying the original file until you save. Old company supplies are divided between staffed squads; stock local depots before leaving levies to defend.

## Play

Import project.godot in **standard Godot 4.6.2** and press Run. The .NET engine runs the GDScript game, but Android exports use the standard editor and matching template. Install the supplied debug APK on Android for device evaluation.

1. New campaign starts at Ashford (sector 2:2), with Mara and Oswin and 1,200 crowns.
2. Company → Ada → Hire. Inventory permits market purchases and collecting/equipping items at the Ashford stockpile. Tap a carried item to equip, unequip, give to a co-located fighter or deposit at Ashford. Replaced weapons remain in the backpack and add weight. In battle, equipment changes and adjacent handovers cost 3 AP.
3. Contracts → Accept Clear Redbank. Map → tap the F tile at 3:3 → Plot route → +6 hours. Time stops at contact.
4. Deploy company opens deployment review. Use Scout before contact for exploration when neither side sees opponents, or Begin combat to start turns directly. Select a fighter, tap a green tile, Confirm placement, and optionally Rotate facing. Begin combat locks the formation and starts the first turn. Placement costs no AP; combat and strategic time stay frozen during review. Select a friendly capsule or its side button. Tap a tile, inspect AP cost, Confirm movement. Tap a visible enemy, set aim if desired, Confirm attack. Reload bows between shots. End turn runs opponents.
5. Tap a door tile from an adjacent position to open it. Crouching costs 2 AP. Guard reserves remaining AP for reaction opportunities. Drag pans and +/− or pinch zooms. Side panels scroll.
6. Resolve after actual victory or defeat. Retreat requires confirmation and a safe adjacent sector; the arrival sector is preferred. Capture pays an accepted job and changes ownership. Wounds, ammunition, losses, enemy survivors, doors and uncollected ground items persist. Victory loot is carried by survivors; return to Ashford to deposit it.
7. Assign medical care, rest, training, repairs, scouting or guard duty. Return to Ashford for recruits and supplies. Iron Hollow at 5:3 is a harder second contract.
8. Save/Load preserves campaign or active battle. Continue autosave loads the last battle boundary/application pause.

## Contract board

New campaigns have seven postings across six objective types. Elimination follows a named existing enemy force, camp assault requires its actual garrison, and defence pays only for repelling the named attackers at the settlement. Clear Redbank and eliminate its raiders can be fulfilled together; killing those raiders elsewhere fails their Ashford defence posting.

Pick up the Willow escort and western-road patrol with a capable stationary squad at Ashford. Freight is a separate 20-food consignment with travel weight; it is unavailable for consumption or transfer. Delivery stores it in Willow's depot. An arrival ambush must be won first; withdrawal, defeat or loss of the assigned squad loses the caravan. The patrol must visit 2:3, 2:4, 2:6 and Ashford in that order. Progress survives save/load. Road work can be reposted one day after closing with a fresh identifier and deadline. Finish before the listed minute.

Existing schema-3 campaigns retain their existing board and world. Start a new campaign to see the new postings and Briar camp at 5:4. There is no automatic insertion of armies into old saves. Escort is a strategic freight abstraction; an independently targetable cart and caravan driver are future tactical work.

## Supplies and defence

Supplies → select a squad → choose 1/5/10/20 → Load or Store a resource. A stationary squad can exchange with a controlled depot in the same sector or another co-located squad. Food, medicine and tools cannot be consumed remotely. Purchases fill the selected squad's pack; farms stock their own local depot. Split and merge conserve every resource. A heavier pack slows travel.

Select an owned sector → Recruit levy (80 crowns). Each levy is a persistent spear-and-shield defender with health, skills and actual equipment. Their hourly food and medical care come from the home depot; upkeep is 3 crowns per living levy per day. Leadership-based garrison training improves their combat skills. New recruitment is capped at 12 living levies per sector in this slice.

Enemy attacks trigger a tactical defence even if the company is elsewhere: Deploy garrison, review/place the levy formation and Begin combat; then control the levy units normally. Co-located company squads join the same battle. Withdrawing mercenaries leave the levies defending at home; losing defenders changes ownership. Loot from a garrison-only victory remains on the battlefield for later company recovery.

## Verify / build

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
godot --path . --script tests/ui_smoke.gd
./scripts/build.ps1 -Godot C:/path/to/standard/godot_console.exe
```

The build script gates APK export on mechanics and UI checks, then verifies signing. Configure Java 17, Android SDK build-tools 35.0.1 and the Godot 4.6.2 Android debug template. CI provisions these dependencies. CI is supplied but has not been run remotely.

Read BUILD_STATUS.md, QA_REPORT.md and IMPLEMENTATION_PLAN.md for acceptance evidence and remaining work.

Phase 1 provides deployment controls. Phase 2 supplies authored entry zones for each map, excluding blocked/occupied cells and cells within three tiles of living hostiles. Persistent hostile positions are retained before friendly placement. An entry zone without capacity leaves units unplaced and prevents confirmation; save or withdraw through a safe exit. Settlements use roads, stalls and enclosed buildings; farms use a yard wall, crop rows and a raised field; mines use rock cuts, a storehouse and elevated quarry; camps use a palisade, gate, cover tents and two approach zones. These remain primitive layouts, without roofs or building-entry transitions. Existing saved battlefields are preserved; visit a previously unvisited sector or start a new campaign to see the new maps.

## Exploration and combat

After deployment, Scout before contact enters command-based scouting if there is no current visual contact. Confirm movement advances one local pulse at a time; enemies patrol, AP recovers gradually and untreated bleeding progresses. Wait / scout advances one pulse without a new movement command. Either side detecting an opponent immediately stops pending movement and opens the company combat turn with remaining AP. Enter combat can start turns deliberately. AP is never refilled merely by changing mode.

After three complete combat rounds without either side seeing opponents, Resume exploration becomes available. Current LOS is checked again. Exploration preserves locations, injuries, local terrain, patrol state and queued movement across Save/Load. It also works for combined squads and garrison defenders. This slice pauses strategic time while a tactical encounter is active; exploration time does not process strategic wages or food. Quiet exploration is command-based, not continuously running while the player is idle. Peaceful sectors without an existing hostile contact still have no separate tactical-entry action.

## Visibility and tactical opponents

Dark ground is unexplored; dim ground is remembered; normal ground is currently visible to the company. Deployment briefs only the entry area. Walls/doors outside sight retain their last observed appearance; unseen changes and ground loot stay hidden until observed. Terrain memory persists with each sector and initializes from actual sight for old saves. Unit visibility still uses perception, facing, stance, concealment and LOS.

Routes use remembered terrain. Unknown ground is provisionally treated as ordinary open ground, and the UI labels such routes as estimates. Real steps charge actual AP and stop at newly encountered obstructions, contact or exhausted AP. Low props and adjacent structures protect against attacks from their direction; flanking and higher ground can reduce that protection. The target panel shows directional cover against the selected attack.

Ranged opponents can move to nearby protected firing positions while retaining enough AP to shoot. Pursuit uses recent last-seen coordinates, stops treating a searched location as a live target and ignores memories older than three rounds. Idle fighters can approach wounded allies; visible threats near a wounded ally receive target priority. These are bounded original tactics using shared team knowledge, not full formations or communication simulation. Hire and equip a third fighter for the camp assault; stronger cover-aware defenders can defeat the original two-person squad.

## New controls

Operations opens peaceful sector visits, transport purchases and local prisoner actions. Peaceful maps support Run/Pause exploration, paid construction on an adjacent selected tile, roof cutaways and Leave sector. Inventory now includes local levies. Contracts offers daily generated deliveries/patrols. New caravans deploy an actual cart and driver into threatened battles.

In combat, select a target to choose style/body area, charge or shield bash. Select an adjacent free tile for deliberate disengagement and read its reaction/AP preview. The side panel offers defensive modes, ally protection, rally, adjacent treatment/repair and actual thrown items. Watch localized injuries, matching ammo type and shield condition. Unused turn AP carries up to four points. Use a prepared four-fighter party or four shield defenders for the deterministic camp fixtures; the mechanical driver does not use every player option.

Night visibility and constructed torches affect perception. Enemy reports have local communication limits, and strategic factions recruit from actual resource budgets. These systems are original bounded rules, not claims of exact JA2 parity. Restart the game to load the changes; new fields contain roof/room/approach metadata, while old visited geometry is preserved.
