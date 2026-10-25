# Build status — 2026-10-25

**Playable integrated slice delivered; full production foundation incomplete.**

Target repository was empty when cloned. Local Godot source lives in this directory; origin remains https://github.com/kavemankai/Rusty-Alliance-.git. Changes are committed locally; no remote push or commercial publication is performed.

Engine: standard Godot 4.6.2 stable, official 71f334935. GDScript, Compatibility/OpenGL renderer, landscape, Android min SDK 24 / target SDK 35. arm64-v8a, armeabi-v7a and x86_64 debug architectures. No paid services or final-art assets.

Verified on Windows with NVIDIA RTX 3050 Laptop GPU:

- 403 mechanical/integration assertions pass with zero failures.
- Phase 1 deployment is complete for the current encounter template: legal highlighted western placement, free facing changes, explicit combat confirmation, frozen actions/knowledge, company/combined/garrison formations and saved unconfirmed formations. Existing active saves resume combat. Phase 2 adds authored settlement, farm, mine and camp layouts plus terrain-based wilderness fallbacks. Geometry, deployment zones and hostile spawn pools persist with the sector.
- Normal-control desktop UI scenarios pass company/item management, supply deposit/load, a capture contract battle and a separate stocked garrison defending while the company is elsewhere, with active/post-victory save/load.
- Six objective types use authoritative travel/battle hooks, exclusive deadlines and exactly-once payments. Patrol/escort progress and freight survive save/load; road postings repeat after one day. Old boards are retained unchanged.
- New rendered controls also fulfil a garrison defence posting and a saved escort/patrol route.
- Two distinct contract battles complete through legal simulation actions in the integration suite.
- Thirty-day isolated clock scenario produces exactly one wage entry each midnight.
- Unique equipment IDs, per-item condition/quantity, backpack switching and location/AP-validated transfers are implemented. The rendered UI scenario takes, transfers and equips an actual item.
- Persistent enemy rosters, casualties, injuries, ammunition/reload state, doors and uncollected ground items survive retreat, save/load and re-entry. Retreat uses safe neighbouring sectors.
- Actual schema-1 and schema-2 fixtures migrate to schema 3 without rewriting the original files. Mercenary, enemy and levy active-battle references rebind after load.
- Squads carry separate food/medicine/tools. Local depots, transfers, split/merge conservation, farm output, supply burden and local medical care are verified. Remote resources confer no benefit.
- Levies are persistent tactical defenders with gear, training, wounds, casualties and upkeep. Co-located squads deploy together; garrisons defend alone and continue after company withdrawal. Lost packs stay at the defeated sector.
- Strategic contacts queue and stale travel callbacks are rejected.
- Company and garrison legal-action victories pass on all four layout types. Rendered controls verify each layout, placement, reload and paid movement; doors and ground loot survive retreat/re-entry. Older battlefields retain their exact geometry.
- Phase 3 adds opt-in command-based exploration, local movement/patrol/bleeding pulses, immediate either-side detection into combat, retained AP/positions and a three-quiet-round return to scouting. Mode, pending paths and patrol state persist.
- Godot imports and runs. Signed Android debug export succeeds; APK inspected with SDK package tools and signature verification.

No connected adb device or installed emulator was available. Android install, launch, physical touch, pause/resume under the OS and performance are **not verified**. No mobile FPS claim is made. The GitHub Actions workflow has not been run remotely.

Production gaps include independently targetable escort carts, levy loadout management, full prisoner handling, deeper AI/knowledge/cover/lighting, transport modes, broader malformed-save/OS interruption coverage and scale profiling. See IMPLEMENTATION_PLAN.md for ordered acceptance work.

Build notes: the preinstalled executable was the .NET editor and requested .mono templates. A separate official standard 4.6.2 executable was downloaded into the workspace work/ directory. The initial standard export's blank validation error was fixed by enabling Android ETC2/ASTC texture import. Project has an original primitive icon; final export should run without the earlier missing-icon error. Debug signing uses existing local development tooling; signing files/passwords are not placed in the repository.

Resume: read AGENTS.md and GAME_SPEC.md, run both suites, then continue tactical/AI depth from IMPLEMENTATION_PLAN.md if no device is available. Full contract is preserved verbatim in PRODUCTION_CONTRACT.md.
