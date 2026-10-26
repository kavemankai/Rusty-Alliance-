# Current opening follow-up — 0.15.0

See [Greywake Opening Experience v0.1](GREYWAKE_OPENING_STATUS.md) for the current flow, authored island, tutorial/recovery work, temporary scene art and verification. The prior report below is historical; its package hashes and remaining-work statements describe that earlier build. The new runtime adds one existing CC0 barrel model (36 mappings / 33 models), retaining the 63 icons and original library provenance.

---

# Quaternius integration and remaining assets

Updated 2026-10-26 · asset preview 0.12.0

The user supplied `All in One - Quaternius[Patreon].zip` and explicitly requested using it to fill the game's asset needs. This supersedes the earlier primitives-only restriction for this work. No archive setup scripts or executable content were run.

## What is delivered

- **735 source models imported**, with materials, textures, per-pack licence notices and source paths/hashes in `assets/quaternius/manifest.json`.
- **35 runtime model mappings, using 32 distinct source models**, in `ui/asset_catalog.gd` and `assets/quaternius/runtime-map.json`. A separate authoring catalogue maps 63 thumbnails to 57 source models; icon-only geometry is excluded from player builds.
- **63 rendered transparent thumbnails**, generated from those models, in `assets/ui/icons/`. These are reusable previews; they are not 63 commissioned illustrations or unique objects.
- Tactical characters replace capsules; role appearances use the Warrior, Ranger, Cleric, Monk and Rogue models. Existing idle clips play. The original fixed weapons are hidden and supported actual equipped weapons, shields and helmets attach to the available bones. This is an initial equipment presentation, not complete grip/armour fitting or full combat animation coverage.
- Tactical trees, brush, rocks, ore, walls, windows, doors, palisades, barricades, stalls, workbenches, training dummies, crops and tents use imported art. Floors, roof cutaways, light-source props, ground-loot bags and caravan carts also use the supplied models.
- Company recruitment/role thumbnails, supported inventory/stockpile item thumbnails, supply/transport button thumbnails and strategic facility thumbnails are connected to the live UI.
- Team markers, labels, selection, movement overlays and fog remain procedural. Art reads the same persisted field/visibility snapshots; it never creates blockers, changes AP, or reveals hidden live terrain.
- The source library remains available for further assembly. Export selections include the small runtime and its dependencies, not the entire 735-model library. Importing a model does not mean it appears in every existing encounter.

The three repaired texture dependencies are recorded in the manifest: the supplied base-character files requested `_png.png` names where the corresponding archive texture was named `.png`. The actual texture is copied under the requested filename; no replacement art is invented.

## Library coverage

| Imported pack/category | Source models | Coverage and limits |
|---|---:|---|
| Fantasy Props MegaKit | 94 | Furniture, storage, food props, banners, forge/workshop tools, torch, coins, bags, market and interior dressing |
| Medieval Village MegaKit | 176 | Modular walls, doors, windows, floors, roofs, fences, wagon and exterior details; complete buildings still need logical-layout-aware assembly |
| Ultimate Stylized Nature | 36 | Trees, bushes, grass, flowers and dead trees; additional OBJ-only nature variants were not duplicated into the library |
| Ultimate Fantasy RTS | 128 | Facility thumbnails, rock/ore sources and future distant settlement/building variants; whole-building meshes cannot replace tile-level tactical collision |
| Medieval Weapons | 24 | Swords, daggers, axes, bows, spear, claymore, arrow, shields and variants |
| Ultimate RPG Items | 106 | Armour-display props, bags, backpack, coins, scrolls, containers, food and inventory prop variants; armour-display props are not fitted outfits |
| Nature Crops | 102 | Crop stages and harvested produce, including wheat; the current game does not simulate all those crop species/stages |
| Modular Fantasy Outfits | 24 | Male/female peasant and ranger outfit parts/full outfits, available for fitting |
| Universal Base Characters/hair | 18 | Body and hair sources for future assembly/retargeting; superhero base appearances are not used as medieval costumes |
| RPG Characters | 6 | Role characters with embedded animations; Wizard is library-only, not introduced as a new magic class |
| Animated Animals | 6 | Horse, donkey, cow, bull, deer and wolf; horse/cart ownership remains the implemented transport system, not a new mounted-combat feature |
| Survival props | 9 | Tent, bandages, backpack, logs, bonfire and torches; modern weapons/electronics deliberately excluded |
| Universal Animation Library 1/2 | 3 | Two animation libraries plus the female mannequin; clips available for retargeting, not automatically wired into combat |
| Knight helmets | 3 | Helmet variants; actual head fit needs further checks across future character bodies |

The included root and pack notices identify these assets as **CC0 1.0 Universal**. Preserve `assets/quaternius/LICENSE.txt`, the pack notices and the provenance manifest. This record describes the supplied archive and does not replace the project's broader release review.

## Remaining work against the full asset list

“Available” means source exists in this archive. “Integrated” means the current game actually uses it. Items below remain open even where a reusable source model exists.

| Full-game asset area | Supplied/integrated now | Still needed |
|---|---|---|
| Art direction | Coherent low-poly sources and real camera previews | A game-specific style/scale/material guide, accessibility rules, faction identity sheet and approved calibration scene |
| Human bodies and heads | Base bodies, hair, outfit sources, five active role appearances | Assemble compatible medieval male/female bodies; six distinct named mercenary presets; more heads/beards/skin variants; role and civilian presets. Current role thumbnails are not identity-matched painted portraits |
| Portraits | Rendered role thumbnails in roster | Six named portraits matching final appearances, generic roster portraits, wounded/captured/dead/fatigue overlays and portrait frames |
| Factions | Procedural cyan/red team markers; banner meshes available | Four original crests, tabard/banner textures, ownership symbols and readable colour-independent faction distinctions |
| Melee weapons | Dagger, sword, axe, spear, greatsword and shield models/thumbnails; javelin reuses spear | Dedicated mace and polearm silhouettes, final grip/attachment alignment, carried/scabbard states and consistent shield variants |
| Ranged weapons/ammunition | Bow and arrow models; typed arrows/javelins thumbnail mapping | A suitable medieval crossbow, bolt model/icon, bow string/draw states, quiver and reload attachments. The archive's sci-fi crossbows were not substituted into this medieval game |
| Armour and helmets | Leather/metal armour display props and icons; three helmet sources | Fitted clothing, padded, leather, mail and plate outfits; condition/damage presentation; different body proportions; final helmet/head, shield/arm and weapon/hand fit. Display props do not complete fitted armour |
| Carried supplies/loot | Bags, backpack, food, bandages, tools, coins, chest and ground-loot presentation | Grounded medicine/tool kit assemblies, equipment-specific stow/draw rules, item damage states and final inventory icon consistency |
| Character animation | Imported idle/walk/run/attack/hit/death sources and two extra libraries; idle connected | Retarget and hook movement, turning, crouch/prone transitions, each supported attack/throw, crossbow reload, shield/parry/brace/protect, damage/death, first aid/repair/loot/construction/rally and handovers to actual actions. Do not count unused clips as finished gameplay animation |
| Settlement/farm/mine/camp/wilderness | Persisted tiles receive appropriate wall, door, roof, crop, tree, ore, stall, tent and prop art | Cohesive assembled buildings/interiors, roof-edge/corner joins, ground/road/mud/water materials, mine entrances, marsh dressing, readable terrain transitions, destruction/wear and remaining construction states |
| Furniture and props | Large reusable library; relevant cover/workshop/storage props connected | Layout-aware interior/market/camp dressing using actual logical fixtures, not decorative objects that imply nonexistent cover or block legal routes |
| Horses and carts | Wagon rendered for tactical convoy actors; transport thumbnails; animals imported | Harness/load/saddle presentation, horse/cart locomotion and rider fitting if mounted gameplay is later approved; civilian/animal ambient placement requires a separate gameplay decision |
| Strategic map | Facility thumbnails over the existing readable ownership/route grid | Finished terrain surfaces, original ownership/squad/army/caravan/contact/contract markers, map frame/legend and named-location badges |
| UI theme and icons | Functional existing theme; 63 reusable model thumbnails; item/supply/role/facility connections | Finished panels/buttons/focus/disabled states, action/status/management/tutorial/save symbols, portrait frames, bars, consistent art direction and a licensed production font/fallback set. Missing item-specific icons include unarmed, padded/clothing, mace, polearm, crossbow and bolts |
| Tactical effects | Existing procedural movement/selection/fog and actual equipment models | Weapon/armour/block/parry impacts, projectiles in flight, dust/debris/smoke/fire, support/status feedback and optional blood/decal effects; a static flame prop is not a finished animated effect |
| Sound effects | **No audio files in the supplied ZIP** | All footsteps, weapons, impacts, blocks, armour, doors, tools, loot, horse/cart, UI/objective sounds and human effort/pain voices |
| Ambience/music | **No audio files in the supplied ZIP** | Settlement/farm/forest/road/marsh/mine/camp/night layers, menu/travel/exploration/tension/combat music and victory/defeat/objective stings |
| Written/release assets | Existing original campaign text; planning documents | Finished bios/faction descriptions, tutorial/help/localization, credits presentation, original game logo/app icon, loading/key art, screenshots/trailer/store graphics after the final visual identity is set |
| Expansion assets | Some source meshes can be reused | Mounted combat, multistorey gameplay and unimplemented content are not completed by importing models; their design and implementation must precede additional asset claims |

## Verification and next priorities

Current evidence is recorded in `ASSET_QA.md` and the asset test results. The old 0.11.0 Android emulator performance measurements are **not** evidence for this art build. Recheck Android memory, frame time, readability, touch picking, cutout/lifecycle behaviour and device thermals after the art changes.

An isolated 15-model calibration preview is provided as `asset-calibration-preview.png` with the repeatable scene builder `tests/asset_calibration.gd`. It demonstrates imported art and scale; it is not a gameplay/fog test or an approved final style sheet.

1. Finalize six mercenary appearances and consistent fitted equipment; validate at gameplay zoom.
2. Retarget/connect the complete offensive and defensive animation set to actual state changes.
3. Finish the missing medieval crossbow/mace/polearm/bolts and the UI/action/status icon gaps.
4. Dress the five encounter families without altering saved collision/cover/visibility rules.
5. Supply audio/music and original faction/UI/release artwork, then repeat mobile acceptance checks.
