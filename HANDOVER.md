# Handover

Open project.godot with standard Godot 4.6.2, or install the debug APK. README.md contains the exact first-contract walkthrough. Screenshots show the actual strategic, inventory and tactical runtime.

Simulation entry: sim/campaign.gd command(). Campaign.s is the single state store. Tactical rules: sim/tactical.gd, with weak campaign ownership and shared mercenary references. Original equipment/character/AP data: sim/catalog.gd. Main UI: ui/main.gd. Strategic drawing/gestures: ui/world_map.gd. Instanced 3D board and ray selection: ui/battle_view.gd.

Item operations live in sim/inventory.gd; schema-1→2 upgrade lives in sim/save_schema.gd. Items are owned by one inventory, stockpile or ground placement; equipment references owned IDs. Enemy individuals belong to group.fighters and tactical units reference those same dictionaries. Local sector.battlefield retains map/door/ground state. Add future schema changes through detached migration before canonical reference rebinding.

Run mechanics and UI tests before continuing. Use scripts/build.ps1 for a gated local APK, .github/workflows/android.yml for proposed remote CI. The workflow is unverified remotely. No release keystore is needed for a debug build.

Saves: Godot user://campaign.json (manual) and user://autosave.json (battle boundaries and application pause), with .bak recovery. Test drivers use separate test-named save/autosave slots and preserve manual playthrough slots.

There is a working central loop and 142 mechanical/integration checks, but **the full production contract is not completed**. Item IDs/transfers, local persistence, retreat survivors and encounter queueing are now implemented. IMPLEMENTATION_PLAN.md is the authoritative next-work list. Highest code priorities are per-squad consumable supplies, tactical levies/combined squads and remaining contract types. Android device QA remains outstanding.

Repository is locally committed with the provided origin. Reference JA2 content is outside this deliverable. No game code/assets were copied from it, and no commercial publication or paid-service action occurred.
