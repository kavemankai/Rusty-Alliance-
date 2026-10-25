# The Broken Marches — complete-game asset list

Production planning inventory • 2026-10-26

This list describes assets for a cohesive finished release of the original medieval mercenary game. It does not authorize generating/importing final art or replace the current primitives-only foundation milestone. No production assets have been created by this list.

The baseline is the implemented game: orthographic 3D tactical combat, a 16x16 strategic world, six named mercenaries, four faction identities, local levies, protected caravans, persistent equipment, exploration, buildings, construction and six contract types. Quantities below are planning estimates, not an approved content budget. They should be refined after one representative scene and character are approved.

## Priorities and counting rules

- **P0 — readability and core identity:** needed before a finished-looking playable slice can be assessed.
- **P1 — complete release coverage:** needed to replace the remaining placeholders and consistently present the implemented systems.
- **P2 — additional variety/polish:** useful after the complete asset set works.
- **Expansion — conditional:** commission only if the associated gameplay is approved and implemented.

One mesh is not one scene placement. One shared animation can serve many characters. An icon's selected/disabled states normally reuse the same icon. Do not multiply models by eight facing directions, manufacture art for all 256 sectors separately, or add category totals together when they count different kinds of deliverables.

Unless stated otherwise, listed assets are **planned / not commissioned**. Existing greybox primitives and QA screenshots are not counted as finished production art.

## 1. Art direction and reference package

| Asset / deliverable | Suggested quantity | Priority | Required coverage |
|---|---:|---|---|
| Visual style guide | 1 | P0 | Original grounded low-fantasy world; silhouettes, proportions, palette, materials, lighting, UI and effects |
| Character/equipment reference sheets | 6 role sheets + 1 common scale sheet | P0 | Soldier, hunter, physician, smith, knight and farmer; equipment attachment and body proportions |
| Environment kit reference sheets | 5 | P0 | Settlement, farm, mine, camp and wilderness; entrances, cover and roof cutaways |
| Faction identity sheet | 1 containing 4 identities | P0 | Company, bandits, nobles and free settlements; colours plus symbols/shapes |
| UI component and accessibility sheet | 1 | P0 | Phone text hierarchy, contrast, touch targets, icon rules, focus/selection and colour-independent distinctions |
| Calibration scene | 1 | P0 | A fighter, wall, door, shield, spear and tree viewed through the actual game camera |

Approve the calibration scene first. A detailed asset that cannot be read at the gameplay zoom is not ready for production.

## 2. Characters, faces and faction identity

| Asset | Suggested quantity | Priority | Notes |
|---|---:|---|---|
| Compatible base human bodies | 2–3 | P0 | Modular bodies with consistent equipment slots and animation retargeting |
| Shared humanoid skeleton | 1 rig standard | P0 | Grip, shield, back, head and projectile attachment points; documented naming |
| Modular heads | 10–16 | P1 | Include distinct heads for the six named mercenaries; reuse others for soldiers and levies |
| Hair / beard pieces | 12–20 combined | P1 | Share across heads; avoid requiring a unique character mesh for every recruit |
| Skin / hair palette variants | 6–8 palette options | P1 | Material or texture variation rather than duplicate geometry |
| Named mercenary appearance presets | 6 | P0 | Mara, Oswin, Ada, Bram, Elin and Tom; recognizable head/outfit combinations |
| Named mercenary portrait illustrations | 6 | P0 | Match their in-world appearances; neutral expression first |
| Generic roster portrait bases | 8–12 | P1 | Levies, bandits, noble troops, caravan drivers and generic recruits |
| Portrait state overlays | 5–7 shared overlays | P1 | Wounded, unconscious, dead, captured, fatigued and low morale; do not repaint every portrait for each condition |
| Human role appearance presets | 6–8 combinations | P1 | Melee infantry, archer, crossbowman, levy, leader, medic, smith and caravan driver; assembled from shared pieces |
| Faction crests / insignia | 4 | P0 | One per current faction; provide UI and world-banner versions from the same artwork |
| Banners / pennants / tabards | 3–5 reusable meshes | P1 | Apply faction identity with materials; allegiance must remain readable at distance |
| Prisoner presentation set | 1 shared set | P1 | Captured pose, restrained equipment presentation and custody marker; reuse actual character bodies |
| Ambient worker/civilian appearance presets | 4–6 | P2 | Visual population for markets, farms and workshops; not a new civilian simulation requirement |

**Reuse:** named mercenaries and enemy soldiers share the rig, most animation clips and modular armour. A levy does not need an entirely separate character production pipeline.

## 3. Weapons, armour, ammunition and carried items

These names follow the current catalogue so art can be mapped to existing item IDs.

| Asset | Suggested quantity | Priority | Required states / reuse |
|---|---:|---|---|
| Dagger | 1 base model | P0 | Held, sheathed/carried, thrown and dropped views |
| Sword | 1 base model | P0 | Held and carried; one-hand attack/parry readability |
| Axe | 1 base model | P1 | Clear head silhouette and overhead strike |
| Mace | 1 base model | P1 | Distinct blunt silhouette |
| Spear | 1 base model | P0 | Readable reach, grip and thrust |
| Polearm | 1 base model | P1 | Clearly different from spear at camera distance |
| Greatsword | 1 base model | P1 | Two-handed grip and stowed representation |
| Bow | 1 base model | P0 | Relaxed/drawn string or a small rig; held and carried |
| Crossbow | 1 base model | P0 | Loaded/unloaded presentation and reload attachment points |
| Javelin | 1 base model | P1 | Reuse the weapon mesh as the thrown projectile and ground item |
| Arrows and bolts | 2 projectile models | P0 | Separate readable projectile types; use stack icons for inventory quantities |
| Throwing stone | 1–3 small mesh variations | P1 | Reuse terrain stones where possible; inventory icon remains distinct |
| Shields | 2–3 visual shapes | P0 | Front/edge readability, bash contact and broken/damaged appearance; still one current logical shield category |
| Helmets | 2–3 visual shapes | P1 | Variants of the current helmet item, not automatically new armour rules |
| Armour/clothing sets | 5 fitted sets | P0/P1 | Clothing, padded, leather, mail and plate; fit compatible bodies |
| Belts, scabbards, quivers and small packs | 6–10 modular accessories | P1 | Shared across outfits; attached or hidden according to actual equipment |
| Medicine pack, food sack and tool kit | 3 recognizable prop families | P1 | World/depot use plus matching inventory icons |
| Coins / coin pouch | 1–2 props | P1 | Economy and reward presentation; shared coin icon |
| Loot bag / dropped equipment presentation | 1–2 reusable containers | P1 | Contents remain actual owned items; reuse weapon meshes for individual drops |
| Wear / damage appearance system | 1 shared system | P1 | Clean, worn and broken readability through tint/masks/decals; avoid a separate mesh for every condition percentage |

**Initial item icon set: approximately 28 base icons.** Cover unarmed, the ten weapon kinds, five armour kinds, shield, helmet, three ammunition types, stone, food, medicine, tools, currency, horse and cart. These icons are part of the UI icon total below, not an additional duplicate icon commission.

## 4. Character animation library

A starting production target is approximately **60–80 reusable humanoid clips**, including weapon-specific actions. Blend/additive layers and retargeting may reduce the number of separately authored clips.

| Animation family | Planning allocation | Priority | Required actions |
|---|---:|---|---|
| Locomotion | ~8 clips | P0 | Idle, walk, run, crouched idle/walk, prone idle/crawl and controlled backstep |
| Turning and posture transitions | ~8 clips | P0 | Turn left/right, standing/crouching/prone transitions and recovery to feet |
| Melee attacks | ~12 clips | P0/P1 | One-hand cuts, dagger stab, axe/mace strikes, spear/polearm thrusts, heavy two-hand attacks, unarmed attack and feint |
| Bow/crossbow handling | ~8 clips | P0 | Draw, aim/hold, release/fire, nock/load and crossbow reload |
| Throws | ~3 clips | P1 | Dagger, javelin and stone delivery; reuse compatible clips where convincing |
| Defence and engagement | ~8 clips | P0/P1 | Shield raise/block/bash, parry, evade, brace, ally protection and disengagement |
| Hits, incapacitation and death | ~8 clips | P0 | Body-location responses, stagger/knockdown, unconscious and death states |
| Support and interactions | ~9 clips | P1 | First aid, repair, loot, door interaction, construction, training and rally; shared clips for similar actions |
| Draw/stow and handovers | ~8 clips | P1 | One/two-hand gear, bow/crossbow, shield/helmet handling and item give/take |

The allocation above is approximately 72 actions, not 72 animations per character. Charge can combine run movement with an appropriate strike. Power/thrust/feint must have readable differences, but should share compatible animation layers rather than require new movement systems.

Additional delivery requirements:

- Animation events for release, impact, reload completion and foot contacts.
- Grip/socket reference poses and an attachment test for every weapon family.
- In-place locomotion as the baseline: the simulation remains responsible for grid movement and AP.
- Stable incapacitated/dead poses and a readable captured pose.
- Interrupted movement/attack transitions that do not visually complete a cancelled action.
- Eight-direction readability through rotating the 3D character; no eight-direction sprite-sheet duplication.

## 5. Terrain and reusable environment kits

| Asset kit | Suggested unique pieces / materials | Priority | Required coverage |
|---|---:|---|---|
| Ground materials / atlas surfaces | 8–12 | P0 | Grass, road/dirt, forest floor, rock/quarry, mud/marsh, crops, indoor floor and simple water edges |
| Ground transition / edge modules | 12–20 | P1 | Road junctions, terrain boundaries, raised edges and shore transitions |
| Trees and bushes | 8–12 mesh variations | P0/P1 | Different silhouettes/heights; shared materials; vegetation must not hide essential tactical information |
| Rocks, boulders and low cover | 6–10 | P0 | Full blockers versus low cover must look different |
| Elevation/cliff modules | 8–12 | P1 | Raised terrain edges, slopes and visual continuity; no implied climbable route where movement is blocked |
| Crop / field pieces | 4–6 | P1 | Repeated crop rows, cut crops and field boundaries |
| Marsh/reed vegetation | 3–5 | P1 | Wet terrain identity without expensive transparency layers |
| Shared settlement/building modules | 30–45 | P0/P1 | Walls, corners, floors, foundations, doorways, windows, roof pieces and roof ends |
| Settlement facility identity pieces | 8–12 | P1 | Market stalls, workshop, garrison and training-ground distinctions on a shared building kit |
| Farm-specific pieces | 10–15 | P1 | Barn/shed identity, fences/gates, field tools and agricultural dressing; reuse settlement modules |
| Mine-specific pieces | 10–15 | P1 | Surface entrance, supports, ore faces/heaps, extraction equipment and quarry dressing |
| Camp-specific pieces | 8–12 | P1 | Tents, bedrolls, fire ring, racks and temporary shelter; reuse shared props |
| Shared world props | 20–30 | P1 | Crates, barrels, sacks, benches, tables, stools, racks, chests, baskets and supplies |
| Doors and gates | 3–5 reusable assemblies | P0 | Open/closed motion and correct visual clearance; reuse across maps |
| Window / opening variants | 2–4 | P1 | Consistent distinction between sight openings, cover and blocked movement |
| Cutaway roof system | 1 modular convention | P0 | Roof parts grouped by room; interior floors/props remain readable when roofs disappear |

**Broad environment budget:** roughly 140–220 reusable environment/prop meshes after consolidating overlap. Treat this as a sizing estimate, not a total to add to the table again. The same pieces should build many sectors.

The release needs complete presentation for settlement, farm, mine, camp and wilderness layouts. Markets, workshops, garrisons and training grounds share the settlement kit; they do not each need an unrelated town asset pack. Surface mine entrances do not require an underground world.

## 6. Construction, transport and battlefield state

| Asset | Suggested quantity | Priority | Required coverage |
|---|---:|---|---|
| Barricade | 1 family, 2–3 orientations/variants | P0 | Directional cover face; variants can be rotations/shared modules |
| Palisade | 3–5 modules | P1 | Straight, corner/end and clear blocking silhouette |
| Constructed gate | 1 assembly | P1 | Open/closed, correct hinge and threshold; reuse gate kit if compatible |
| Torch | 1 prop + fire/light presentation | P1 | Visible source and modest night illumination |
| Construction preview | 1 reusable material/overlay | P0 | Legal, illegal and pending placement; shared by build types |
| Construction progress/repair feedback | 1 shared presentation set | P1 | Actual action progress, completion and repair state; not a new construction simulation |
| Protected provision cart | 1 chassis + 2–3 load arrangements | P0 | Targetable silhouette, wheel motion and cargo presentation |
| Disabled/wrecked cart | 1 state/variant | P1 | Show incapacitation distinctly from repairable cosmetic wear |
| Cargo dressing | 4–6 props, reused from shared props | P1 | Bags, crates, barrels and tied loads; do not commission twice |
| Horse | 1 rigged base, 3–4 coat palettes | P1/P2 | 3D model needed if displayed in camp/settlement; strategic horse icon is required regardless |
| Horse gear | 1 pack/saddle set | P2 | Strategic transport identity; not mounted tactical combat |
| Horse ambient animation | 6–8 clips if horse model is shown | P2 | Idle, walk, turn, graze/rest and basic reactions |
| Driver | 1 appearance preset | P0 | Reuse human rig/body; visually linked to cart without hiding the separate target |
| Ground loot/death markers | 2–4 shared markers | P1 | Distinguish visible loot, bodies and incapacitated people; do not reveal unseen loot |

## 7. Strategic world and map presentation

| Asset | Suggested quantity | Priority | Required coverage |
|---|---:|---|---|
| Strategic terrain tile/swatch set | 5 current types, expandable | P0 | Road, grass, forest, hills and marsh; share tactical palette |
| Facility/map symbols | 7 | P0 | Market, farm, mine, workshop, garrison, camp and training |
| Faction/ownership markers | 4 identities with shared states | P0 | Player ownership, hostile ownership and free sectors; shape/crest plus colour |
| Squad, army and caravan markers | 3 base families | P0 | Company, military group and protected caravan; selection/strength indicators |
| Horse/cart transport badges | 2 | P1 | Share the inventory icons where readable |
| Route and ETA presentation | 1 procedural set | P0 | Planned/active route, waypoints, destination and travel interruption |
| Discovery and contact markers | 4–6 | P0 | Unknown sector, discovered sector, known hostile presence and active contact |
| Contract destination/objective markers | 6 | P1 | Capture, elimination, camp assault, escort, patrol and defence; reuse board icons |
| Named-location identity art | 1 small illustration/badge per named location | P2 | Reuse the facility kit for the base release; unique landmark art can follow |
| World-map frame/legend | 1 interface set | P1 | Coordinates, terrain legend, ownership legend and clear touch selection |

**The 256 sectors are world data, not 256 unique background paintings.** Repeated terrain/materials, markers and modular encounter kits cover most of that world.

## 8. User interface assets

| Asset set | Suggested quantity | Priority | Required coverage |
|---|---:|---|---|
| Main UI theme | 1 | P0 | Panels, borders, buttons, tabs, sliders, scrollbars, dialogs, tooltips and notification surfaces |
| Theme states | 5–6 shared states | P0 | Normal, pressed, selected, focused, disabled and optional desktop hover; essential information never depends on hover |
| Item icons | ~28 base icons | P0/P1 | Catalogue coverage listed in section 3 |
| Combat/action icons | ~30–40 | P0/P1 | Move, confirm/cancel, stance/mode, turning, attacks/styles/aim, reload/throw, guard/disengage, charge/bash/protect, aid, repair, loot, build and rally |
| Strategic/management icons | ~20–25 | P1 | Recruit/renew/dismiss, squads, routes, time controls, assignments, supplies, market, ledger, prisoners and contracts |
| Status icons | ~15–20 | P0/P1 | HP/AP, bleeding, localized wounds, fatigue, morale/panic, guard/protection, incapacitation, capture and death |
| Map/facility/contract icons | ~15–20 shared with section 7 | P0/P1 | Use the same base artwork across map, board and management screens |
| Bars, pips and resource counters | 1 shared component set | P0 | Health, AP, morale, fatigue and supply/currency totals |
| Portrait frames / roster states | 1 shared component set | P1 | Selection, employment, casualty and custody states |
| Modal/notification symbols | 6–8, reused where possible | P1 | Warning, information, success, failure, confirmation, save/recovery and missing resources |
| Tutorial gesture illustrations | 6–8 | P1 | Tap/select, confirm/cancel, drag, pinch, two-finger pan, scroll and long-press only if used |
| Loading/save indicators | 1 small animation family | P1 | Loading, saving, completion and recovery/error states |
| UI font | 1 readable family | P0 | Required punctuation, numbers, names and supported languages; licence and fallback coverage supplied |
| Optional heading font | 1 | P2 | Must remain readable on phones; no decorative body font requirement |

**Expected icon scope:** approximately 100–130 unique base icons after reuse. Count item/map/action/status overlaps once. Selected and disabled states should normally be generated through the UI theme.

Screens requiring a complete, consistent layout/theme: main menu; new/load/continue; strategic map; company/recruitment; character details; contracts; inventory/equipment; supplies/depot; finances; deployment; exploration/combat; tactical inventory; prisoners/transport/construction panels; battle result; pause/settings; help and credits. The developer inspector can remain plain functional text.

## 9. Tactical overlays and effects

| Asset / system | Suggested quantity | Priority | Required coverage |
|---|---:|---|---|
| Selection and team markers | 1 shared procedural set | P0 | Selected fighter, friendly/hostile/neutral and multi-unit formation |
| Movement/reach overlays | 1 shared procedural set | P0 | Planned path, destination, AP cost, legal/illegal tile and reachable range |
| Targeting/cover/LOS overlays | 1 shared procedural set | P0 | Valid/invalid target, aim location, directional cover, obstruction and remembered sightings |
| Deployment/build overlays | 1 shared procedural set | P0 | Entry zones, facing, valid placement and construction legality |
| Fog/memory presentation | 3 coordinated states | P0 | Visible, remembered and unexplored; remembered visuals must not reveal unseen live changes |
| Melee/armour impact effects | 4–6 compact effects | P1 | Cut/pierce/blunt contact, armour strike, shield block and parry; recolour/reuse where suitable |
| Projectile presentation | 2–4 small effects | P1 | Arrow/bolt/throw readability and impact; reuse actual projectile meshes |
| Dust, debris and smoke | 3–5 shared effects | P1 | Movement, wooden/stone impacts, construction and fire smoke |
| Torch/fire effect | 1 reusable effect | P1 | Modest light and cheap flame/smoke, consistent with visibility rules |
| Support/status feedback | 3–5 symbols/animations | P1 | First aid, repair, rally, detection and guard; use grounded gestures/icons, not magical healing visuals |
| Damage and AP callouts | 1 font/style system | P0 | Numbers/text generated at runtime, not separate number-image assets |
| Optional blood/decal set | 2–4 restrained variants | P2 | Can be disabled; gameplay injury information remains visible without gore |

Target roughly 12–20 reusable effect families, with some overlap above. These are small gameplay cues, not a demand for cinematic particles. The mandatory developer overlay/scenario-launcher gap also needs implementation work; buying or drawing overlay graphics does not complete that tooling.

## 10. Sound effects, ambience and music

| Audio asset family | Suggested starting quantity | Priority | Required coverage |
|---|---:|---|---|
| Footsteps | 32–48 variations | P1 | About 8 surfaces with 4–6 variations each; shared between human characters |
| Melee swings | 18–24 | P1 | Light blade, heavy blade, axe/mace, polearm and unarmed families; reuse related weapons |
| Contact impacts | 20–30 | P1 | Flesh, cloth/leather, metal, shield wood and stone; avoid a full weapon-by-armour recording matrix |
| Block/parry/bash | 10–16 | P1 | Shield contact, metal deflection, body impact and shield break |
| Bow/crossbow/throw actions | 14–22 | P1 | Draw, release, load/reload, throw and compatible projectile impacts |
| Armour/equipment/loot | 12–18 | P1 | Gear movement, draw/stow, pickup/drop and item handover |
| Doors, gates, construction and repair | 16–24 | P1 | Open/close, latch, wood/stone work, tools and completion cues |
| Human nonverbal voices | 4–6 voice banks | P1 | Effort, pain, incapacitation, panic, rally and death; multiple variations rather than a unique actor for every generic soldier |
| Horse/cart sounds | 8–14 if these appear in the world | P1/P2 | Hooves, quiet horse sounds, wheels and cargo; reuse generic movement/contact audio |
| UI/economy/objective cues | 12–18 | P1 | Select, confirm/cancel, invalid action, recruitment, contract/payment, warning and save/recovery |
| Ambience loops/stems | 8–12 | P1 | Settlement, farm, forest, road, marsh, mine, camp and night ambience; shared wind/fire/insect layers |
| Music | 6–8 tracks | P1 | Menu, strategic travel, exploration, tension and combat; reuse with appropriate transitions |
| Short music/event stings | 4–6 | P1 | Victory, defeat, objective completion and major danger |
| Fully voiced named-character dialogue | Only after a written line list is approved | P2 | Not needed for every line or every character in the baseline release |

Provide variation, seamless loops, source recordings/session exports, sensible levels and clear licence/performer records. Important information must also have visual feedback. Include separate music, effects and voice mix controls in the integration work.

## 11. Written content and release-facing assets

| Deliverable | Suggested quantity / basis | Priority |
|---|---:|---|
| Named mercenary bios and descriptions | 6, matching the current roster | P1 |
| Background/trait explanations | 6 backgrounds plus each actual trait/rule | P1 |
| Faction descriptions | 4 | P1 |
| Named-location descriptions | One per named location | P1 |
| Item, action and status descriptions | One entry per actual item/action/status | P0/P1 |
| Contract text templates | 6 types with 3–5 wording variants each | P1 |
| Tutorial/help copy | One complete first-contract and combat walkthrough | P1 |
| Success/failure/recovery messages | Shared catalogue covering real rule outcomes | P1 |
| Localizable UI string catalogue | All player-facing text; roughly 800–1,500 keys as a planning allowance | P1 |
| Translation/font fallback package | Per approved additional language | P2 / release-language dependent |
| Game title/wordmark | 1 original master | P1 |
| Android launcher artwork | 1 master plus adaptive foreground/background and monochrome versions | P1 |
| Splash/loading identity | 1 flexible layout | P1 |
| Credits/notices | 1 maintained package | P1 |
| Store screenshots | 6–8 actual gameplay captures | P1 for store release |
| Store banner/feature artwork | Per chosen store's current requirements | P1 for store release |
| Gameplay trailer | 1 short gameplay-led edit | P2 |

Store-specific sizes should be checked when preparing the actual listing. An app icon should be exported into required sizes by tooling rather than redrawn separately for every density. English is the current baseline; additional release languages need an explicit selection before translation work is scoped.

## 12. Handoff and technical requirements

These are proposed starting constraints, to be validated on real target Android phones before a whole pack is produced.

| Area | Required handoff |
|---|---|
| Models | Editable source plus GLB export, consistent axes/scale, UVs, pivots, sockets and material names |
| Character mesh budget | Start around 3,000–6,000 visible triangles including gear at the normal gameplay level; prepare simpler LODs where measurements justify them |
| Environment budget | Repeated modules should stay simple and batchable; share meshes/materials instead of a unique draw setup per logical tile |
| Textures | PNG source; shared palettes/atlases; begin around 512–1024 for shared sets, increasing only where actual camera tests justify it |
| Materials | Compatibility-renderer-friendly materials; keep the number of materials per character/building low; normal maps/extra shader layers only when useful at gameplay zoom |
| Animation | Editable rig/clip source, named actions, loops, transition poses and event timing; clips retargeted to the common skeleton |
| UI | Editable vector/layered masters plus transparent exports or Godot theme components; readable at actual phone size |
| Audio | WAV masters, loop points and level notes; compressed runtime music/ambience exports where appropriate |
| Text | Stable localization keys with source-language copy, context and variable placeholders; do not bake UI labels into images |
| Scale | One logical tile is one Godot unit. Confirm body height/weapon grip against the calibration scene; logical reach/blocking still comes from simulation data |
| State ownership | Artwork must not become a second owner of HP, AP, inventory or position. Equipment appearance follows actual owned item IDs |
| Collision/visibility | Simple shapes and documented tile footprints; decorative meshes must not secretly change path costs, cover or LOS |
| Roofs/doors | Consistent roof grouping and door pivots; visually open doors must agree with the logical open state |
| Accessibility | Clear silhouettes, shapes and readable text as well as colour; audio cues have visual equivalents |
| Provenance | Author/supplier, source file, usage licence/ownership agreement, attribution requirements and notices recorded per asset |

Recommended asset register fields: asset ID, display name, category, logical item/facility/action ID, priority, source path, export path, owner, quantity/variants, dependencies, licence/attribution, import status, in-game review status and phone-validation status. The plan does not mark any future art as licensed or completed.

## 13. Production order

### Batch 1 — prove the visual pipeline

- One calibrated human body/rig and Mara's appearance/portrait.
- Sword, spear, shield, bow and padded armour.
- Idle, walk, one melee attack, bow shot/reload, block and hit response.
- Grass/road ground, one wall, one functioning door, one low-cover prop and one tree.
- Selection, path, target and HP/AP presentation.
- One consistent panel/button theme and a small starter icon set.
- A few footsteps, attack/block sounds and UI confirmations.

Integrate this batch into a real encounter and test touch/readability, equipment attachment, fog, doors, damage and frame pacing before producing the rest.

### Batch 2 — cover the whole existing game

Complete the ten weapon kinds, five armour kinds, six named mercenaries, shared generic troops, all required animation families, five environment archetypes, seven facility identities, cart/driver, four constructions, inventory/status/management icons and every required screen. Add full core sound coverage, help text and credits.

### Batch 3 — make the complete set cohesive

Add visual variants, remaining portraits, environmental dressing, ambience/music, accessibility/localization work, loading/recovery feedback and store assets. Optimize and validate the finished scenes on actual target phones. Polish should follow consistent full coverage rather than leave a few beautiful characters in unfinished maps.

## 14. Assets that depend on future gameplay approval

Keep these outside the baseline order:

- Mounted tactical combat: mounted rider clips, mounted equipment poses and mounted hit/death/dismount interactions.
- Multistorey/underground combat: stairs, floor transitions, additional roof/floor occlusion and matching movement/LOS rules.
- Larger bespoke castles, ruins, mountain regions or river crossings: new kit work only if these become actual playable terrain/location requirements.
- Broad diplomacy/story expansion: additional named characters, dialogue portraits, authored scenes and voiced lines after those systems/content are defined.
- Cinematics or extensive facial animation: optional presentation work, not needed to finish the existing tactical game.

Firearms, modern vehicles, copied JA2 characters/maps/assets and magical creature/spell packs are not part of this game's baseline asset request.

## 15. Asset acceptance checklist

An asset is ready only when:

- [ ] Editable source and correct export are delivered and identifiable.
- [ ] Ownership/licence and any attribution are recorded.
- [ ] Scale, pivots, sockets, materials and naming match the approved calibration.
- [ ] The asset imports into the actual project and looks correct at gameplay zoom.
- [ ] All required states/actions are covered, including damaged/incapacitated states where relevant.
- [ ] Selection, silhouettes, cover, doors and roof cutaways remain readable.
- [ ] Hidden/remembered information still obeys fog and perception rules.
- [ ] UI/audio/animation timing agrees with the authoritative action rather than implying a different outcome.
- [ ] Memory, material/draw cost and frame pacing are checked on a physical target phone.
- [ ] The asset is marked integrated/verified in the register; source delivery alone is not completion.

Implementation work to schedule alongside asset production: animation/attachment adapters, item-to-appearance mapping, theme integration, pooled effects, audio buses/settings and developer art-review scenes. These are integration tasks, not additional paintings or models, and the list does not claim they already exist.
