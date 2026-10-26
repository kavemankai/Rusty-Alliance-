# Current Greywake milestone — 0.14.0

The exact roster has now been supplied and implemented. New Greywake creation, paid pre-voyage selection and scheduled mainland recruitment are enabled. See [current implementation and verification](GREYWAKE_RECRUITMENT_STATUS.md) and [approved shipping specification](GREYWAKE_RECRUITMENT_SHIPPING_SPEC.md). The island map and recovery economy remain upstream acceptance work.

---

## Historical 0.13 record (superseded status)

# Seven-skill/Greywake verification

2026-10-26 · 0.13.0-skills-preview · Godot 4.6.2 Compatibility

**This is not full Greywake acceptance.** The finalized twelve-template workshop roster is missing. All recruiting tests use clearly labelled synthetic data. The production roster file is empty and new Greywake creation is disabled. The original campaign remains available.

## Desktop and simulation

| Suite | Recorded result | Coverage |
|---|---|---|
| `tests/run.gd` | **596 passed, 0 failed** | All existing mechanical/integration cases, including original campaign and old migrations |
| `tests/extended.gd` | **796 passed, 0 failed** | Path solvers, campaign replay and six 45-day campaign seeds |
| `tests/skills.gd` | **165 passed, 0 failed** | Seven attributes/skills; schema-1/2/3 saves; preserved IDs/history/items; malformed data; selected training and separate banks; same-hour/repetitive rejection; Stealth, Fieldcraft, Athletics; AP preview/execution including hidden withdrawal terrain; scouting; deterministic high-skill AI replay; separate scenario/default save/autosave paths; budget, exact charging, unique named/cheap identities and renewal audit |
| `tests/ui_smoke.gd` | **0 failures** | Existing normal-control company, equipment, supply, deployment, exploration, combat, garrison, convoy and save/load flows |
| `tests/skills_ui.gd` | **0 failures** | Real UI input selects training, preserves partial credit, hires two separate cheap fighters, saves/reloads and restores scenario-specific save defaults; synthetic roster only |
| `tests/touch_smoke.gd` | **19 passed, 0 failed** | Existing native-event gesture/ray-picking checks; these are also included in the 596 mechanical assertions |
| `tests/assets.gd` | **812 passed, 0 failed** | Existing art library/runtime/icon integrity and presentation/state separation |
| Packaged Windows smoke | **0 failures** | Executed from outside the source project; packaged scripts, actors, icons and notices present; unused art library excluded |

All accepted runs require a clean exit and no SCRIPT ERROR/ERROR output. An immediate-free touch fixture exposed a native shutdown crash with skinned scenes; its teardown now queues the board for freeing and both callers wait two frames. The 19 assertions remain intact. An initial editor-import shutdown also crashed; the accepted repeat completed cleanly. Failed attempts are not counted as passes.

The local build script and GitHub workflow include the skill simulation and UI suites. This report verifies local/emulator runs; it does not assert an unobserved remote GitHub Actions result.

The art catalogue now holds resource paths rather than eagerly preloading every tactical model into the menu/editor. Live visual nodes retain their source resources for safe cache reuse during redraw; no static resource cache is introduced. The skills UI test verifies that opening the menu does not cache the Warrior 3D model. Explicit export selections still include the needed models, and an outside-directory package test verifies them. No measured memory, FPS or thermal improvement is claimed from this change.

## Android emulator

Android 15/API 35 x86_64, dedicated Marches_API35 emulator, landscape, actual Android input. The optional debug telemetry observer reads state and control bounds; it does not execute game commands.

- Existing native scenarios: **35 passed, 0 failed** across basic controls (10), gestures (2), tactical combat (14), original-campaign lifecycle recovery (5) and cutout handling (4).
- Dedicated skill/recruitment scenario: **11 passed, 0 failed**, including seven-skill display, selected training and partial-credit isolation, individual recruiting/item IDs, save/reload and Greywake's own pause/force-stop autosave continuation. Earlier connection/startup failures are not accepted evidence; the recorded successful rerun uses the rebuilt lazy-loading package and a restarted emulator.
- The synthetic Greywake test uses a validated normal save fixture to set up the scenario; subsequent hiring, training, save/load and lifecycle operations use actual Android input. It checks unique item ownership and the persisted recruit counter by reading the saved file.
- Test-only template data, authoring scripts and fixtures are excluded from the player APK. New production Greywake creation remains disabled until the actual workshop roster arrives.

Raw reports/screenshots are in the neighbouring `greywake-android-qa-0.13.0` output folder. The source summary is `greywake-android-results.json`. Startup telemetry is removed before relaunch so an old file cannot masquerade as a live process. Failed emulator cleanup is recorded as failure, not hidden.

During initial reruns the Android emulator framework/ADB connection failed, including DeadSystem errors in emulator system processes. The dedicated emulator was restarted for the accepted rerun. This is an environment failure record, not proof of a physical-device or application-memory diagnosis.

This is functional emulator evidence, not physical-phone touch/thermal/battery acceptance or a new low-end performance claim. The 160×160 scale scenario was not repeated in this skill pass.

## Open input and unverified scope

1. Supply the finalized twelve-template workshop table: names, attributes, seven skills, fees, wages and initial equipment details. No synthetic statistics are a substitute.
2. Integrate that table and rerun budget choices, named identity, repeated cheap recruitment, old/new saves, UI, deterministic AI and Android scenarios against the real roster.
3. Verify the final workshop balance in playtests and on physical Android hardware.
4. Renewal still charges seven days' wages up front while daily payroll continues. The current accounting is verified and documented, not changed or declared correct as a prepaid-wage design.

No bespoke Greywake map, boat timetable, complete defence/RP redesign, weapon skill trees or full asset-production completion is claimed by this work.
