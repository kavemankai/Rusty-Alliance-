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
| 9 Android hardware acceptance | Open; needs a physical device or emulator |
| 10 Wider source/parity/release audit | Open |
