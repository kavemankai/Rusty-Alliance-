# The Broken Marches

Original Godot 4.6.2 / GDScript medieval mercenary strategy game. This is a **playable integrated foundation slice**, not the complete production contract. Primitive 3D tactical board, touch-oriented controls, 16×16 campaign, persistent company, two capture jobs and independent strategic forces.

## Play

Import project.godot in **standard Godot 4.6.2** and press Run. The .NET engine runs the GDScript game, but Android exports use the standard editor and matching template. Install the supplied debug APK on Android for device evaluation.

1. New campaign starts at Ashford (sector 2:2), with Mara and Oswin and 1,200 crowns.
2. Company → Ada → Hire. Inventory permits market purchases and equipping stash items.
3. Contracts → Accept Clear Redbank. Map → tap the F tile at 3:3 → Plot route → +6 hours. Time stops at contact.
4. Deploy company. Select a friendly capsule or its side button. Tap a tile, inspect AP cost, Confirm movement. Tap a visible enemy, set aim if desired, Confirm attack. Reload bows between shots. End turn runs opponents.
5. Tap a door tile from an adjacent position to open it. Crouching costs 2 AP. Guard reserves remaining AP for reaction opportunities. Drag pans and +/− or pinch zooms. Side panels scroll.
6. Resolve after actual victory or defeat. Retreat requires confirmation. Capture pays an accepted job and changes ownership. Wounds, ammunition and losses persist.
7. Assign medical care, rest, training, repairs, scouting or guard duty. Return to Ashford for recruits and supplies. Iron Hollow at 5:3 is a harder second contract.
8. Save/Load preserves campaign or active battle. Continue autosave loads the last battle boundary/application pause.

## Verify / build

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/run.gd
godot --path . --script tests/ui_smoke.gd
./scripts/build.ps1 -Godot C:/path/to/standard/godot_console.exe
```

The build script gates APK export on mechanics and UI checks, then verifies signing. Configure Java 17, Android SDK build-tools 35.0.1 and the Godot 4.6.2 Android debug template. CI provisions these dependencies. CI is supplied but has not been run remotely.

Read BUILD_STATUS.md, QA_REPORT.md and IMPLEMENTATION_PLAN.md for acceptance evidence and remaining work.
