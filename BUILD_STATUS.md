# Build status — 2026-10-26

**Playable integrated slice delivered; full production foundation incomplete.**

Current development build: **0.15.0-greywake-opening**, implementing Opening Experience v0.1. Anonymous employer briefing, native interactive tavern/profile cards, paid two-to-six-person confirmation, presentation-only crossing, authored gridless island, real dockside tutorial/outcomes and paid recovery work are integrated. The original campaign, exact roster, ownership, payroll, renewal and four-day shipping rules are retained. Existing staging saves stay intact; only explicitly eligible pristine saves can upgrade. Scene/portrait art is temporary, the production archive remains unavailable, and the broader Greywake campaign/endings are unfinished. See GREYWAKE_OPENING_STATUS.md for actual evidence and remaining verification.

Target repository was empty when cloned. Godot source, tests, documentation and the asset inventory are tracked in this directory; origin is https://github.com/kavemankai/Rusty-Alliance-.git. Generated builds and local development tools are stored separately from the source repository.

Engine: standard Godot 4.6.2 stable, official 71f334935. GDScript, Compatibility/OpenGL renderer, landscape, Android min SDK 24 / target SDK 35. arm64-v8a, armeabi-v7a and x86_64 debug architectures. No paid services. Version 0.12.0 introduces the user-approved Quaternius CC0 asset library; ASSET_COVERAGE.md records actual coverage and unfinished art/animation work. Earlier Android emulator measurements describe 0.11.0, before these art changes.

Verified on Windows with NVIDIA RTX 3050 Laptop GPU:

- 596 mechanical/integration assertions pass with zero failures.
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
- Visibility/AI phase adds per-team explored terrain memory, current sight, hidden loot/obstacle suppression, provisional unknown-ground routes, directional geometry-derived cover, cover-seeking ranged AI, bounded last-seen pursuit and wounded-ally support. No hidden opponent coordinates enter pursuit goals.
- The requested items 1-6 and offensive/defensive pass add paid combat choices, localized injury/treatment, typed projectiles, peaceful construction/rooms/timed scouting, prisoners/levy gear/transport, protected caravans/procedural jobs, local AI communications/lighting/formations and resource-backed strategic responses. See REQUEST_PROGRESS.md.
- Godot imports and runs. Signed Android debug export succeeds; APK inspected with SDK package tools and signature verification.

Android 15/API 35 x86_64 emulator installation, native touch, scrolling, gestures, cutout safe areas, combat controls and lifecycle recovery are now verified within ANDROID_QA.md. No physical phone is connected. Physical touch feel, OEM interruption/low-memory, sustained performance/thermals and battery remain unverified. The GitHub Actions workflow has not run remotely.

Remaining acceptance work includes Android hardware/touch testing, physical filesystem/power-loss acceptance, and independent commercial rights/dependency review. The focused technical source/release-content audit is complete; mandatory gaps are listed in CONTRACT_ACCEPTANCE.md. Application-level save interruption and desktop scale profiling are covered in HARDENING_SCALE.md. The six requested gameplay areas and subsequent offensive/defensive pass are implemented as described in REQUEST_PROGRESS.md; multistorey buildings and mounted tactical combat are not claimed.

Build notes: the preinstalled executable was the .NET editor and requested .mono templates. A separate official standard 4.6.2 executable was downloaded into the workspace work/ directory. The initial standard export's blank validation error was fixed by enabling Android ETC2/ASTC texture import. Project has an original primitive icon; final export should run without the earlier missing-icon error. Debug signing uses existing local development tooling; signing files/passwords are not placed in the repository.

Resume: read AGENTS.md and GAME_SPEC.md, run both suites, then continue tactical/AI depth from IMPLEMENTATION_PLAN.md if no device is available. Full contract is preserved verbatim in PRODUCTION_CONTRACT.md.


## Save hardening and scale follow-up — 2026-10-26

Phases 7 and 8 add typed event/financial/assignment records, structural preflight before migration, verified temporary/backup commits, process-termination recovery coverage, large-map heap routing, cached selection redraws and six 45-day campaign/replay scenarios. See HARDENING_SCALE.md and the raw profile/extended reports for exact evidence and limitations. The physical Android gate (phase 9) and wider source/parity/release audit (phase 10) remain open. No additional JA2 source was copied or newly audited in this follow-up.


## Phases 9 and 10

The user selected emulator testing. See ANDROID_QA.md and android-qa-results.json for final Android evidence. Technical source/mapping/content work is recorded in SOURCE_AUDIT.md, CONTRACT_ACCEPTANCE.md, LEGAL_PROVENANCE.md and THIRD_PARTY_NOTICES.txt. Full foundation is still not claimed: physical acceptance, mandatory interactive debug overlays/scenario launcher and commercial review remain separate gaps.


Final 0.11.0 emulator run: 37 checks passed, 0 failed across six scenarios; no script/fatal errors in the final application runtime log. The delivered APK hash is bound to android-qa-results.json. Physical-phone acceptance and full foundation remain open as described above.
