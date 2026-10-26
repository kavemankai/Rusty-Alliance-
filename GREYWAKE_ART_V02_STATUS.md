# Greywake partial v0.2 art integration — 0.15.1

## What is actually supplied

Five uploaded ZIPs contain four distinct archives. The two UI/preview ZIPs are byte-identical. All members were checked for safe relative paths before extraction. The combined delivery contains 55 PNGs: 24 UI images, 24 portrait images (12 full plus 12 thumbnails), five concept boards and two overview previews. All PNGs decode successfully. Hashes and exact disposition are recorded in `art_reference/greywake_v02/import_audit.json`.

The supplied complete-pack manifest/README describe 66 PNGs, including ten standalone scene plates and one standalone map. Those eleven files are **not in these uploads**. A montage showing those scenes is a preview, not the individual backgrounds. Existing temporary scene SVGs, precise tavern hotspots, live tactical board and authored layered island are retained. No concept board was cropped, enlarged or presented as a missing standalone production asset.

## Applied to the actual game

Eight UI PNGs now render on real controls: four button states, the dark profile/panel frame, and anchor/ship/recruit icons. Native labels, costs, character statistics, hit areas and input callbacks remain authoritative. Texture panels use nine-slice borders with content padding. The prior Android touch propagation fix is preserved. Greywake campaign buttons use the new skin; the original campaign's in-game theme remains unchanged.

The other sixteen UI images are imported and available for future appropriate uses; they are not exported merely to fill unused slots. This update does not introduce decorative fake controls or notifications. `ui/greywake_art.gd` handles presentation and `scripts/map_quaternius.py` explicitly selects the eight runtime textures.

## Portraits and references

The supplied portrait registry uses Farmhand, Dock Labourer, Ivo Pike, Bess Ash and other provisional identities. None identifies the approved canonical Mara/Oswin/Ada/Bram/Elin/Nessa/Garran/Sabine/Roderic/Ysra roster or the two militia templates. Similar names do not establish identity. The registry itself marks every profile unapproved and says the images are scaled concept references, originating from 320×320 crops. No fees, ages, stats or biographies are imported from those boards.

All portrait full images/thumbnails, boards, previews and original metadata are preserved under `art_reference/greywake_v02/`, with `.gdignore` excluding them from game imports. They are not assigned to people or exported to the player pack. Existing clearly labelled generic role thumbnails remain. A portrait-to-roster mapping can be reviewed separately; no new workshop table is needed. The supplied README's statement that the recruitment roster is blocked is historical and superseded by the approved `data/greywake_roster.json`.

## Current verification

Current run results are recorded in `ui-art-results.json`. The previous 0.15 source/native reports describe their exact older binaries; they are not reused as proof of this skin. Desktop tests exercise the complete real hiring/departure/battle/save flow with the supplied button textures bound to the actual controls. Original campaign controls are also exercised. Outside-source-folder package smoke checks runtime texture inclusion and exclusion of concept/portrait references.

No new Android APK or native Android acceptance run is claimed for 0.15.1. The verified 0.15 APK is preserved separately. Physical-phone acceptance remains open.

## Player build and screenshots

Extract `../broken-marches-0.15.1-windows.zip` and run `The Broken Marches.exe`. Choose New Game for Greywake or New campaign for the original scenario. Keep the .pck beside the executable.

Screenshots: [tavern](ui-art-tavern-preview.png), [island controls](ui-art-island-preview.png). Build with standard Godot 4.6.2: import `project.godot`, then export the **Windows Pack** preset, keeping the PCK with the official standard Windows runtime. Run `scripts/pack_smoke.gd` from the exported folder using `--main-pack` so source files cannot mask missing resources.

## Assets still needed

- The ten separate scene/background plates and standalone map described by the pack manifest; the map must be reconciled with the authored mask and have separate location labels/overlays.
- Approved canonical portrait mapping, followed by genuine standalone detailed portraits matching the required identities/equipment; the current supplied crops remain provisional even after mapping.
- Final native-resolution scene art, precise individual tavern layers/cut-outs and any appropriate motion treatment.
- Audio/ambience, fitted equipment visuals, missing weapon models and complete action animation remain as previously documented.

The original campaign, roster, skills, inventory, payroll, shipping, narrative anonymity and tactical rules are unchanged. Later campaign contracts, fortress encounters and three endings remain separate unfinished milestones.

Accepted desktop results: **596 gameplay + 222 opening UI checks = 818 passed, 0 failed**. The existing original-campaign UI suite reports zero failures. The isolated Windows pack smoke reports zero failures and two rendered actors. PNG integrity is **55 passed, 0 failed**. No simulation or canonical data files changed from `d766f8c`.
