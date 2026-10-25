# Build status — 2026-10-25

**Playable integrated slice delivered; full production foundation incomplete.**

Target repository was empty when cloned. Local Godot source lives in this directory; origin remains https://github.com/kavemankai/Rusty-Alliance-.git. Changes are committed locally; no remote push or commercial publication is performed.

Engine: standard Godot 4.6.2 stable, official 71f334935. GDScript, Compatibility/OpenGL renderer, landscape, Android min SDK 24 / target SDK 35. arm64-v8a, armeabi-v7a and x86_64 debug architectures. No paid services or final-art assets.

Verified on Windows with NVIDIA RTX 3050 Laptop GPU:

- 87 mechanical/integration assertions pass with zero failures.
- Normal-control desktop UI scenario passes recruitment, contract, travel, deployment, combat, payment, active-battle save/load and post-victory save/load.
- Two distinct contract battles complete through legal simulation actions in the integration suite.
- Thirty-day isolated clock scenario produces exactly one wage entry each midnight.
- Godot imports and runs. Signed Android debug export succeeds; APK inspected with SDK package tools and signature verification.

No connected adb device or installed emulator was available. Android install, launch, physical touch, pause/resume under the OS and performance are **not verified**. No mobile FPS claim is made. The GitHub Actions workflow has not been run remotely.

Production gaps include additional contract types, item-instance identity and transfers, per-squad logistics, persistent local tactical maps, tactical levies, exploration/combat transitions, deeper AI/knowledge/cover/lighting, robust simultaneous encounters, save migrations and scale profiling. See IMPLEMENTATION_PLAN.md for ordered acceptance work.

Build notes: the preinstalled executable was the .NET editor and requested .mono templates. A separate official standard 4.6.2 executable was downloaded into the workspace work/ directory. The initial standard export's blank validation error was fixed by enabling Android ETC2/ASTC texture import. Project has an original primitive icon; final export should run without the earlier missing-icon error. Debug signing uses existing local development tooling; signing files/passwords are not placed in the repository.

Resume: read AGENTS.md and GAME_SPEC.md, run both suites, then continue IMPLEMENTATION_PLAN.md step 2 if no device is available. Full contract is preserved verbatim in PRODUCTION_CONTRACT.md.
