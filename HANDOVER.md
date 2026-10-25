# Handover

Open project.godot with standard Godot 4.6.2, or install the debug APK. README.md contains the exact first-contract walkthrough. The two screenshots show the actual strategic and tactical runtime.

Simulation entry: sim/campaign.gd command(). Campaign.s is the single state store. Tactical rules: sim/tactical.gd, with weak campaign ownership and shared mercenary references. Original equipment/character/AP data: sim/catalog.gd. Main UI: ui/main.gd. Strategic drawing/gestures: ui/world_map.gd. Instanced 3D board and ray selection: ui/battle_view.gd.

Run mechanics and UI tests before continuing. Use scripts/build.ps1 for a gated local APK, .github/workflows/android.yml for proposed remote CI. The workflow is unverified remotely. No release keystore is needed for a debug build.

Saves: Godot user://campaign.json (manual) and user://autosave.json (battle boundaries and application pause), with .bak recovery. Test drivers use separate test-named save/autosave slots and preserve manual playthrough slots.

There is a working central loop and an extensive initial test suite, but **the full production contract is not completed**. IMPLEMENTATION_PLAN.md is the authoritative next-work list. Highest code priorities are persistent item IDs/transfers, per-sector tactical persistence, retreat survivors, simultaneous encounter ordering and the remaining contract types. Android device QA remains outstanding.

Repository is locally committed with the provided origin. Reference JA2 content is outside this deliverable. No game code/assets were copied from it, and no commercial publication or paid-service action occurred.
