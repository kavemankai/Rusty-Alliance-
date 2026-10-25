# Schema-1 regression fixtures

These are actual saves emitted by this project's previous release, commit `cbffb36bd753cd02179bf77a833c1d173d6ac101`, under Godot 4.6.2. They contain only the original fictional starting company and world fixtures.

- legacy-strategic.json: new seed-731 campaign saved through the original save_to method.
- legacy-tactical.json: accepted Redbank, travelled, entered battle, moved Mara to (4,3), set her weapon condition to 63, then saved through the original method.
- legacy-corpse.json: same active encounter with hostile_0 at zero HP and the original name-only weapon loot record at its location. This reproduces the old corpse/ground ownership ambiguity.

The previous implementation was extracted to the workspace work/schema1-fixture directory and used to generate these files. Tests load these read-only and write migrated output to separate user:// test slots. Do not regenerate fixtures using the new save code: that would cease to test backwards compatibility.

schema2-strategic.json and schema2-tactical.json were generated from this project's next previous release, commit a5240f2. The strategic fixture splits Oswin into another squad, recruits one levy using the old counter and sets local training to 40. Its original global food/medicine/tools totals are 60/12/12. The tactical fixture travels to Redbank and moves Mara to (4,3) before saving. These verify supply conservation, trained-profile creation and active-battle context during schema-2→3 migration.
