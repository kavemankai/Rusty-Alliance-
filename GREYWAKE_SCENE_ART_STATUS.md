# Greywake scene art — 0.15.2

## Complete receipt, provisional artwork

The remaining three distinct archive parts are now received; the fourth upload repeats the previous portrait archive byte-for-byte. Together with the earlier parts, all seven distinct pack parts are available: **66 PNGs**, comprising ten scene plates, one full map, 24 portrait images, 24 UI images, five concept boards and two previews. Archive/file hashes and classification are maintained in `art_reference/greywake_v02/import_audit.json`. The earlier missing-file report is historical.

The supplied README and manifest describe these as upscaled/reframed concept crops. A 1920×1080 export size is not proof of native painted detail. Those quality limitations remain; no native-resolution or final-release approval is asserted.

## Applied to actual gameplay

Seven scene PNGs are used: title atmosphere, anonymous employer, tavern atmosphere, crossing, Dock Town arrival, recruitment vessel and offshore vessel. The previous eight supplied UI textures remain in use. Briefing text and employer anonymity are unchanged; crossing is skippable and never spends campaign minutes. Arrival shows the port before revealing the authored live map at the contract stage.

The tavern art does not provide approved placements for the canonical twelve people. Native roster buttons are therefore grouped beneath the illustration and operate the existing real profile/hiring controls. No face in the backdrop is silently labelled Mara or another canonical identity. This is a functional illustrated recruitment prototype; individually mapped/reactive NPC layers remain unfinished.

The harbour panel selects its picture from existing saved vessel states. Offshore artwork is shown only for an offshore vessel, without exposing candidate identities. A currently docked unexpired vessel uses the recruitment-vessel picture; otherwise the port illustration is used. Actual port access, fees, hiring rules, exclusive deadlines and offers remain the shipping service's authority. Scenic soldiers/boats are not extra simulation units.

## Reference-only content

- `07_dockside_tactical_reference`: baked fighters, rings and text make it a combat reference. Actual tactical play remains the live 3D board with authoritative pathfinding, fog and actors.
- `09_open_harbour`: a soft castle/detail crop, retained for art direction rather than forced into a port state.
- `10_greywake_map_reference` and `greywake_isle_full`: baked labels, additional locations, full colour and a different coastline/placement. Dock Town is painted in the south, while the current authored logical port is northwest. Using it as a live overlay would misrepresent routes, ownership and fog. The existing 10×10/62-land layered map remains intact.
- All 12 provisional portrait identities/full/thumb files remain unmapped. The repeated ZIP supplies no new canonical approval. Existing role thumbnails remain explicitly generic.

Reference content is retained under `art_reference/` with `.gdignore`, and is excluded from the player package. Unused old employer/tavern/voyage SVG plates remain recoverable in source but are not selected for export. The island SVG remains active.

## Verification and delivery

Current run evidence is in `scene-art-results.json`; previous 0.15/0.15.1 results describe their older exact binaries and are not counted again. New UI assertions confirm the actual title/employer/tavern PNG bindings, while the full paid selection, save/load, crossing, battle/tutorial and withdrawal controls are exercised. Core mechanics and original-campaign UI are rerun. The Windows package is tested outside the source folder so missing exported dependencies cannot be masked.

The new Windows preview is `../broken-marches-0.15.2-windows.zip`. Extract and run The Broken Marches.exe with its PCK beside it. New Game opens Greywake; New campaign retains the original campaign. Build using standard Godot 4.6.2 and the Windows Pack preset. Export to a new folder; never overwrite the verified prior APKs.

Screenshots: [title](scene-art-title-preview.png), [briefing](scene-art-employer-preview.png), [tavern](scene-art-tavern-preview.png), [arrival](scene-art-arrival-preview.png), [harbour](scene-art-harbour-preview.png).

This update is desktop-verified only. No new Android native or physical-device acceptance is claimed.

## Remaining art work

- Canonical portrait mapping and final detailed individual portraits; the current low-detail crops remain provisional even after mapping.
- Label-free map artwork aligned to the actual mask and authored locations, with all presentation layers kept separate.
- Genuine standalone high-detail scenes, precise tavern character layers/hotspots and any suitable animation.
- Audio/ambience, fitted equipment and complete combat animation remain unfinished.

Canonical data, original campaign, gameplay rules, seven skills, ownership, saves, payroll/renewal and the four-day shipping calendar are unchanged. Full island content and three victory endings remain separate later milestones.

Accepted results: **596 core + 225 opening UI + 28 six-person scene checks = 849 passed, 0 failed**. Existing original-campaign UI: zero failures. Isolated Windows pack: zero failures, two rendered actors, actual scene textures present and reference map excluded. PNG integrity: **66 passed, 0 failed**. Simulation and canonical data are unchanged from `53ccc00`.
