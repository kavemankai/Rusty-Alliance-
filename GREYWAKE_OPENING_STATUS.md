# Greywake Opening Experience v0.1

Development build **0.15.0-greywake-opening**, Godot 4.6.2 standard / Compatibility. Based on the verified 0.14 recruitment/shipping implementation at `ebf3865`.

This is an integrated opening chapter, not the entire Greywake campaign. The current player flow is:

**Title → anonymous employer briefing → interactive tavern → company confirmation → skippable crossing → island reveal → Dockside Trouble → actual tactical encounter → persistent island campaign.**

## What works

The title provides New Game, Continue, Settings and Exit, with separate original-campaign access and existing save buttons. The employer's already-accepted contract uses the supplied draft dialogue. No employer identity, betrayal, investigation, extra route or political outcome is introduced.

The tavern is a single interactive illustrated tableau with twelve native recruit hotspots. Its temporary silhouettes distinguish the militia table, professional table, lone plate-armoured fighter, fistfight, hearth/window/bar candidates and a tending patron. Every profile reads the authoritative roster, seven attributes/seven skills, canonical loadout, hiring fee and daily wage. The company manifest shows actual selected individuals, fees, reserves and wages. Named selections can be removed from their card or manifest; repeatable individuals are removed individually. Hiring/refunds use existing commands. Two to six paid recruits are required; both Elites remain inspectable and unaffordable at the opening purse of 2,400 crowns.

Opening stages and dialogue progress persist in `Campaign.s.opening_flow`. The existing `opening_voyage` remains the financial/landing authority. Company confirmation calls the existing embarkation function exactly once. The voyage is a brief still-image transition, automatically completing after 4.5 seconds or skippable with its button, Esc or Space. Fade-out/in durations are 0.10/0.15 seconds. Scene time never advances the campaign clock; the company lands at the established minute 480. Save/load and Android pause saves preserve the current narrative stage and actual company.

The gridless island uses a separate native map view and an original unlabelled vector base. Coast/terrain illustration, roads, names/icons, fog, ownership, company, contract markers, routes and the harbour ship icon remain separate layers. It contains a handcrafted 10×10 region with **62 connected land sectors**, retained inside the existing 256-sector backing. Dock Town, Harth, Old Abbey, Smuggler's Cove, Greyhold, East Barracks, Northern Watchtower, Pinewood, Crossroads and Harth farmland have real simulation references. Sea/off-island flags restrict company routes, strategic arrivals, retreat neighbours and army neighbour choices; they are also checked on load. The original 16×16 campaign is unchanged. Fortresses can be approached, but their authored encounters and larger campaign content are unavailable in this opening.

Dockside Trouble offers **180 crowns**, a provisional authored reward. Two fixed enemies use existing dagger/mace data, ordinary AI, hit chances, damage, injuries and defeat rules. Enemy profiles do not change with recruitment spending. The authored battlefield has stone quay, wooden jetty, warehouse, stacked cargo, actual cover/blockers, water boundaries and legal deployment zones. Water blocks movement but permits sight; no special tutorial combat odds are used. A newly active CC0 barrel mapping joins the existing crate/building models (36 runtime mappings / 33 distinct source models; 63 thumbnails remain unchanged).

The tutorial follows actual selection, movement, AP, attack/chance, turn, defence and resolution. Tips can be acknowledged or dismissed and never block alternative legal actions. Advanced combat controls remain available behind an explicit button during the introduction. Victory pays once through existing contracts; withdrawal pays nothing, leaves bandits/loot/injuries consistent and can close the occupied port. Defeat uses existing capture/death rules. Destroyed companies are not restored. One-person survivors remain valid.

A minimal recovery activity, **Harth farm-road rounds**, uses the existing patrol/waypoint/payment/repost implementation: accept physically at Harth, visit its farmland, then return for **120 crowns**, payable once per posting. Existing one-day repost delay, normal travel, hourly food, wages, injuries and employment expiry all remain. Its first posting uses the existing five-day offer period; expiry/reposting does not end the campaign. The dockside introductory offer has no practical campaign deadline; its existing numeric deadline representation uses a named far-future sentinel, not a new story timer.

The Day 4 06:00 / four-day shipping calendar, deterministic 2–4 candidate manifests, exclusive 24-hour offshore deadline, actual-docking 48-hour offer window, physical hiring requirements and unique ownership remain authoritative. The map's harbour UI uses that same service. No second recruitment system or free political reopening action exists.

## Art status and provenance

`Greywake_Opening_Art_ProductionPack_v02.zip` was not found in this task's files or Downloads. A wider Codex-directory search returned no match but encountered an unrelated inaccessible cache, so absence from every possible location is not asserted. No files from that production archive are claimed as imported or approved.

The employer, tavern, voyage/title and island plates are **original temporary vector artwork** under `assets/greywake/`, with provenance in `PROVENANCE.txt`. They are replaceable placeholders, not enlarged crops passed off as production art. Native UI supplies all names, prices, statistics and dialogue. Character cards explicitly use temporary CC0 **role portraits**, not approved identity-matched portraits; no new biography or character likeness is invented. No suitable audio exists in the supplied library, so this opening remains silent. Fitted armour, missing weapon models, full animation and the rest of the production asset gaps remain in ASSET_COVERAGE.md.

## Save compatibility and migration

Original schema-1/2/3 migrations and campaign slots remain intact. Greywake keeps `greywake.json` and `greywake-autosave.json`. New island saves carry namespaced opening/world version metadata and strict actor, job, mask, route and stage validation.

Older 0.14 staging saves continue to load and retain their geography. An explicit **Upgrade staging save to island opening** action is available only for a safe minute-480, single stationary company at Dock Town, with no visited battlefield, levies, encounter, armies, jobs or pending travel. It preserves actual people, gear, money, counters and shipping records. Hired pre-departure selections resume in the tavern; already-landed eligible companies resume at arrival without paying or embarking again. Unsupported historical staging states are rejected without mutation and remain playable in their original staging screen. No visited battlefield is regenerated.

## Desktop and Android controls

Left click selects; middle drag pans the island/tactical camera; wheel zooms; right click or Esc cancels a selection. Enter advances briefing; Esc skips briefing to recruitment or cancels company confirmation. Esc/Space skips crossing. Space ends a tactical turn when UI focus does not consume it; clicking the board releases previous button focus. Existing Android drag/pinch/pan and touch controls are retained. The opening uses compact desktop controls and larger touch targets on Android. Full key rebinding remains deferred; the title Settings screen documents bindings and provides fullscreen switching.

## Verification

Baseline before edits: mechanical 596/0, extended 796/0, skills 165/0, Greywake 650/0, assets 812/0, old Greywake UI 23/0, existing main/skills UI 0 failures. Final evidence is recorded in the report files listed below. Only clean process exits without SCRIPT ERROR/ERROR or native crash output count as accepted runs.

| Suite | Accepted passed | Failed | Evidence |
| --- | ---: | ---: | --- |
| Existing mechanics/integration | 596 | 0 | test-results.json |
| Existing extended/replays | 796 | 0 | extended-results.json |
| Existing seven-skill compatibility | 165 | 0 | skills-test-results.json |
| Existing roster/shipping | 650 | 0 | greywake-test-results.json |
| Existing art plus new barrel mapping | 814 | 0 | asset-test-results.json |
| Legacy staging UI compatibility | 23 | 0 | greywake-ui-results.json |
| New saved opening sequence | 40 | 0 | opening-flow-results.json |
| Authored land/routes/migration | 492 | 0 | island-test-results.json |
| Actual dockside outcomes/recovery | 183 | 0 | dockside-test-results.json |
| New native desktop opening/profile/input flow | 221 | 0 | opening-ui-results.json |
| Existing main/selected-skill UI | no counter | 0 | ui-test-results.json / skills-ui-results.json |

The dockside legal-action driver won **12/12 tested roster/seed combinations**, including two spearmen, two crossbowmen, a mixed cheap pair and a stronger professional company. This establishes those fixtures, not guaranteed victory for arbitrary play/seeds or final balance. Defeat/capture and destruction tests use declared controlled low-health fixtures to exercise genuine outcome handling. Withdrawal and paid recovery use real travel and contract commands; there is no forced outcome or free recovery grant in shipped gameplay.

An initial new island test completed assertions but the engine crashed during shutdown; that attempt is rejected. Subsequent clean island reruns passed. Early UI checks also caught off-screen confirmation and narrow stat columns; these were fixed before accepted runs. A temporary static JSON cache caused shutdown resource warnings and was removed. No accepted result relies on those attempts.

Packaged Windows and final Android checks are recorded separately after export; source results alone do not establish packaged/native success. Physical-phone feel, sustained performance/thermals/battery and broader campaign balancing remain unverified.

## Files and responsibilities

- `sim/greywake_opening.gd`: saved flow, authored introduction/encounter, tutorial markers, persistent outcomes.
- `sim/greywake_world.gd`: authored region installation, passability, strict validation and explicit safe migration.
- `sim/campaign.gd`: thin command/event/control integration; existing authority retained.
- `sim/greywake_shipping.gd`: additive recognition of versioned island metadata; lifecycle/hiring rules retained.
- `sim/contracts.gd`: existing contract accounting; location-aware error wording for island work.
- `sim/battlefields.gd`, `sim/tactical.gd`: dockside data and transparent-but-impassable water support.
- `ui/greywake_opening_view.gd`: title, employer, tableau, real profile cards/manifest, confirmation, crossing and reveal.
- `ui/greywake_map.gd`: layered gridless island and existing touch/desktop input.
- `ui/main.gd`, `ui/battle_view.gd`: opening integration, contextual teaching and desktop controls.
- `ui/mobile_probe.gd`: read-only QA coordinates for the actual new map; never gameplay commands.
- `data/greywake_opening.json`, `greywake_island.json`, `greywake_dockside.json`: immutable authored content and prototype tuning.
- `assets/greywake/`: temporary original plates and provenance; existing role thumbnails remain licensed CC0 sources.
- `scripts/build_greywake_placeholder_art.py`, `map_quaternius.py`: reproducible art/runtime dependency selection.
- `tests/opening_flow.gd`, `greywake_island.gd`, `greywake_dockside.gd`, `opening_ui.gd`: new focused acceptance suites.
- `tests/greywake_ui.gd`: retains the legacy staging interface regression; new title/tableau flow has its own suite.
- `scripts/android_greywake_smoke.py`, `android_opening_smoke.py`, `pack_smoke.gd`: native/backward-compatible/package evidence.
- `export_presets.cfg`: explicit new runtime/data/provenance export and version code 15.

The exact supplied roster is preserved. Generated screenshots and test JSONs accompany these changes; source/build/status/asset documents distinguish current and historical acceptance.

## Build and run on Windows

Use the standard Godot 4.6.2 console executable. From the project folder:

```powershell
& $Godot --headless --path . --editor --quit
& $Godot --headless --path . --script tests/run.gd
& $Godot --headless --path . --script tests/extended.gd
& $Godot --headless --path . --script tests/skills.gd
& $Godot --headless --path . --script tests/greywake.gd
& $Godot --headless --path . --script tests/greywake_island.gd
& $Godot --headless --path . --script tests/greywake_dockside.gd
& $Godot --headless --path . --script tests/opening_flow.gd
& $Godot --path . --script tests/opening_ui.gd
& $Godot --headless --path . --export-pack 'Windows Pack' 'builds/windows-opening/The Broken Marches.pck'
```

Run all existing UI/assets suites too. Pair the exported PCK with the official standard Windows runner renamed `The Broken Marches.exe`, with notices beside it. Keep both in the same directory. Smoke-test from **outside** the source project using `--main-pack` and `scripts/pack_smoke.gd`, so local source cannot mask missing packaged dependencies. Android debug export uses the existing Java 17 / SDK 35 setup and the distinct 0.15 APK path; never overwrite the 0.14 artifacts.

## Remaining priorities

1. Supply/inspect the production art archive, replace placeholders, map real identity portraits and supply suitable audio.
2. Human playtest the introduction, tutorial wording, fixed enemy values and provisions/wage reserves. The bounded recovery job supports tested cheap survivors; expensive companies can still make unsustainable decisions. Incapacitated/captured or destroyed companies do not receive free rescue, healing or money.
3. Author actual fortress/garrison encounters, contracts and political/evidence consequences before claiming a complete island campaign.
4. Complete the three victory routes/endings only in their own approved milestones. The employer remains anonymous.
5. Perform physical Android acceptance and sustained performance/accessibility work. Full remapping/localisation and final art/animation remain future work.

## Release verification notes

The final Windows PCK was tested outside the source folder using the official Godot 4.6.2 runner: two rendered actors and **0 failures**, including real opening plates, island data, authored collision and barrel mesh. The 0.15 APK verifies with Android v2 and v3 signatures.

An initial export omitted dynamically referenced SVG dependencies. All four plates are now explicitly selected in both exports and the outside-project smoke was repeated successfully. An Android startup assertion initially read the previous title telemetry after a successful tap; OS-input helpers now wait for a fresh post-input observer frame, allowing up to 30 polling seconds for scene loading. A first lifecycle attempt hit the shorter timeout while rebuilding the loaded 3D battle; the completed retry is recorded separately. An accidentally headless UI invocation could not drive the native GUI; the GUI repeat finished **221 passed, 0 failed**. Failed attempts are excluded from accepted counts.

Native touch testing also exposed a real tavern scrolling defect: the profile panel consumed drag events before its scroll container. The panel now passes those events and the role thumbnail ignores them. Native hiring is rerun after that fix; pre-fix Android scenarios are not bound to the final artifact.

## Final packaged/native acceptance — 2026-10-27

The final 0.15.0 APK completed **76 passed, 0 failed** across eight native Android OS-input scenarios. Counts: original campaign 10, gestures 2, tactical combat 14, lifecycle 5, cutout 4, skills/progression 11, Greywake recruitment/shipping 17, opening/battle/paid recovery 13. These are complete runs on the rebuilt APK after the tavern touch fix; earlier candidates are excluded.

Device: dedicated Marches_API35 emulator, Android 15 / API 35, x86_64, 1280×720 landscape, host GPU. The installed APK hash equals the packaged file: `018abf4028f70c6d7d855b2cd8018036052f74868440303d39d3ac484beff776`. APK archive checksums and v2/v3 signature verification pass. The logcat capture contained no SCRIPT ERROR or fatal exception match. Emulator evidence does not establish physical-phone feel, performance, battery or thermals.

The current Windows pack also completed its outside-source-folder launch/render/battle smoke with **0 failures**. Source tests total **3,980 passed, 0 failed**, plus existing no-counter UI checks with zero failures. No passing count includes a shutdown crash or failed earlier attempt.

Runtime implementation: `da37a12` on `main` (pushed). The subsequent evidence commit contains the final reports/screenshots. Player artifacts are separate 0.15 files under the workspace outputs folder; earlier 0.14 files are preserved.

Actual running-game screenshots: [desktop tavern](opening-tavern-preview.png), [desktop island](opening-island-preview.png), [desktop dockside](opening-dockside-preview.png), [Android tavern](opening-android-tavern-preview.png), [Android island](opening-android-island-preview.png), [Android combat/tutorial](opening-android-combat-preview.png). Exact changed paths are listed in [GREYWAKE_OPENING_CHANGED_FILES.md](GREYWAKE_OPENING_CHANGED_FILES.md).
