# Tavern image selection — in progress

The requested shared selection behavior is implemented: faint gold borders, a persistent soft glow on the selected recruit and live profile updates without rebuilding the entire screen. All name controls use the same candidate binding that image controls will use. No hiring, simulation, identity or equipment data changed.

Image placement remains pending the user choice between direct tavern-scene hotspots and twelve individual portrait cards. The current painting has fewer than twelve distinct, canonically mapped people. Supplied separate portraits remain provisional and unmapped; no appearance identities were silently reassigned. No new player build is claimed for this partial checkpoint. The published 0.16.0 player and its accepted report remain historical for that exact build.

Current checkpoint verification: `tests/tavern_selection.gd` 181 passed, 0 failed; `tests/opening_ui.gd` 225 passed, 0 failed; `tests/run.gd` 596 passed, 0 failed; `tests/ui_smoke.gd` 0 failed (no total counter). All exited 0 without script/error output. Selection tests click every canonical name, check profile/selection consistency, persistent glow and unchanged authoritative state.

Next: apply the chosen image layout, bind every image to the same candidate ID, verify image/name synchronization and size bounds, capture the result, export and smoke-test the updated Windows player. Keep the existing name menu and canonical roster.
