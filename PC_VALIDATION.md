# PC vertical slice validation — 0.16.0

The existing Greywake opening and original campaign now have native desktop sizing, configurable keyboard controls, persistent combat controls, a resizable inspector and presentation caching. Acceptance covers 1280×720 through 1920×1080 on Windows, with a default window up to 1600×900 within the available desktop.

Run `The Broken Marches.exe` beside `The Broken Marches.pck` in `../broken-marches-0.16.0-windows/`, or extract the sibling ZIP. **New Game** opens Greywake; **New campaign** retains the original campaign. Existing scenario save slots are preserved. No campaign saves are bundled.

## Controls and display

| Action | Default |
| --- | --- |
| Select fighter, destination or visible target | Left click |
| Pan / zoom | Middle drag, WASD or arrows / mouse wheel |
| Confirm preview, deployment or actual outcome | Enter when no button has keyboard focus |
| Cancel preview; then open paused Settings | Right click or Escape; Escape again |
| Select / cycle fighters | 1–9, Tab / Shift+Tab |
| End turn / reload / guard | Space / R / G |
| Center selected fighter / reset camera | F / Home |
| Map or battle / Company / Contracts / Inventory | M / C / J / I |
| Save / confirmed quickload | F5 or Ctrl+S / F9 |
| Help / fullscreen | F1 / F11 |

Settings contains UI scale (90–130%), battle render scale (50–125%), VSync, frame limit (30/60/120/unlimited) and action bindings. Preferences use `user://desktop-settings.cfg`, separately from campaign data. Conflicting or reserved bindings are rejected. Focused buttons keep Enter/Space behavior; typing and dialogs block gameplay shortcuts. Tab cycles fighters when the board has focus, and navigates controls when a button has focus. Briefing/crossing retain their displayed skip controls.

The crew strip and AP/hit/confirm/reload/guard bar stay visible. Advanced combat choices remain in the inspector. Drag its divider to resize it. Camera/divider state survives UI rebuilds; camera state survives quickload within the running session. Camera positions are presentation state, not new persistent campaign fields. Focus loss stops automatic time/exploration, clears held input, disables tactical rendering and caps processing at 15 FPS. Returning focus restores the selected cap without resuming travel.

## Accepted tests

**4,166 counted assertions passed, zero failed.** Two additional UI suites report zero failures without assertion totals. All 18 accepted runs exited 0 without `ERROR:` or `SCRIPT ERROR:`. The frame probe is a measurement rather than an assertion total. [Machine-readable evidence](pc-acceptance-results.json) records report/source hashes and per-run logs under `evidence/pc-0.16.0/`.

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Core mechanics | 596 | 0 |
| Extended integration | 796 | 0 |
| Seven skills | 165 | 0 |
| Greywake roster, transactions, shipping, saves | 650 | 0 |
| Opening flow | 40 | 0 |
| Island | 492 | 0 |
| Dockside combat and recovery | 183 | 0 |
| Assets | 814 | 0 |
| Desktop preferences | 17 | 0 |
| Mouse camera and focus-clock supplement | 14 | 0 |
| Original campaign UI | No total counter | 0 |
| Skills UI | No total counter | 0 |
| Greywake UI | 23 | 0 |
| Opening UI | 225 | 0 |
| Scene-art UI | 28 | 0 |
| PC interaction, layout and player loop | 112 | 0 |
| Renderer comparison | 11 | 0 |
| Normal game-scene probe | 120 sampled frames | No errors |

The PC suite uses actual Control mouse/key events, paid canonical recruits and validated commands. It covers briefing, focused Return, six-person selection at three resolutions and 130% UI, departure, crossing, deployment, divider dragging, fighter selection, exact movement/AP/hit previews, visible crossbow attack and owned bolt, reload, guard, enemy turn, key repeats, typing, modal blocking, remapping, fullscreen, save/load, focus handling, withdrawal, map travel, Harth work and exactly-once payment. A second paid company wins through legal tactical engine actions; Enter resolves its real victory and cannot pay twice. This is automated interaction, not human playtest acceptance. The headless mouse supplement independently exercises actual board GUI events and the running-clock focus transition.

## Performance and limits

Measured on an Intel i5-13420H / RTX 3050 Laptop GPU / 60 Hz display:

- Same six-person campaign, 30 CPU selection redraw samples: baseline `90b0ce7` median **6.142 ms**, current **0.203 ms**, about **30.3×** lower CPU time for this operation. P95 **6.857 → 0.232 ms**. The old renderer is retained as a test-only fixture. GPU targets were disabled and deferred teardown excluded. This is not a universal FPS multiplier.
- Ordinary game-scene main loop at 1920×1080, cap 60, 120 frames after warm-up: **60 FPS**, median **16.6663 ms**, p95 **16.6667 ms**, tactical target **1548×817**. See `pc-native-probe-results.json`. The custom SceneTree test harness is not used to establish gameplay FPS.
- Actor/terrain IDs remain stable through 100 selection redraws. Real state changes still rebuild actors. Tactical resolution follows control pixels and render scale, bounded at 2560×1440. Picking and logical geometry retain the same battle.

This is one PC and a short slice measurement. Other hardware, high-DPI configurations, sustained performance, thermals, larger battles and physical phone interaction remain unverified.

## Windows release evidence

`Windows Desktop` uses the official Godot 4.6.2 x86-64 release template ([official release](https://github.com/godotengine/godot-builds/releases/tag/4.6.2-stable)). The EXE is **104,653,312 bytes**; PCK **66,744,524 bytes**. Tests, benchmark fixtures, raw library-only models and reference boards/portraits/maps stay excluded.

The isolated PCK smoke loads the main scene, desktop classes, crew/action docks, native battle target, meshes/materials/icons, credits, exact roster, skills, Greywake calendar, valid saves, opening and real dockside combat: **0 failed, exit 0**. It runs with the standard engine against the exported PCK. It is not reported as an external-script result from the release template.

The actual release executable separately rendered two 1600×900 title frames outside the source directory and exited **0** using `--quit-after`. The inspected frame is `pc-release-title-preview.png`. Movie capture timing is encoding time, not performance evidence. Windows was locked during the direct computer-use attempt; no lock bypass or physical input acceptance is claimed. Source GUI tests and exported-data smoke are the interaction evidence. Package sizes, hashes and CRC appear in the repository file `pc-release-results.json`.

## Reproduce

From the project folder, with official 4.6.2 standard engine and its release export template installed:

```powershell
./scripts/check_pc.ps1 -Godot 'C:/path/to/Godot_v4.6.2-stable_win64_console.exe'
python scripts/map_quaternius.py
& 'C:/path/to/Godot_v4.6.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' '../broken-marches-0.16.0-windows/The Broken Marches.exe'
```

From the exported folder:

```powershell
& 'C:/path/to/Godot_v4.6.2-stable_win64_console.exe' --main-pack './The Broken Marches.pck' --script '../broken-marches/scripts/pack_smoke.gd'
```

For a real release-render check, use `Start-Process -PassThru` with the release EXE, its exported working directory, and arguments `--write-movie <absolute-frame-path.png> --quit-after 2 --fixed-fps 60 --log-file <absolute-log-path>`. Wait for the returned process; inspect `ExitCode`, log and frames. A successful shell launch alone is not an exit-code check. Run the EXE normally for play.

After recording release evidence, `python scripts/package_pc_preview.py` gates accepted reports and binary hashes before making the ZIP. Full graphical tests require an interactive unlocked desktop; the PC mouse supplement runs headless independently.

## Scope completion audit

| Requirement in PC_VERTICAL_SLICE.md | Authoritative proof |
| --- | --- |
| 1. Native sizing/scaling/fullscreen | Settings implementation, PC window and 130% UI checks, inspected tavern/combat frames and real release title |
| 2. Complete existing player loop | Real-input opening/actions, legally driven victory and Enter resolve, confirmed withdrawal, paid Harth work, save/load; original UI smoke |
| 3. Crew/action/preview/inspector | Six actor strip, exact cost/hit/owned-ammo assertions, pinned-control bounds at two combat sizes, real divider drag and retention |
| 4. Safe PC controls | PC 112, mouse 14 and settings 17; modal/typing/repeat/focus/remapping assertions; camera/cancel keys documented |
| 5. Preferences/focus pause | Config reload/corruption, native pixel scaling, running-clock supplement, render-disabled/cap assertions |
| 6. Rendering optimization/camera continuity | Stable actor IDs, retained-baseline benchmark, ordinary-scene probe, resolution bounds and deployment/rebuild/quickload camera checks |
| 7. Preserve simulation/content | Clean `git diff --exit-code 90b0ce7 -- sim data`; core, extended, skills, ownership, saves, shipping, fog/tactical and original UI results |
| 8. Validation and delivery | 18 accepted runs, outside-source PCK/native release checks, versioned ZIP/CRC/hashes, report, separate screenshots and normal recoverable Git commit/push |

## Remaining outside this PC slice

Final approved portraits, fitted equipment/action animation, final art/audio, complete Greywake contracts/military AI/evidence/three endings, balance and Android acceptance remain outstanding. Seven supplied scene images remain provisional. PC buttons use a flat focus-visible style, the supplied profile panel and three icons. Touch retains its eight-texture path. Existing APKs are historical and unchanged. Full production-contract completion is not claimed.
