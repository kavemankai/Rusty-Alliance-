# Current opening follow-up — 0.15.0

See [Greywake Opening Experience v0.1](GREYWAKE_OPENING_STATUS.md) for the current flow, authored island, tutorial/recovery work, temporary scene art and verification. The prior report below is historical; its package hashes and remaining-work statements describe that earlier build. The new runtime adds one existing CC0 barrel model (36 mappings / 33 models), retaining the 63 icons and original library provenance.

---

# Asset integration verification — 0.12.0

2026-10-26 · standard Godot 4.6.2, Compatibility/OpenGL, Windows/NVIDIA RTX 3050 Laptop GPU.

## Automated evidence

| Check | Result | Scope |
|---|---|---|
| Godot full-library import | Exit 0; no SCRIPT ERROR/ERROR output | 735 models and their supplied material/texture dependencies |
| Original mechanical suite | **596 passed, 0 failed** | Existing simulation/integration rules |
| Extended suite | **796 passed, 0 failed** | Campaign, persistence and broader rule scenarios |
| Asset-specific suite | **812 passed, 0 failed**; clean exit | All 735 imported resource remaps, 35 nonempty runtime mappings, matching thumbnail dependencies, canonical actor references and no campaign mutation through visual construction/redraw |
| Source asset audit | **735 model hashes verified, 8 CC0 notices, 63 PNG thumbnails, 0 failed** | Original imported model integrity, licence markers and 192×192 thumbnail format; full clip inventory in asset-source-results.json |
| Desktop control smoke | **0 failures** | Recruitment, inventory/equipment transfers, supplies, all encounter layouts, deployment, paid movement, combat choices, convoy, garrison, fog/loot reveal and save/load; verifies selection redraw retains floor cache and does not accumulate actor nodes |
| Packaged desktop smoke | **0 failures** | Main menu, company/inventory, encounter, actual actor geometry, all 63 thumbnail dependencies, notices and exclusion of a library-only character, run outside the source project |
| Calibration render | **15 models rendered, 0 failed** | Isolated presentation preview, not a campaign screenshot or fog claim |
| Android debug export/signature | Export succeeds; v2/v3 signature verified | Version code 12, 0.12.0-quaternius-assets, current art dependencies and notices |

Source and runtime logs are in the workspace `work/` folder. `asset-test-results.json`, `asset-source-results.json`, existing test JSON reports and refreshed runtime screenshots preserve the evidence in source. Test/authoring code, reports, screenshots and unused library geometry are excluded from playable packages.

## Runtime footprint and packaging

The source library is about 498 MB before Godot's import cache. It contains 735 source models, including variants and material dependencies. The player loads **32 distinct 3D models through 35 role/terrain/equipment mappings**, plus **63 small rendered thumbnails**. Whole buildings, animals and armour props needed only to author thumbnails do not have to load as 3D resources on a phone.

The Windows delivery pairs the official standard Godot executable with the exported PCK and engine/art notices. Launch `The Broken Marches.exe` from the delivered folder; keep the adjacent PCK. This runner contains the standard engine/editor binary rather than a separately downloaded Windows export template. The delivered folder runs independently of the project checkout; a package smoke check explicitly uses an outside folder to prevent source files from masking missing dependencies.

Selected exports explicitly list runtime scripts and source models because a main-scene-only selection did not discover all GDScript preload dependencies. `scripts/map_quaternius.py` regenerates that list and keeps library-only geometry out of exports.

An initial static bounds cache retained script/resources at shutdown in the new asset test. The cache was removed; the final asset test exits cleanly. Bounds are computed from each instantiated model. No passing claim relies on the earlier errored test runs or incomplete packages.

## Remaining verification

- The art build has **not** repeated the 0.11.0 Android emulator acceptance run. Old emulator frame-time/memory results cannot be applied to these models/textures.
- Physical phone performance, texture memory, thermals, battery, lifecycle/OEM interruption and final touch readability remain open.
- Named appearances, fitted armour/grips, complete movement/combat/support animation and full prop assembly remain production work, not completed by asset presence.
- The provided 15-model preview and sampled icons were inspected. This is not exhaustive artistic approval of every imported variant or proof that every attachment is correct in every pose.
- No audio or fonts exist in the supplied ZIP. Missing assets and integration work are enumerated in ASSET_COVERAGE.md.

## Reproduce

1. Run `python scripts/import_quaternius.py <archive-path>` with the user-supplied archive.
2. Run Godot's headless editor import, then `python scripts/map_quaternius.py`.
3. Run `scripts/render_asset_icons.gd` using the rendering-capable standard engine; rerun mapping and editor import afterward. Existing committed PNGs do not need regeneration for normal builds.
4. Run `tests/run.gd`, `tests/extended.gd`, `tests/assets.gd`, `tests/ui_smoke.gd` and `python scripts/audit_asset_sources.py`; reject SCRIPT ERROR/ERROR output regardless of exit code.
5. Export the `Windows Pack` PCK and Android debug preset. Copy the PC runner/PCK/notices outside the project, then run `scripts/pack_smoke.gd` against that PCK from the outside directory. Verify the Android signature before delivery.
