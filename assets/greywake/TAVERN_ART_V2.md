# Interactive tavern artwork, v2

User-approved direction: select all twelve recruits directly inside the tavern painting, keep the name menu, show faint borders and a soft selected glow, and open the same profile.

Built-in image_gen was used on 2026-10-28 to edit the supplied tavern reference into a twelve-person scene. Runtime asset: `scenes/03_tavern_recruitment_interactive_v2.png`, 1672×941 pixels. The original supplied `03_tavern_recruitment_1920x1080.png` remains preserved in source. The generated file was copied from the Codex generated_images folder into this project; runtime has no dependency on that external folder. No external image API or fallback CLI was used.

The new scene's working appearance mapping is explicit in `ui/tavern_scene.gd`. Back row left to right: Militia Spearman, Militia Crossbowman, Oswin, Ada, Nessa, Sabine. Front row: Mara, Bram, Elin, Garran, Roderic, Ysra. Click regions use normalized coordinates and the actual aspect-fit painting rectangle. A profile uses an AtlasTexture view of the same painting, not a separately mismatched face.

These are provisional scene appearances for the approved interaction. Painted clothing/equipment is illustrative; canonical inventory and roster data remain authoritative. Final fitted equipment/art acceptance is not claimed. The original unmatched portrait pack is still reference-only. No stats, identities, hiring fees, wages, inventories, campaign rules or saves were rewritten.

The faint regions and glow are native UI layers, not painted into the asset. They remain synchronized with the name menu and profile, including when browsing unaffordable or already hired candidates. Merely selecting a person never hires them.

The exact built-in edit prompt is preserved in TAVERN_IMAGE_PROMPT.txt beside this file.
