# Current desktop interface — 0.17.0

The tavern now supports direct image selection of all twelve recruits, with faint borders, selection glow and synchronized profiles. Battle now uses a full-width field, bottom company/equipment/overview panel, contextual radial choices and clear active-fighter/visible-target highlights. [Current verification, controls, build and limits](DESKTOP_UI_017_STATUS.md). Earlier version sections below are historical.

# Current PC slice — 0.16.0

The existing vertical slice now has native desktop sizing, configurable keyboard controls, a persistent tactical crew/action bar, a resizable inspector, focus-safe pause behavior and cached actor rendering. See [PC validation, controls, reproduction and limits](PC_VALIDATION.md) and [the complete acceptance scope](PC_VERTICAL_SLICE.md). The full Greywake campaign, final assets/audio and new Android acceptance remain outstanding.

The earlier version sections below are historical evidence for their own builds.

# Requested production pass — 2026-10-26

The user requested completion of items 1-6, extra attention to item 1, then an offensive/defensive combat feature pass. Implemented scope:

1. Melee/equipment: deliberate disengage and visible reaction preview; normal/power/feint/thrust attacks; selected body targets; shield/parry/evade/brace choices; localized severity and treatment effects; typed arrows/bolts/javelins; recoverable thrown gear; differentiated draw costs; capped four-AP turn carryover.
2. World/buildings: peaceful tactical visits and safe leave; timed exploration with queued orders and pause-on-load; single-level roofed room footprints and cutaway rendering; training/workshop variants; four selectable authored approaches; paid barricade/palisade/gate/torch construction.
3. Company/prisoners: local levy equipment ownership; prisoner release/ransom/enlistment; automatic rescue after local victory; owned horses/carts, conservation through split/merge and horse forage.
4. Escorts/jobs: persistent, targetable cart and driver; nearby driver required for cart movement; cart/driver loss fails delivery; physical cart repair; route-priced delivery/patrol postings with known-risk premiums and daily generation limit.
5. Tactical AI/visibility: actual-AP line/column/wedge orders; shield use, local medical support and rally; six-tile one-hop sightings for individual AI decisions; recent sound priority; existing panic retreat; night perception and constructed light sources; oriented fortification cover.
6. Strategic AI: facility income, troop upkeep, budgeted recruitment at staffed owned bases, expiring nearby intelligence, raid/withdraw responses, patrol return objectives and persistent army-clash casualties/loot/control.
Additional combat feature pass: real charge movement plus power strike; shield bash damage/displacement/wear; adjacent ally protection with paid directional interceptions; repair/aid support; explicit AP and reaction feedback.

Verification: mechanical/integration and rendered UI suites gate the supplied APK. See QA_REPORT.md for final results. These are original, bounded implementations: one-level interiors (not multistorey buildings), strategic transport (not mounted tactical combat), discrete timed scouting pulses (not physics locomotion), and aggregate strategic clashes when the company is absent.

Follow-up phases 7 and 8 now cover application-level hardening and desktop scale/performance. Android hardware acceptance and wider source-audit/release gates remain outstanding. Full-foundation completion is not claimed.


## Save hardening and scale follow-up — 2026-10-26

Phases 7 and 8 add typed event/financial/assignment records, structural preflight before migration, verified temporary/backup commits, process-termination recovery coverage, large-map heap routing, cached selection redraws and six 45-day campaign/replay scenarios. See HARDENING_SCALE.md and the raw profile/extended reports for exact evidence and limitations. The physical Android gate (phase 9) and wider source/parity/release audit (phase 10) remain open. No additional JA2 source was copied or newly audited in this follow-up.


| Follow-up phase | Status |
|---|---|
| 7 Save/state hardening | Implemented; malformed records, backups and process interruption verified |
| 8 Scale/performance and extended checks | Implemented; 32/80/160 desktop profiles, faster routing/redraw and six 45-day campaigns |
| 9 Android acceptance | Emulator functional checks completed as requested; physical-phone gate remains open |
| 10 Wider source/parity/release audit | Focused technical audit and release-content checks completed; commercial rights review remains external |


The 9/10 follow-up adds native Android gestures, touch cancellation/pause cleanup, safe-area handling, scroll propagation fixes, repeatable OS-input testing and explicit acceptance gaps. See ANDROID_QA.md and CONTRACT_ACCEPTANCE.md. Emulator acceptance is scoped separately from physical-phone acceptance.


## 0.14.0 Greywake recruitment follow-up

The exact user-supplied twelve-template baseline is implemented as original project data, with a separate production scenario, paid opening company, canonical carried weapons and deterministic scheduled mainland offers. No external source code or weapon statistics were imported. See GREYWAKE_RECRUITMENT_STATUS.md for evidence, strict deadline/ownership/save rules and explicit upstream island/recovery limitations. Original campaign, combat formulas, AI knowledge and renewal accounting are preserved.


## Greywake Opening Experience v0.1 — 0.15.0

The user-supplied opening specification is preserved in GREYWAKE_OPENING_EXPERIENCE_SPEC.md. The integrated narrative/tableau/island/dockside work and its verification are documented in GREYWAKE_OPENING_STATUS.md. All new scene plates are temporary original vectors; no unavailable production archive or proprietary art is claimed. Existing authoritative combat, inventory, skills, payroll and shipping are reused. Island boundaries and explicit safe staging migration are simulation rules. The three endings, broader political content and final art/physical acceptance remain deferred.

## 2026-10-27 — partial v0.2 art

Eight supplied UI textures are integrated into real Greywake controls; duplicate ZIP deduplicated. Canonical roster and existing gameplay are preserved. Unmapped provisional portraits/boards are reference-only; the standalone scenes/map are absent. See GREYWAKE_ART_V02_STATUS.md and ui-art-results.json for current evidence and remaining assets.

## 2026-10-27 — remaining scene parts received

The full seven-part v0.2 pack is now received (66 PNGs). Seven scene plates and eight UI textures are active. Baked-label/geographically mismatched maps, combat reference and unmapped portraits remain reference-only. See GREYWAKE_SCENE_ART_STATUS.md and scene-art-results.json for current evidence. Gameplay/canonical data and earlier binaries are preserved.
