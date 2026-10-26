# Provenance

2026-10-26 asset update: the user explicitly supplied and authorized `All in One - Quaternius[Patreon].zip`. Its included root/per-pack notices identify the imported art as CC0 1.0 Universal. These third-party models/textures and their rendered thumbnails are not project-authored art and do not come from JA2. Source entries/hashes and preserved notices are in `assets/quaternius/`; ASSET_COVERAGE.md distinguishes runtime use from library availability and unfinished fitting/animation work. Quaternius attribution and the supplied CC0 notice are included in THIRD_PARTY_NOTICES.txt.

Reference: kavemankai/jaggedalliance2 at 9bec381bcaec845361e13f95098faaf294435acd. The checkout includes `SFI Source Code license agreement.txt`; the inspected agreement restricts commercial use and distribution of that software and derivative works. The reference is retained outside the new project for research.

New sim/ and ui/ scripts, names, world layout, formulas, equipment values, tests and primitive icon were independently authored for this project. No JA2 source, copied tables, protected characters, maps, binaries or assets are shipped. This is a development provenance statement, not a rights opinion. Any eventual commercial release requires appropriate rights review, as required by the production contract.

Runtime: Godot Engine 4.6.2 standard, official release 71f334935, MIT licence; engine and export-template third-party notices remain applicable to the exported APK. See https://godotengine.org/license/ and engine-distributed notices. External art is the user-authorized Quaternius CC0 library described above; no music or paid services are introduced.

Build troubleshooting consulted the official Godot Android exporter implementation:
https://github.com/godotengine/godot/blob/4.6.2-stable/platform/android/export/export_plugin.cpp
It identified the Android texture-import setting behind a blank export-validation failure. This code was not copied into game rules.

Source ownership/licensing for the newly authored game remains with the applicable project owner; no open-source licence has been invented or granted by this delivery.

Schema-1 regression save fixtures were generated from this project's own previous commit cbffb36. They contain the fictional Marches world/characters, not JA2 source, campaign data or assets.

Schema-2 fixtures were generated from this project's own commit a5240f2. The schema-3 logistics and levy rules use original code, data and formulas. Additional reference inspection is limited to the persistent sector/training relationships identified in SOURCE_AUDIT.md; no JA2 militia tables or source code are included.


Phase 10: additional reference function bodies were read as documented in SOURCE_AUDIT.md. No reference C/header code, tables, campaign data or assets were incorporated. The release audit compares tracked-source hashes with research files of at least 512 bytes and checks archive/APK paths and signing-material exclusion; absence of byte-identical files is not proof of independent creation or legal clearance.

THIRD_PARTY_NOTICES.txt is generated from standard Godot 4.6.2 engine APIs, with an Android-template attribution supplement. Matching official template declarations and Maven licence metadata identify Kotlin standard library 2.1.20, AndroidX fragment 1.8.6, core-splashscreen 1.0.1 and documentfile 1.1.0 under Apache-2.0, whose text is included. Related AndroidX/Kotlin runtime families are acknowledged. This is not an exact transitive binary SBOM or a substitute for complete dependency-notice/ownership review before commercial distribution. No commercial publication or project licence grant is performed.
