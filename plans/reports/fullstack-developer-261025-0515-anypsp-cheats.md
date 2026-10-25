# AnyPSP: CWCheat cheats with a Cheats tab

Date: 2026-10-25 (UTC). Branch `feat/cheats` in `repos/anypsp-cheats`, rebased onto main `2c3f17b`. Commits `40f955b feat(cheats): CWCheat files with a Cheats tab in the menu` and `b1c7af5 docs: cheats on the desktop`. Nothing is merged or pushed.

## Outcome

AnyPSP now reads PPSSPP's CWCheat files and runs the cheats that are turned on after every vblank. This works in `anypsp-play`, `anypsp-interp-gpu` and the per-game `-gpu` runners, because the cheats run from `main_gpu.cpp` right after the existing `--patches` vblank writes. The in-game menu has a Cheats tab, and switching a cheat saves it back into the file as `_C1`/`_C0`.

## What was built

- **`runtime/gpu/cheats.{hpp,cpp}`** (new). The parser and code types are adapted from PPSSPP `Core/CwCheat.cpp` at `b4386554`; the credit is in `THIRD_PARTY.md`.
  - **Parsing:** handles `_S`/`_G`/`_C0`/`_C1`/`_L`, a BOM, and `//` and `#` comments. The `_S` game selection follows PPSSPP: a file for a single game is used even if its ID differs. Unknown lines become warnings.
  - **Code types:** 0/1/2 (writes), 3 (increment/decrement), 4/8 (serial writes), 5 (copy), 6 (pointer writes, including walks, 0x9 lines and copy), 7 (OR/AND/XOR), B (delay, a no-op as in PPSSPP), C (code stopper), D (value, address and joker conditions) and E (multi-line conditions).
  - **Refusals:** a cheat containing a 0xA code (vibration/shader), `_M` (PSP Action Replay), `_N` (TempAR), an unknown type or a malformed line is refused as a whole. The message puts the reason first, then the line, e.g. `vibration and post-processing ... are not supported (line 12: _L 0xA0000000 0x00000000)`.
  - **Saving:** `save()` changes only the `_C` digit and keeps every other byte, including CRLF line endings. It writes through a temp file and rename. If the `_C` lines moved or were renamed on disk, it refuses with an error instead of writing.
  - **One deviation from PPSSPP:** when a pointer code's base address is unreadable, PPSSPP runs the pointer code's extra lines as if they were codes. AnyPSP skips them.
- **`--cheats auto|file.ini|off`.** The default is `auto` in a window and `off` headless, so scripted runs don't pick up files from the data folder.
  - `auto` looks in `cheats/` next to the program first, then in the per-user data folder.
  - It tries `ULUS10299.ini` (PPSSPP's name, the disc ID without the dash) and then `ULUS-10299.ini`.
  - The disc ID comes from PARAM.SFO `DISC_ID`, or from `UMD_DATA.BIN` if that is missing.
  - The run log lists the loaded cheats, warnings and refusals, and ends with "cheats changed N value(s)".
  - Joker codes see the buttons the game sees: live pad, scripted `--input`, or the dialog-filtered pad.
- **Menu (`menu.*`, `menu_host.*`).** A Cheats tab sits between Controls and Settings, using the anyui Cheats icon. AnyGBA uses the same order.
  - Each cheat is a checkbox row showing its name and code count ("1 code" / "N codes").
  - Refused cheats are greyed out with the reason underneath. Pressing Cross on one shows "Cannot turn on: ...".
  - An *Import cheat file* row shows the file name and the per-user folder to copy it to.
  - Without a file, the tab says "No cheat file for this game". The host saves on each toggle and shows any save error in the menu.
  - Strings are in English and Vietnamese, in one block at the end of `strings.tsv`.
- **Docs:** `docs/user/desktop.md` has a new "Cheats" section and a Cheats entry in the Menu tab list. It notes that cheats change data, not translated code, and that PPSSPP's interval is 77 ms where AnyPSP runs them every vblank.

## Tests

- **`tests/unit/cheats_tests.cpp`** (new, 6 cases):
  - parsing and game selection;
  - every refusal reason;
  - each code type against `GuestMemory` (writes, incs, booleans, serial, copy, B);
  - pointer codes (16-bit, inverse 32-bit, 0x9, single and double walks, copy);
  - all conditions, including joker and the C stopper;
  - the save round trip (byte-exact with CRLF and BOM), `find_file` order, and refusing to overwrite a changed file.
- **`tests/unit/menu_tests.cpp`:** a new Cheats tab test covers no file, the list, toggling by key and click, saving, a refused cheat and Vietnamese text. The rail navigation test was updated for the new tab.
- **Golden pictures:** all were regenerated on Linux/clang because the rail now has 7 tabs. They include new `cheats-{1x,2x}-{dark,light}` and `cheats-none-1x-dark` pictures, which I looked at; the layout is clean and only long refusal reasons are cut off with an ellipsis.
- After the rebase onto `2c3f17b`: `anypsp_desktop_tests` passes 45/45, and `ctest` passes 6/6 (corpus_analysis is skipped because there is no corpus).

## UNH 1 headless proof

All runs used `/home/ubuntu/anyport/scratch-out/cheats`, `--deterministic`, `input4.txt` and 5400 vblanks with `anypsp-interp-gpu`.

**Finding the timer.** I took RAM dumps (a temporary patch, never committed) and compared them, then used `PSPRECOMP_WATCH_WRITE`:
- `0x09A594A8`/`0x09A594AC` hold the displayed digit, but the game rewrites them every frame, so freezing them changes nothing.
- The master value is an 8.24 fixed-point countdown at `0x0937D148`. Its top byte is the timer minus one: `0x61D999AC` at vblank 4930, while the screen shows 98.

**Test cheat** (`scratch-out/cheats/ULUS10299.ini`). It is guarded by an address-equality check and an 8-bit less-than condition, so it only writes during a round:

```
_C1 Round timer stays at 99
_L 0xD12594A8 0x412594AC
_L 0x00000002 0x00000002
_L 0xD0B7D14B 0x20200063
_L 0x20B7D148 0x63000000
```

The file also has a `_C0` cheat and a refused 0xA cheat, to exercise the log output.

**Results** against a clean main `2c3f17b` baseline, built in a temporary worktree that has since been removed:
- **`--cheats off`:** all 5400 frame hashes are identical to the baseline.
- **With the cheat:** frames are identical up to vblank 4918. They differ from 4919 to 5400 (482 frames), starting exactly when the timer would first tick to 98. The cheat changed 307 values. At vblank 5400 the timer shows **99**, against **94** in the baseline (crops `timer-cheat.png` and `timer-base.png`).
- The cheat file was not modified by the headless runs.

**Caveat:** the address is in heap memory and was found in one deterministic scripted run. It is a test code, not a general UNH 1 cheat, which is why it is not in the docs or the repo.

## Issues and deviations

- The worktree build of main at `repos/anypsp/out/linux` segfaults at startup after the incremental rebuild to `2c3f17b`. A clean build in a fresh worktree runs fine, so it looks like a stale build directory, not a code bug. I did not investigate further.
- The workspace root `CLAUDE.md` command list does not mention `--cheats`. That file is outside this repo, so I left it alone.
- All processes I started have exited. The temporary dump binary and its patch were never committed. The RAM dumps are deleted.

Status: DONE
Summary: CWCheat cheats with a menu Cheats tab, saving, docs and tests are on `feat/cheats` (rebased onto main `2c3f17b`), and a self-found UNH 1 round-timer cheat holds the timer at 99 in a headless run while `--cheats off` hashes match main exactly.
Concerns/Blockers: The main worktree's `out/linux` build crashes at startup (a stale build directory, it seems), and the UNH 1 timer address is a heap address from a deterministic run, so it is a test code only.
