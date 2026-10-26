# Phase 9 — Android emulator acceptance, 2026-10-26

Scope agreed with the user: use an emulator for now. This closes the emulator smoke-test work; it does not turn emulator results into physical-phone acceptance.

Environment: Android 15 / API 35 default x86_64 system image, dedicated Marches_API35 AVD, 720x1280 physical display rotated to 1280x720 landscape, density 240, two virtual CPUs and 2048 MB RAM. Windows WHPX acceleration and host NVIDIA RTX 3050 Laptop OpenGL translation were used. A simulated tall cutout reports a 72-pixel left safe-area inset in landscape. Version 0.11.0-android-audit is a signed debug build, versionCode 11.

## Evidence and fixes

The host drives Android input commands and real two-pointer MotionEvents through the OS. It does not call campaign commands, override battle outcomes or inject victory/payment. Optional read-only debug telemetry supplies button rectangles and observed state; it is disabled in ordinary builds unless user://mobile-qa.enabled is created in a debug installation. The synthetic large-field scenario is explicitly a separate fixture copied into the isolated emulator's save slot, then loaded through the normal UI.

Android testing found and repaired panel scrolling over buttons: buttons now pass pointer events to their scroll container, and their callbacks run after the input dispatch finishes. Native board touches handle tap, drag, cancellation, emulated-mouse twins and pause cleanup. Android pan/scale recognition is enabled, and both strategic and tactical boards handle the resulting native gesture events. Safe-area pixels are converted into logical UI insets at startup and resize. The text UI and primitive visual scope are retained.

The QA driver also needed fresh-frame waits after cold start and stable button positions after inertial scrolling. Early diagnostic failures were not accepted as passing results; the final reports use the corrected driver and explicit state checks.

Covered scenarios, with raw results in android-qa-results.json and the versioned parent android-qa output folder:

- Basic Android touch: new game, recruitment and panel scrolling, stockpile/person item handover and equip, saved-state restoration, map selection/pan/zoom, real contract acceptance, travel and contact.
- Two-pointer OS input: strategic pinch/pan without unintended release selection.
- Tactical controls: deployment, ray-picked selection, an actual two-AP step, two-AP brace, guard, five-AP bow attack and owned arrow consumption, two-AP reload, camera gestures, active combat save/load and a real enemy turn.
- Android lifecycle: Home writes autosave; force-stop/relaunch and Continue autosave restore phase, funds, time, exact combat profiles/AP/wounds and PRNG. Confirmation Cancel retains the game.
- Cutout configuration: menu and controls fit the reported 72-pixel inset, touch Save works there, and disabling the simulated cutout restores the full landscape layout.
- Synthetic partially surveyed 160x160 field: normal Load and Save retain all 25,600 cells. This is not an authored 25,600-cell encounter or a normal-campaign balance claim.

The large-field observation includes about 4.6 seconds from tap to observed loaded UI, including host/telemetry delay. A prior sample recorded median wall-clock process frame spacing 16.727 ms and p95 19.155 ms over 300 samples. The final raw report retains its own measured sample. The read-only observer adds work, host GPU acceleration is enabled, and these samples do not establish low-end phone frame pacing, thermals or battery performance. No mobile 60-FPS guarantee is made.

Physical multi-finger feel, OEM lifecycle/low-memory behaviour, power-loss/full-disk durability, extended phone soak, accessibility and an exhaustive Android victory/payment walkthrough remain unverified. Desktop UI/integration suites cover the full contract victory/payment loop; the emulator suite covers its controls and actual battle actions, not every possible player flow.

## Reproduce

Start a dedicated API-35 x86_64 emulator. This task's AVD is under work/android-avd; its system image was installed with the official Android CLI. Keep personal phone saves separate. The scripts reject non-emulator serials.

1. Run scripts/build.ps1 with standard Godot 4.6.2 and SDK/JDK paths.
2. Generate the optional scale fixture with Godot --headless --path . --script tests/android_scale_fixture.gd.
3. Run scripts/test_android.ps1 with AndroidSdk, JavaHome, Output, optional Serial and Fixture. It compiles/deploys the OS gesture helper, installs the APK and opts in to read-only telemetry, then gates each scenario on success. Dismiss Android's first-launch full-screen hint if it appears on a fresh AVD.
4. Inspect each *-results.json, screenshots and Android runtime logs. Disable the observer for ordinary play by removing its marker and restarting the app.

Godot platform references used while diagnosing gestures and scroll propagation:
https://docs.godotengine.org/en/4.6/classes/class_inputeventpangesture.html
https://github.com/godotengine/godot/blob/4.6.2-stable/platform/android/java/lib/src/main/java/org/godotengine/godot/input/GodotInputHandler.java
https://github.com/godotengine/godot/blob/4.6.2-stable/platform/android/java/lib/src/main/java/org/godotengine/godot/input/GodotGestureHandler.kt
https://github.com/godotengine/godot/blob/4.6.2-stable/scene/gui/scroll_container.cpp
https://developer.android.com/studio/run/emulator-commandline


Final 0.11.0 emulator run: 37 checks passed, 0 failed across six scenarios; no script/fatal errors in the final application runtime log. The delivered APK hash is bound to android-qa-results.json. Physical-phone acceptance and full foundation remain open as described above.


## 0.14.0 Greywake recruitment preview

The final dedicated Android 15/API 35 x86_64 run passed 62 checks with zero failures: original basic 10, gestures 2, tactical 14, lifecycle 5, cutout 4, selected-skill/legacy recruitment 11, and approved production Greywake opening/shipping 16. The final APK is bound by SHA-256 in greywake-android-results.json. Native control screenshots are retained outside Git in work/greywake-android-evidence-shipping. The preparation harness now removes stale observer telemetry before launch after an earlier rejected startup run; only the complete final passing runs are accepted. Signature v2/v3, CRC, included twelve-profile/scenario data and excluded test/source material were checked. Physical-phone and finished-island recovery acceptance remain open.
