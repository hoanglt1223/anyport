---
handoff-version: 1
created: 2026-10-25 05:55 UTC (12:55 Asia/Saigon)
from: Linux build box (/home/ubuntu/anyport, Ubuntu 24.04, no display)
to: Claude Code on the Windows PC (D:\Projects\personal\anyport)
supersedes: plans/handoffs/anyport-night-20261025-0150.md, plans/handoffs/anyport-linux-20261025-0510.md
---

# Handoff: Linux session -> Windows PC

Everything is pushed. Pull first: the workspace (`git pull`), `repos/anygba` (main ae90434) and `repos/anypsp` (main b1c7af5). The other repos did not change. Rules: CLAUDE.md (now with a "Linux box" paragraph and AnyPSP `--cheats`/`--dialogs`), memory `act-without-asking` (also: make small design calls yourself, state them in one line).

Caution from the night handoff: the Windows PC had an uncommitted sceCtrl rewrite in repos/anypsp (devices.cpp, kernel.*, hle_tests.cpp). It was redone and pushed from Linux as 6303975. Discard the Windows copy (`git checkout -- runtime tests` after checking `git status`), or the pull will conflict. Engine runner repos (tic80-psp, fake08-psp, lovepotion-psp) exist only on Windows and are untouched.

## Done on Linux (details in plans/reports/*261025-03xx* and *-05xx*)

- AnyGBA v0.3.1 tagged and released (CI and release green). After it on main: Video-tab live preview (before/after divider, 4x loupe, per-row descriptions) and graphics presets Very low..Ultra with Custom detection (ae90434). Not in a release yet.
- AnyPSP main:
  - 6303975 sceCtrl: 64-sample ring filled per vblank, full latch, Negative reads, validation. UNH 1 hashes unchanged.
  - e40df0f `Interpolate = auto` (default; on for ULUS-10299 in a window, off headless) and F10 toggles interpolation. F9 is still smoothing.
  - 2f21c41 Video-tab preview + presets (PSP: 1x/1x/2x/3x/3x+interp/4x).
  - d28d6cf `__sceSasCoreWithMix` volume fix: UNH 1 sound effects were silent.
  - b58bda7 system dialogs: message dialog, "There is no data.", save/load/delete lists with icons, Yes/No, "... completed". `--dialogs auto|show` (show in a window).
  - 2c3f17b sceLibFont fallback: bundled Noto fonts in PGF format (Latin, JIS X 0208 Japanese, Korean). Real fonts win: game cache flash0/font, then per-user flash0/font. UNH 1 profile NAME now shows "PSP".
  - b1c7af5 cheats: CWCheat (PPSSPP format) `cheats/<DISCID>.ini` next to the program or in the per-user folder, Cheats tab in the menu, `--cheats auto|file.ini|off`.
- UNH 1 playtest items: Load Game silent return was the missing system dialog (now drawn); clipping is music+voice at full volume (same in PPSSPP); save write/load works (Naruto's House profile change); round timer is 2 s per unit by design.
- UNH 1 controls (manual): jutsu Up,Up+Circle / Down,Down+Circle; Secret Technique Triangle then Circle with a full blue gauge; hold Down charges chakra; R guards. The user was told.
- Emerald filter comparison: https://claude.ai/artifact/YJQtCzrU8vifMNuTfQUapg (private). Recommendation `xbrz4x`. Files and route script on Linux in ~/anyport-out/emerald-filters/.
- Emerald APK (ae90434, arm64) on Linux: ~/anyport-out/android/Pokemon Emerald.apk, signed with a NEW Linux debug key, so it cannot update the phone's install. Never publish it (it embeds the ROM).

## Next on the Windows PC (in order)

1. Pull everything, discard the old uncommitted sceCtrl copy (see Caution), clean-build AnyPSP (MSVC). Incremental builds after big pulls can link stale objects (seen on Linux: crash at start); if a runner crashes at startup, rebuild clean.
2. Window checks that Linux could not do (no display), with UNH 1 in `anypsp-play` or the UNH 1 runner, `--window`:
   - Interpolation on by default (title shows `interpolated`), F10 toggles at once, F9 smoothing.
   - Load Game with an empty memstick shows "There is no data."; save in Naruto's House shows the save list; keyboard, gamepad, mouse and touch on the dialogs.
   - Video tab: preset row, divider drag, loupe (Select, mouse), descriptions in vi/en.
   - Cheats tab with a PPSSPP cheat file for ULUS-10299 (no cheat file ships; a public UNH 1 code or the user's own).
   - AnyGBA Emerald (`D:\Games\anygba\out7`): rebuild from main for the presets/preview, check the Video tab, set the filter to xbrz4x if the user agrees.
3. Build the UNH 1 translated runner with everything above, one compiler job at a time (MSVC OOMs otherwise): configure `out/runners/unh1-menu` from current main, `cmake --build ... --target anypsp-run-unh1-gpu -- -m:1`. Then remove the old worktree `repos/anypsp-menu-merge` and branches `merge/menu-redesign`, `feat/menu-redesign`.
4. APK: rebuild on Windows with its debug key (same package id `io.anyport.anygba.ga9dec84dfe7f`) so it updates the phone in place, put it in OneDrive My Games\AnyGBA\android\. Or copy `%USERPROFILE%\.android\debug.keystore` to the Linux box's ~/.android/ and rebuild there.
5. Engine runners (tic80-psp, fake08-psp, lovepotion-psp): forking/pushing is public, ask the user first; then they can be continued on Linux too.
6. Real PSP-3000 (user's hands): timer unit about 2 s, music+voice loudness at team select, engine runner EBOOTs via psplink.

## Open decisions already made (do not re-ask)
- AnyPSP Very high preset stays 3x (with interpolation); AI preview in AnyGBA shows a note, not a live AI frame.
- List delete returns to the list while saves remain; the Load icon stays.
- Japanese fallback includes JIS level 2 kanji (fonts add 2.08 MB per runner).
