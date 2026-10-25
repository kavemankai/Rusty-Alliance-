# The Broken Marches

Original Godot 4.6.2 / GDScript medieval mercenary strategy game. This is a **playable integrated foundation slice**, not the complete production contract. Primitive 3D tactical board, touch-oriented controls, 16×16 campaign, persistent company, two capture jobs and independent strategic forces.

The current update adds per-squad provisions, local depots, local medical care, persistent tactical levies and combined friendly-squad battles, on top of the item/continuity systems. Schema-1 and schema-2 saves migrate automatically to schema 3 without modifying the original file until you save. Old company supplies are divided between staffed squads; stock local depots before leaving levies to defend.

## Play

Import project.godot in **standard Godot 4.6.2** and press Run. The .NET engine runs the GDScript game, but Android exports use the standard editor and matching template. Install the supplied debug APK on Android for device evaluation.

1. New campaign starts at Ashford (sector 2:2), with Mara and Oswin and 1,200 crowns.
2. Company → Ada → Hire. Inventory permits market purchases and collecting/equipping items at the Ashford stockpile. Tap a carried item to equip, unequip, give to a co-located fighter or deposit at Ashford. Replaced weapons remain in the backpack and add weight. In battle, equipment changes and adjacent handovers cost 3 AP.
3. Contracts → Accept Clear Redbank. Map → tap the F tile at 3:3 → Plot route → +6 hours. Time stops at contact.
4. Deploy company. Select a friendly capsule or its side button. Tap a tile, inspect AP cost, Confirm movement. Tap a visible enemy, set aim if desired, Confirm attack. Reload bows between shots. End turn runs opponents.
5. Tap a door tile from an adjacent position to open it. Crouching costs 2 AP. Guard reserves remaining AP for reaction opportunities. Drag pans and +/− or pinch zooms. Side panels scroll.
6. Resolve after actual victory or defeat. Retreat requires confirmation and a safe adjacent sector; the arrival sector is preferred. Capture pays an accepted job and changes ownership. Wounds, ammunition, losses, enemy survivors, doors and uncollected ground items persist. Victory loot is carried by survivors; return to Ashford to deposit it.
7. Assign medical care, rest, training, repairs, scouting or guard duty. Return to Ashford for recruits and supplies. Iron Hollow at 5:3 is a harder second contract.
8. Save/Load preserves campaign or active battle. Continue autosave loads the last battle boundary/application pause.

## Supplies and defence

Supplies → select a squad → choose 1/5/10/20 → Load or Store a resource. A stationary squad can exchange with a controlled depot in the same sector or another co-located squad. Food, medicine and tools cannot be consumed remotely. Purchases fill the selected squad's pack; farms stock their own local depot. Split and merge conserve every resource. A heavier pack slows travel.

Select an owned sector → Recruit levy (80 crowns). Each levy is a persistent spear-and-shield defender with health, skills and actual equipment. Their hourly food and medical care come from the home depot; upkeep is 3 crowns per living levy per day. Leadership-based garrison training improves their combat skills. New recruitment is capped at 12 living levies per sector in this slice.

Enemy attacks trigger a tactical defence even if the company is elsewhere: Deploy garrison and control the levy units normally. Co-located company squads join the same battle. Withdrawing mercenaries leave the levies defending at home; losing defenders changes ownership. Loot from a garrison-only victory remains on the battlefield for later company recovery.

## Verify / build

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
godot --path . --script tests/ui_smoke.gd
./scripts/build.ps1 -Godot C:/path/to/standard/godot_console.exe
```

The build script gates APK export on mechanics and UI checks, then verifies signing. Configure Java 17, Android SDK build-tools 35.0.1 and the Godot 4.6.2 Android debug template. CI provisions these dependencies. CI is supplied but has not been run remotely.

Read BUILD_STATUS.md, QA_REPORT.md and IMPLEMENTATION_PLAN.md for acceptance evidence and remaining work.
