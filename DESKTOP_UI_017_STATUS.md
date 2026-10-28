# Desktop UI update — 0.17.0

The tavern and battle interface changes are implemented and verified. Run the versioned Windows player in `../broken-marches-0.17.0-windows/`. Existing 0.16 builds and APKs remain separate historical artifacts.

## Tavern: select the people in the painting

All twelve canonical recruitment templates have distinct clickable regions inside the new tavern scene. Every region has a faint border; the selected person and their name-menu button share a soft gold glow. Either input updates the same profile immediately, without rebuilding the whole screen. The profile portrait is a view of that same person in the painting.

The scene fits its available area without cropping; hit regions follow the fitted image through window resizing and UI scale changes. Selection never hires someone automatically. Prices, wages, the two repeatable archetypes, ten unique professionals, equipment and paid departure rules are unchanged.

The new painting was made with built-in imagegen from the supplied tavern reference, following the user's explicit choice of people inside the illustration. The old image and unmatched portrait pack remain preserved. [Asset provenance and appearance mapping](assets/greywake/TAVERN_ART_V2.md) and [exact edit prompt](assets/greywake/TAVERN_IMAGE_PROMPT.txt) record the work. These remain illustrative appearances; actual inventory is authoritative, and fitted equipment/final-art acceptance is not claimed.

## Battle: field above, company below

The desktop battlefield spans the window by default. A compact bottom panel contains six company slots, matching portraits where available, health/AP/energy bars, the selected fighter's real equipment and ammunition, Equipment/Details controls and a tactical overview. Extra units can scroll horizontally; empty slots are decorative and never create people. The turn banner reflects actual deployment, exploration or combat state.

The full existing options inspector opens with **Details**. It remains resizable. Other campaign menus, inventory and saves retain their established controls. The default desktop camera is closer and starts near the active fighter; middle drag, wheel, WASD/arrows, F and Home remain available.

The active fighter receives a gold portrait border, world diamond, outline and overhead pointer. A selected, currently visible enemy receives a red target diamond/outline. The equipment panel and persistent AP/hit preview identify the selected target. Hidden or dead opponents receive no target marker. The overview uses observed terrain snapshots and currently known enemies rather than hidden world state; clicking it moves only the camera.

## Contextual radial controls

Click a battlefield tile, fighter or currently visible target to open the radial; right-click also opens context while retaining the actor for friendly support. The menu offers the applicable move/attack or placement action, plus movement, attack choices, defence, stance/pace, support and other controls. Groups with more than six entries have pages. Cancel/Escape dismisses it; Tab/arrows and Enter navigate/activate its native buttons. Space and gameplay shortcuts cannot act through an open radial.

Actions reuse the existing internal control callbacks synchronously. AP, attack chance, range, ammunition, injuries, equipment requirements and command validation remain authoritative. A context fingerprint rejects stale choices after actor/battle/state changes. Changing panels, focus or window size dismisses the menu. Opening choices pauses automatic advancement and never advances the campaign clock. Merely browsing options creates no items, hires or experience.

## Accepted verification

**7,522 counted assertions passed, zero failed, across 20 suites.** Original-campaign UI and skills UI additionally report zero failures without assertion totals. Every accepted process exited 0 and its log contains no engine/script error. The normal-scene probe is a 120-frame measurement, not an assertion counter. See `desktop-ui-017-results.json` and `evidence/desktop-0.17.0/` for exact reports, logs, normalized source hashes and build fingerprints.

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Core / extended | 596 / 796 | 0 |
| Skills / Greywake | 165 / 650 | 0 |
| Opening / island / dockside | 40 / 492 / 183 | 0 |
| Assets | 814 | 0 |
| Tavern image/name selection and layout | 3,225 | 0 |
| Bottom HUD, radial actions and visibility | 129 | 0 |
| Desktop settings / mouse-focus supplement | 17 / 14 | 0 |
| Greywake UI / opening UI / scene-art UI | 23 / 227 / 28 | 0 |
| PC player loop / cached renderer | 112 / 11 | 0 |

The tavern checks click every image and name at 1280×720, 1600×900, 1920×1080 and 130% UI at minimum size. They check matching profiles, synchronized highlights, independent non-overlapping hit regions, bounds and unchanged authoritative state. The battle checks use actual GUI events, paid recruits and a real enemy turn. They verify exact move/attack/ammunition/stance costs, stale rejection, keyboard blocking, world/portrait selection, hidden-target suppression, overview behavior and valid owned inventories. Controlled negative fixtures alter AP/visibility only to test rejection; no victory is forced.

Existing UI regressions open the optional inspector through the actual Details button when testing its controls. The opening test explicitly dismisses the radial before testing the global end-turn shortcut. These are adaptations to the new interaction, not bypasses of command validation.

One earlier partial headless run exited with native engine code -1073741819 in the unchanged island suite. Its independent repeat and the subsequent complete run both finished with 492 passed, 0 failed and exit 0. Only clean accepted runs are counted above.

## Runtime and delivery evidence

`sim/` and `data/` remain unchanged from `482244e`. Existing original-campaign, save/ownership, skills, deterministic combat/pathfinding/fog/AI, wages and shipping checks pass. No JA2 source, artwork or numeric tables were copied; the supplied screenshots guide layout only.

The isolated exported PCK smoke loads the new tavern/regions/profile selection, bottom HUD and live radial context, then checks actual actors, meshes, canonical data, saves and notices: **0 failed, exit 0**. The actual x86-64 release executable separately renders two native 1600×900 title frames outside the source directory and exits 0. Movie capture is launch/render evidence, not gameplay FPS. Binary/ZIP hashes, byte sizes and CRC are in `desktop-ui-017-release.json`.

The latest ordinary-scene probe observed **30 FPS at 1920×1080 in this host session**, with a 1920×707 tactical target and the configured cap of 60. Diagnostic runs disabling VSync, overlays, clipping or halving resolution also observed 30 FPS; the cause is not established. This update makes no new 60-FPS or hardware-wide guarantee. The cached selection-redraw benchmark remains a separate CPU measurement, not a whole-game FPS multiplier. Other PCs, sustained performance and Android device interaction remain unverified.

## Reproduce and continue

Use official Godot 4.6.2 standard and its x86-64 release template. From this project:

```powershell
./scripts/check_pc.ps1 -Godot 'C:/path/to/Godot_v4.6.2-stable_win64_console.exe'
python scripts/map_quaternius.py
& 'C:/path/to/Godot_v4.6.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' '../broken-marches-0.17.0-windows/The Broken Marches.exe'
```

From the exported folder, run the standard engine with `--main-pack './The Broken Marches.pck' --script '../broken-marches/scripts/pack_smoke.gd'`. Check its explicit smoke result and exit code. Launch the release EXE normally for play. `scripts/package_desktop_ui.py` validates the recorded source/report/binary fingerprints before creating the ZIP. Keep the original campaign and the exact roster authoritative; do not add simulation rules to UI callbacks.

Final portraits/fitted animation, the broader Greywake campaign and endings, audio, balance and fresh Android acceptance remain outside this interface update.
