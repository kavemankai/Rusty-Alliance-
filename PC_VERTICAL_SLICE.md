# PC vertical-slice rework

Objective: rework The Broken Marches so the existing playable vertical slice is optimized for PC play. This is not a new campaign-content or final-art milestone. The full objective remains active until the actual player loop and PC delivery are verified.

## Acceptance requirements

1. Desktop-native, resizable presentation at 1280×720 minimum, 1600×900 default and 1920×1080; readable UI scaling and fullscreen; no stretched fixed-resolution tactical image.
2. Consistent mouse/keyboard navigation through title, briefing, paid hiring, confirmation, crossing, island, deployment, tactical turns, outcomes and recovery. Every shortcut uses existing validated commands and the actual selected actor/preview.
3. An accessible crew strip and persistent action/preview bar during combat; accurate AP/hit previews; resizable inspector; primary controls remain available without scrolling past explanatory text.
4. PC controls: middle drag/WASD/arrows and wheel camera; center/reset; fighter numbers and cycling; confirm/cancel; end turn, reload and guard; panel navigation, help, save/load and fullscreen. Typing, native button focus, modal dialogs and key repeats must not trigger unintended commands. Bindings are configurable and persist separately from campaign saves.
5. Display preferences for UI scale, battle resolution scale, VSync and frame cap persist. Losing application focus pauses automatic campaign/exploration advancement and throttles rendering; resume never secretly fast-forwards or resumes travel.
6. Presentation-only optimizations reduce unnecessary actor reconstruction; native render resolution follows the actual board size with a bounded maximum. Verify caching and measurements rather than claiming an unmeasured speedup. Camera state survives UI rebuilds and save/load.
7. Preserve canonical roster, original campaign, deterministic combat/path/fog/AI restrictions, seven skills, inventories, injuries, progression, economic/renewal rules, Greywake saves and scheduled shipping. No free money/recruits or unverified campaign content.
8. Run the existing required source/UI suites and new PC interaction/layout/performance checks. Verify the exported Windows build outside the source checkout and provide a runnable versioned artifact, report, screenshots, reproducible commands and a recoverable pushed commit.

## Scope and limits

PC is the primary target of this rework. Touch input paths remain available; earlier Android evidence is historical and cannot verify this new interface. Missing final art, identity-approved portraits, audio, full Greywake endings and physical-phone acceptance remain clearly documented outside this PC slice objective.

## Implemented PC presentation

Desktop preferences and bindings: ui/desktop.gd. Input/settings controller: ui/pc_controls.gd. Gameplay shell, crew/action docks and camera continuity: ui/main.gd. Native viewport and redraw caching: ui/battle_view.gd. Existing map and opening presentation are adapted for desktop input/scale. All rules remain in sim/.

The requirement-by-requirement audit, exact counts, measurements, standalone evidence and remaining limits are recorded in [PC_VALIDATION.md](PC_VALIDATION.md). Machine-readable accepted results are in pc-acceptance-results.json. Delivery is recoverable through the normal repository commit and push.
