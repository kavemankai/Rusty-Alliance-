# Greywake roster, opening company and mainland shipping

Development build: **0.14.0-greywake-recruitment**, based on `8a0a1ec`. Exact roster and initial recruitment are implemented. Scheduled shipping is implemented and tested in a Dock Town staging scenario. **The complete Greywake island campaign is not finished.**

## Playable flow

Choose **New Greywake campaign**. The mainland tavern starts with exactly 2,400 crowns and no fighters. Hire **two to six** mercenaries; the selected company pays all fees and then lands together at Dock Town. Both Elite profiles remain visible and unaffordable. Opening reservations can be removed for one exact refund before departure; provisional cheap profiles and their inaccessible kits are removed, and their IDs are never reused. Save/load and Android pause recovery retain the selection phase.

All twelve supplied profiles and all fourteen attribute/skill values are authoritative. Sabine uses the explicitly permitted dagger option. Existing ranged loadouts carry 16 typed arrows/bolts; Nessa and Ysra carry actual secondary daggers in their canonical inventory. There are no fabricated secondary weapon statistics. Ten named professionals retain canonical identities. The original campaign still starts with its existing Mara/Oswin company, 1,200 crowns and Ashford world.

After departure, direct named/template hiring is blocked. **Dock Town → Recruitment harbour** shows the calendar and vessel offers. First arrival is **Day 4, 06:00**, absolute minute **4,680**; later ships arrive every **5,760 minutes**. Manifests contain 2–4 candidates generated once on arrival and retained through saves. At least the first candidate is cheap; later slots provisionally have a one-third professional chance when one remains eligible. This weighting is an implementation default, not a locked balance decision.

A blocked vessel waits at most 1,440 minutes. Docking requires recovery strictly before its deadline. Late docking gets 2,880 minutes from actual arrival in port. A docked blockade suspends purchases without moving departure. Missed, departed and cancelled ships never reopen, refill or shift the regular calendar. All purchases validate physical stationary Dock Town presence, money, identities and global encounter state before spending anything.

## Authority and integration

`sim/greywake_shipping.gd` owns the single port-access query, absolute timing constants, manifest lifecycle, offer hiring and strict save checks. `data/greywake_scenario.json` supplies the Dock Town sector reference and friendly harbour administrations. Ownership comes from existing sectors; `port_blockade` stores only explicit authored closure reasons. `set_closure`, `grant_passage`, `cancel` and `access_changed` are authored integration hooks, not unrestricted player commands. Tactical victory and strategic occupation call the same access hook. Negotiated passage has no fabricated dialogue or free UI action.

The existing chronological campaign event queue dispatches three distinct shipping event names. Employment expiry, daily wages and renewal billing are retained unchanged. Shipping does not move time, run during battles, resurrect casualties, provide free mercenaries or mix levies with professionals. Initial purchases start the existing seven-day employment period at landing time; no full maritime crossing simulation is implied.

New production saves use `fall_of_greywake`, with namespaced `opening_voyage`, `greywake` and `shipping`. Original and older schema migrations remain intact. The earlier `greywake` infrastructure fixture/save format remains readable without silently replacing its scenario, people or world; it is not presented as the new production scenario. Manual and autosave slots remain separate from the original campaign.

## Upstream gaps and recovery risk

The completed 10×10 island terrain mask/map UI is still upstream. To avoid presenting the original 16×16 campaign as Greywake, production exposes a **Dock Town staging screen**, with a harbour ship-status marker, instead of the original map. The engine's current 256-sector backing remains an internal compatibility structure; it is not a finished island. The final island-map port icon must be connected when that map exists.

Greywake contracts, garrisons/military AI, investigation, faction consequences and three actual victory paths/endings remain later milestones. The hooded patron remains unidentified. The shipping hooks do not invent political resolutions or alter any ending conditions.

**Recovery/economy acceptance remains open.** The staging scenario has no authored paid work or overland destinations. Its initial provisions follow existing consumption and can run out before the first reinforcement vessel; employment still expires under existing rules. A complete playable recovery loop cannot be accepted until island work/travel exists and is balanced. No funds, food, wages or renewal rules were silently changed to conceal this limitation. A one-person survivor can continue using existing controls and paid port hiring, subject to actual resources and availability.

## Verification

Source suites and their saved reports:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Existing mechanical/integration `tests/run.gd` | 596 | 0 |
| Existing extended/replay `tests/extended.gd` | 796 | 0 |
| Seven-skill compatibility/progression `tests/skills.gd` | 165 | 0 |
| Asset/import catalogue `tests/assets.gd` | 812 | 0 |
| Exact roster/opening/shipping `tests/greywake.gd` | 650 | 0 |
| New rendered opening/harbour controls `tests/greywake_ui.gd` | 23 | 0 |
| Existing rendered gameplay controls `tests/ui_smoke.gd` | no assertion counter | 0 |
| Existing rendered selected-skill controls `tests/skills_ui.gd` | no assertion counter | 0 |
| Packaged PC smoke | no assertion counter | 0 |

The 650-check suite independently reads the supplied roster fixture, verifies actual kits, fees/capacity, atomic failed purchases, reserved IDs, canonical professional reuse/death, duplicate prevention, individual progression, original save compatibility, military recovery through real legal tactical actions, the exact exclusive deadlines, loaded versus continuous outcomes, multi-day scheduler behaviour, global battle blocking, cancellation and corrupt references. Rendered controls test real button input, opening and landed saves, refunds, departure, hiring, blockade and manifest persistence. Test-only setup creates controlled battles/clock states; it is never shipped as a roster replacement.

Final Android 15/API 35 dedicated-emulator verification: **62 passed, 0 failed** (basic 10, gestures 2, tactical 14, lifecycle 5, cutout 4, skills 11, production Greywake 16). The exact tested APK SHA-256 is `e312abb8f9bd531fdddbb1ad8b252b3f38003ae3e6ab5d15d8cd9732bda552d6`. `greywake-android-results.json` contains the full per-scenario evidence. The final application runtime log contains no Godot script/errors or Android fatal exception. An earlier startup attempt read stale observer telemetry; the runner was fixed to remove it before launch and complete final runs passed. Physical phone acceptance, performance/thermal/battery and complete island gameplay remain unverified.

Run source suites with the workspace Godot 4.6.2 console executable, `--path . --script tests/<suite>.gd` (use a display for the UI scripts). Reject `SCRIPT ERROR`/`ERROR` output even if a process exits zero. `tests/greywake_android_fixture.gd` generates isolated production-data clock fixtures; `scripts/android_greywake_smoke.py` uses OS input and restores the emulator's Greywake slots afterward. Full approved timing/lifecycle requirements are preserved in GREYWAKE_RECRUITMENT_SHIPPING_SPEC.md.

Future island integration must explicitly migrate the staging sector backing and pinned Greywake scenario metadata; it must not silently reinterpret existing saves as a completed island.
