# Handover

Open project.godot with standard Godot 4.6.2, or install the debug APK. README.md contains the exact first-contract walkthrough. Screenshots show the actual strategic, inventory and tactical runtime.

Simulation entry: sim/campaign.gd command(). Campaign.s is the single state store. Tactical rules: sim/tactical.gd, with weak campaign ownership and shared mercenary references. Original equipment/character/AP data: sim/catalog.gd. Main UI: ui/main.gd. Strategic drawing/gestures: ui/world_map.gd. Instanced 3D board and ray selection: ui/battle_view.gd.

Item operations live in sim/inventory.gd; schema-1→2→3 upgrades live in sim/save_schema.gd. Supplies live in squad.supplies and sector.supplies via sim/supplies.gd. sim/garrison.gd creates/trains individual sector.levies profiles. Tactical units reference canonical mercenary, group.fighters or sector.levies profiles. Items have one owner and equipment references owned IDs. Local sector.battlefield retains map/door/ground state. Future schema changes must migrate detached data before rebinding.

Run mechanics and UI tests before continuing. Use scripts/build.ps1 for a gated local APK, .github/workflows/android.yml for proposed remote CI. The workflow is unverified remotely. No release keystore is needed for a debug build.

Saves: Godot user://campaign.json (manual) and user://autosave.json (battle boundaries and application pause), with .bak recovery. Test drivers use separate test-named save/autosave slots and preserve manual playthrough slots.

There is a working central loop and 208 mechanical/integration checks, but **the full production contract is not completed**. Item ownership, battlefield continuity, per-squad logistics, persistent tactical levies and combined friendly squads are implemented. IMPLEMENTATION_PLAN.md is the authoritative next-work list. Remaining contract types are the next major code priority, followed by deployment/AI depth. Android device QA remains outstanding.

Repository is locally committed with the provided origin. Reference JA2 content is outside this deliverable. No game code/assets were copied from it, and no commercial publication or paid-service action occurred.
