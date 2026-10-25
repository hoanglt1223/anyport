# AnyPSP: Naruto: Ultimate Ninja Heroes (ULUS-10299) playtest follow-ups

Date: 2026-10-25 (UTC). Repo: `repos/anypsp` (main). Build: `out/linux-pt` (clang, Release, Ninja). Scratch: `/home/ubuntu/anyport/scratch-out/unh1-fu/`.

## Outcome

| # | Item | Verdict | Change |
|---|------|---------|--------|
| 1 | Load Game with an empty memstick returns silently | Not an HLE result-code bug. The codes match PPSSPP. The missing "There is no data" text is drawn by the PSP's system savedata dialog, which the native AnyPSP build does not render. | None |
| 2 | Audio clipping in battle | The mixer is faithful. Full-scale samples come from music (ATRAC3+, ch 1) plus voice (mono ATRAC3+, ch 2, decoded to ~0 dBFS) summed at full channel volume, which also saturates in PPSSPP. While tracing this I found a real SAS bug: `__sceSasCoreWithMix` applied its volumes to the voices, not to the buffer, so UNH1 played **no SAS sound effects at all**. | Fixed, commit `d28d6cf` |
| 3 | Save write and load | Works. A save is written to `--ms`, and a fresh boot loads it and restores the edited profile. | None |
| 4 | Round timer rate | Not a bug. One timer unit is exactly 120 vblanks (60 game frames at 30 fps, 2.0 s of PSP time) in both deterministic and normal mode. The guest gets PSP-correct vblank and clock rates, so this rate is the game's own. | None |

Frame hashes of the input4 run (6000 vblanks) are identical before and after the fix (`base/h.txt` vs `sas/h.txt`). ctest passes (6/6) with the fix.

## 1. Load Game with an empty memstick

Evidence:
- Run `load/` (input `1500:4000`, no Up). Log: `[savedata] mode 8 ULUS102990000 file DATA.BIN` at boot, then `[savedata] mode 4 ULUS10299 file DATA.BIN` after Cross. Mode 4 is LISTLOAD.
- `runtime/host/savedata.cpp`, LISTLOAD branch: with no matching save, `sd.slots` is empty, so it stores `kLoadNoData = 0x80110307` and finishes with status 1→2→3 and no dialog.
- PPSSPP `Core/Dialog/PSPSaveDialog.cpp`: LISTLOAD with `GetFilenameCount() == 0` shows `DS_LOAD_NODATA` ("There is no data"). On cancel it sets `SCE_UTILITY_SAVEDATA_ERROR_LOAD_NO_DATA`, which is `0x80110307` (`Core/HLE/ErrorCodes.h`). That is the same code AnyPSP returns. The mode 8 (SIZES) result `0x801103C7` for a missing save also matches `SavedataParam::GetSizes`.
- Frames (`load2/`): 1570–1580 show the game's save-utility backdrop (where the system dialog would sit), then a white flash, the game's own attract sequence, and the title. This is the game's normal path after a LOAD_NO_DATA result.
- The title cursor defaults to Load Game even when a save exists (`reload/`, frame 1475). So the default cursor is the game's design and does not depend on the save query.

Gap, not a bug: the native and desktop builds have no system savedata dialog UI. List dialogs are chosen automatically (`PSPWEB_SAVE_CHOICE` or the focus rule), and the no-data case closes at once. Rendering the system messages ("There is no data", the save and load confirmation) would be a separate feature.

Minor fidelity difference, not changed: for a missing save, SIZES writes the `"0 KB"` used-space strings where PPSSPP writes `""`. No game effect was observed.

## 2. Audio clipping / SAS

Method: temporary `DBG_AUDIO` instrumentation (reverted, kept as `scratch-out/unh1-fu/dbg-audio.patch`) logged per-channel peaks, sum overflow, SAS in/out levels and ATRAC decode peaks. `PSPWEB_TRACE_HLE` gave call counts and arguments.

Findings:
- Channels: ch 1 = stereo music, ATRAC id 0 (AT3+) into buffers `0x8E67600..`, plus the SAS grain. ch 2 = voice, ATRAC id 1 (mono AT3+, output stereo, `sceAudioChangeChannelConfig(2, 0)`), buffers `0x8E6F640..`.
- Baseline `base/run.wav`: 63 full-scale samples, all at 51–52 s (vblank ~3060, team-select voice). They are sum overflow (`sumclip`), never SAS overflow (`sasclip` = 0). Ch 2 buffers alone peak at 31000–32767, because the voice decodes to 0.97–1.18 FS. The music peaks around 17000–20000. The sum of the two saturates.
- The reference behaves the same: PPSSPP `__sceAudio.cpp` sums `(sample * vol) >> 15` per channel and then applies `clamp_s16`, and its float→s16 conversion clamps the same way (`Atrac3Standalone.cpp`). The ATRAC decoder is PPSSPP's `at3_standalone`. Verdict: no mixer bug. 63 samples out of 4.4 M is a mastering and loudness fact of the game.

SAS bug (fixed):
- UNH1 mixes SAS with `__sceSasCoreWithMix(core, 0x8C53BC0, 0, 0)`: 4525 calls by vblank 3150, left and right volume both 0, and the input buffer is always zero.
- The old code computed `existing + (voices * vol >> 12)`, so with volume 0 every SAS voice was dropped. The game's sound effects were silent.
- PPSSPP `SasAudio.cpp` `WriteMixedOutput` ("leftVol/rightVol here are how much to scale the inp content by, not the mixBuffer") and JPCSP `SoundMixer.synthesizeWithMix` both compute `(existing * vol >> 12) + voices`.
- Fix: `runtime/host/sas.cpp`, `value += (existing * vol) >> 12`. Unit test: `tests/unit/hle_tests.cpp`, "__sceSasCoreWithMix scales the buffer by its volumes and adds the voices at full level". It fails on the old code (`at(0u) == 500`) and passes now.
- Effect (`sas/run.wav` vs `base/run.wav`): the audio differs from 20 s on (menu sounds, diff RMS 700–1300) and most in battle (80–90 s, diff RMS 3700). Full-scale samples went from 63 to 70: 7 more at 84 s, from the same summing behaviour. Frame hashes are unchanged.

Commit: `d28d6cf fix(hle): __sceSasCoreWithMix volumes scale the buffer, not the voices`.

## 3. Save write and load

- Path to a save prompt (`house-prefix.txt` plus the events below): title Up, Cross; Right ×4 to Naruto's House; Cross; Cross (dismiss the hint); Down, Cross (Edit Your Profile); Cross (hint); Square (Edit); Down, Cross (Sasuke); Cross (comment); Cross (Update profile? OK); Circle; Circle (Return to Mode Select? Yes with Cross at 4700); Cross at 4900 on "Save data? YES".
- Log: `[savedata] mode 5 ULUS10299 file DATA.BIN` (LISTSAVE), then `[savedata] chose 0000 -> 0x0`.
- Files in `house/ms/PSP/SAVEDATA/ULUS102990000/`: `DATA.BIN` (4404 B), `PARAM.SFO` (4912 B; TITLE "NARUTO: Ultimate Ninja Heroes", SAVEDATA_TITLE "Save Data", DETAIL "Play Time 000:00:47 / Rank: ACADEMY"), `ICON0.PNG` 144×80, `PIC1.PNG` 480×272.
- Reload (`reload/`, copy of that memstick, Cross on Load Game at 1500): `mode 4 ... chose 0000 -> 0x0`, then MODE SELECT. `reload2/`: Naruto's House, Edit Your Profile shows Sasuke and "This fight is mine!", so the saved profile was restored.
- Heroes Mode stage 1 clear (`save1/`, 24000 vblanks) shows Stage Clear, Result and Stage 2 with no save prompt. The course saves only at its end or on exit.

## 4. Round timer

- `timer-ticks.py` hashes the thresholded timer digits (crop 222,8–258,32) every 5 vblanks. Digit strip `ticks.png`: 99@4790, 98@4920, 97@5040, 95@5280, 94@5400, 93@5520, 68@8520, 67@8640, 66@8760, 65@8880, 64@9000.
- From 98@4920 to 68@8520: 30 units in 3600 vblanks, exactly 120 per unit. Every clean gap in both `t-det` (`--deterministic`) and `t-real` (normal) is 120. The first tick after "Fight" is 135, which includes the round intro.
- The game runs 2 vblanks per game frame (4504 game frames in 9000 vblanks), so one unit is 60 game frames.
- Guest time is tied to vblanks in both modes (`Kernel::now_us` caps at `frame_start_guest_us_ + kFrameUs`), and the window paces vblanks at 59.94 Hz. One unit is therefore 2.0 s of PSP time, whether the game counts frames or reads the clock. On hardware it cannot be faster; it would only be slower if the PSP dropped frames.
- The playtester's 135 vblanks per unit included the round intro and pause-menu time.

## Commits (not pushed)

- `d28d6cf fix(hle): __sceSasCoreWithMix volumes scale the buffer, not the voices` (`runtime/host/sas.cpp`, `tests/unit/hle_tests.cpp`).

No user-visible option or behaviour documented in `docs/user/desktop.md` changed, so the docs are not updated.

Note: another session committed `e40df0f` and `2f21c41` to main during this work. `d28d6cf` sits on top of them and touches only the two files above.

## Unresolved questions

- Should AnyPSP render the system savedata messages ("There is no data", save and load confirmations) in the desktop window? That is a feature decision, not a bug.
- In Edit Your Profile the NAME field is blank, and the log says `[font] no system fonts in <cache>/unh1-208619520/flash0/font`. Is a firmware font expected there, and does a real PSP show the nickname? Not investigated (out of scope).
- Hardware check (PSP-3000): confirm one timer unit is about 2 s and that the voice and music overlap at team select is as loud there.
