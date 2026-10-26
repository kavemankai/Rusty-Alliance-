# Greywake Opening Art — Scene and Portrait Pack v0.2

Contains **individually exported scene plates**, twelve separate recruitment portrait slots (plus square thumbnails), the original no-grid island map, reusable UI art, generation boards, and an explicit file manifest.

## Important quality disclosure

The image generator produced multi-panel concept boards rather than separate native-full-resolution illustrations in this production attempt. The 1920x1080 scene plates here are **upscaled/reframed crops**; this pixel size does **not** mean the source scene contains native 1920x1080 painted detail. The portrait references originate from 320x320 concept crops, resized to 768x960 for layout integration and 512x512 for thumbnails. They should be regarded as temporary art and not accepted as final release character portraits. Original crop dimensions and provenance are recorded in `metadata/asset_manifest.json`.

There are 12 distinct files and no embedded UI text in the processed portrait areas, but the faces and names are not canonically approved. Do not promote illustrative prices, ages, stats, or character names from the concept boards to production data. Current authoritative Greywake recruitment roster remains blocked until explicit workshop approval.

## Directory overview

- `assets/backgrounds/`: 1920x1080 screen plates for title atmosphere, employer, recruitment tavern, boat, harbour/docks, tactical/reference, offshore waiting, open harbour, and map.
- `assets/portraits/full/`: 12 separate 768x960 character portraits, **scaled concept references**.
- `assets/portraits/thumbs/`: 12 separate 512x512 portrait thumbnails.
- `assets/maps/`: original hand-drawn no-grid Greywake map with baked location labels.
- `assets/ui/`: reusable panels, buttons, transparent portrait frame, status icons from v0.1.
- `assets/reference/`: five original image-generated boards for art direction.
- `metadata/portrait_registry_PROVISIONAL.json`: identity-to-file map (not a simulation roster).
- `metadata/tavern_hotspots_PROVISIONAL.json`: group-click regions for scene prototype, not final clickable art.
- `metadata/asset_manifest.csv`: per-asset source and quality labels.

## Godot integration

Copy `assets/` into `res://assets/greywake/`. Use `TextureRect` with stretch mode KEEP_ASPECT_COVERED for backplates, draw dialogue and costs with Godot controls, and have scene transitions fade a ColorRect overlay. Keep artwork display separate from gameplay state.

Treat `07_dockside_tactical_reference_1920x1080.png` strictly as a combat **reference image**; enemy rings and fighters are baked into it. Actual battles must continue using the existing live 3D tactical scene and pathfinding. Similarly the map illustration does not encode traversable connections, sectors or sea boundaries.

The background tavern includes multiple people but is not built as independently animated or movable NPC layers. The included hotspots provide starter regions for character-group selection only, not approved individual placements.

## Still required before final-art acceptance

1. Generate/paint **genuine standalone native-resolution** artwork for title, tavern, employer, boat, port, offshore vessel and any other used backgrounds.
2. Replace each low-detail, upscaled portrait with an individual high-detail illustration consistent with the approved recruitment roster.
3. Resolve faces, equipment, sex, names, fees and biographies against the final approved twelve-template data.
4. Build character cut-outs/layers and precise hotspots for a visually reactive tavern.
5. Verify small-screen and 1080p clarity and attribution/provenance before production use.
