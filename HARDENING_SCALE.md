# Phases 7 and 8 — save hardening and measured scale

## Phase 7

Typed Event, Transaction and Assignment records now define the command/save boundaries. Assignment records retain actor, task, sector and start time; old saves gain missing records without replacing malformed existing data. Financial rows must form a chronological balance chain ending at current funds. Event IDs are unique, ordered by time/ID, below next_event and cannot be in the past; event payloads have required fields.

Structural preflight runs before migrations and semantic ownership checks. It rejects malformed nested collections, invalid coordinates, fractional/out-of-range statistics, bad terrain order, malformed inventory/injury records and invalid active combat data. Existing schema-1/2 fixtures still migrate; active mercenary, enemy, levy and convoy profiles still rebind to their canonical owners.

Saving writes and flushes a temporary file, checks write status, reads and validates it, writes and verifies a separate backup temporary file, commits that backup, then renames the current temporary file. Loading tries committed current, committed backup, validated current temporary, then validated backup temporary. A valid current always wins over an uncommitted newer temporary file. Invalid loads leave the live campaign unchanged. recovery_source identifies which file was used.

Recovery coverage includes partial writes, termination after a verified temporary write, interruption before backup rename and interruption after backup rename. Each checkpoint also runs in a separate engine process terminated with OS.kill. Markers prove it reached the checkpoint and did not execute past termination; the parent verifies the last committed campaign remains intact. These tests use isolated user://hardening-* files. Truncated current-file recovery, first-save temporary recovery and malformed strategic/tactical records are covered. This verifies application/process interruption, not physical power loss, filesystem durability or actual full-disk hardware failure.

## Phase 8

A measured baseline justified replacing repeated frontier sorting with a binary min-heap and an admissible movement-cost heuristic for large fields. The reference solver remains for authored maps of at most 512 cells to preserve their established equal-cost route choices. Randomized tests compare minimum AP with the reference solver, then check every route step against the exact movement cost, including charted hidden terrain, elevation, blockers, stance and movement mode.

Visibility refresh reuses its terrain hash for lighting. The renderer retains static geometry across selection and route-preview redraws, repaints changed highlights and replaces dynamic units/loot without accumulating nodes. Terrain, fog, sight, roofs, lighting and occupied-room changes invalidate the cache; a full rebuild still occurs for those changes.

Measured on Windows, standard Godot 4.6.2, i5-13420H and RTX 3050 Laptop GPU, OpenGL Compatibility, fully surveyed stress maps, five units:

| Grid | Route before ms | Route after ms | Redraw before ms | Selection/preview redraw after ms | Cached visibility before/after ms |
|---|---:|---:|---:|---:|---:|
| 32 x 32 | 166.350 | 43.194 | 7.652 | 2.175 | 0.459 / 0.311 |
| 80 x 80 | 3422.338 | 325.433 | 35.262 | 4.951 | 1.746 / 1.124 |
| 160 x 160 | 32101.517 | 1378.760 | 132.073 | 13.642 | 10.321 / 4.613 |

Minimum route costs are unchanged at 124, 364 and 764 AP. At 160 x 160 this is about 23 times faster routing and 10 times faster selection redraw. Initial terrain construction remains a loading cost: 165 ms in the current sample versus 136 ms baseline. The renderer intentionally trades some cache/invalidation work for much faster repeated selection redraws. Full fog/terrain rebuilds and 1.38-second worst-size routes can still pause input. These are desktop measurements, not Android acceptance or low-end performance proof. The roughly 16.7 ms frame samples are vsync-capped and do not establish GPU headroom. Baseline redraw had unchanged selection; the current measurement additionally changes selection and route preview.

Raw profile-baseline.json and profile-current.json retain the measurements. tests/profile.gd reproduces the current profile. Do not overwrite baseline data when rerunning the current profile.

Six deterministic seeds each run 45 simulated days with active factions, upkeep, recruitment, ordinary legal combat, actual casualties and save/reload every fifth day. Checkpoints validate ownership/state and replay the next clock interval in two independent instances. These scenarios use explicit reserve funds and provisions to isolate persistence and long-running strategy; they do not establish economy balance or campaign win rates. Together they cover 270 simulated campaign days. Build validation runs both the ordinary mechanical suite and tests/extended.gd, followed by rendered UI controls and APK export/signature checks.

Physical Android acceptance and the wider source/parity/release audit remain open. Full production foundation is not claimed.

## Final verification and delivery

- Mechanical/integration: 577 passed, 0 failed.
- Extended route/campaign checks: 796 passed, 0 failed; six seeds, 270 simulated days. The count includes each legal route step and therefore varies if equal-cost paths have a different number of steps.
- Rendered desktop walkthrough: 0 failures, including repeated redraw node conservation and retained static floor for selection/preview changes.
- Android export: versionCode 10, versionName 0.10.0-hardening-scale, package org.brokenmarches.foundation. APK signature schemes v2/v3 verify. No physical Android test performed.
- The initial final-gate attempt caught a typo in the added UI test. The corrected rendered suite and export completed successfully afterward. Mechanical and extended code was unchanged after their passing final runs.
- Versioned APK/source packages sit alongside the previous release in the parent outputs folder; the prior delivered APK is retained. Existing local project.godot editor changes are preserved outside the commit. No remote push was performed.
