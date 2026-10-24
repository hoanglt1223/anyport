# AnyPSP: UNH 1 button combos and jutsu (interrupted)

Date: 2026-10-25, Asia/Saigon. The investigation stopped early because the PC was shutting down.

## Outcome so far

- **There is no input bug for UNH 1 at the HLE level.** Scripted headless runs on the user's unchanged runner (`out/runners/unh1-text`) show the game reacting to every combo input:
  - Tapping Triangle shows the chakra aura and turns the gauge red. This is the Secret Technique "focus".
  - Triangle then Circle starts the Secret Technique dash. Circle alone is a normal shuriken attack, and its frames differ from the combo run.
  - Holding Triangle keeps the aura on.
- **The likely root cause is how the user expects the controls to work.** The user's description matches later games, not UNH 1. The official UNH 1 manual (US booklet, pages 2, 8 and 9) says:
  - Jutsu 1 is **Up, Up+Circle**.
  - Jutsu 2 is **Down, Down+Circle**.
  - Secret Technique is **Triangle, Circle**. It works only with a full blue gauge, and the first blow must connect, or the attack fizzles after the dash.
  - Charge chakra is **hold Down**, and taunt is **Up**.
  - Guard is R.

  So "hold Triangle to charge" and "Triangle Triangle Circle" are UNH 2/3 inputs. On the keyboard the jutsu inputs use the arrow keys (d-pad).
- **What UNH 1 imports from sceCtrl** (from the BOOT.BIN import table):
  - It imports only `sceCtrlSetSamplingMode(0)` (digital), `sceCtrlSetSamplingCycle(0)` and `sceCtrlReadBufferPositive(buf, 1)`.
  - One input thread calls the read once per vblank (`0x0880a7e4`, count is `addiu a1,zero,1` at `0x0880a564`).
  - So the old HLE behaviour (current state, one per vblank) is equivalent for this game.
  - Host input: `Controls::pad()` ORs every key and button held each vblank, `key.repeat` is ignored, and it is applied before `Kernel::frame()`. There is no last-key-wins problem.

## Not yet verified: which runs still had to be checked

These two runs finished just before the stop, but I did not view their output:

- `old-uu` (Up, Up+Circle) and `old-dd` (Down, Down+Circle).
- Their image strips are in `C:\Users\nguye\AppData\Local\Temp\claude\D--Projects-personal-anyport\6abeed62-62d9-4274-ac7a-e6a4cccd14e1\scratchpad\combo\old-uu-6800.png` and `old-dd-6800.png`.
- To check them, compare them against `old-c-6800.png` (Circle alone).

## Code changes (uncommitted, not compiled)

The sceCtrl HLE now behaves like the PSP. These are accuracy fixes for other games and are not needed for UNH 1:

- `runtime/host/devices.cpp`, `kernel.hpp`, `kernel.cpp`:
  - A 64-entry sample ring, filled by `Kernel::sample_pad()` at each vblank.
  - Read returns min(count, unread) of the newest samples and blocks only when nothing is unread.
  - Peek returns the newest N samples.
  - Negative variants are added.
  - Latch now has make, break, press and release, plus the sample count.
  - Digital mode centres the stick.
  - Get/SetSamplingCycle validate the cycle. Get/SetIdleCancelThreshold are added.
  - count > 64 returns `0x80000104`.
- `tests/unit/hle_tests.cpp`: 6 new sceCtrl cases.

I did **not** commit these, because they have never been compiled or tested.

The runner build in `out/runners/unh1-input` failed: `generated_unit_0013.cpp` hit C1002, compiler out of heap, while other builds were running at the same time.

## Resume from here

1. `cmake --build out/runners/unh1-input --config Release --target anypsp_hle_tests`, then `anypsp_hle_tests.exe "sceCtrl"`. Fix compile errors and failing tests.
2. Rebuild `anypsp-run-unh1-gpu` in `out/runners/unh1-input` with nothing else building. Then run `scratchpad/combo/run.sh <exe> <outdir> "<extra input>" 7100`. The input script reaches battle by frame about 5920. Check that the frame hashes for `old-t2` and `old-c` inputs match the old runner (`old-*/h.txt`).
3. View `old-uu` and `old-dd`, confirm the jutsu starts, then commit `fix(hle): sceCtrl sample ring, latch and negative reads`.
4. Tell the user the UNH 1 inputs from the manual. Optionally add them to `docs/user/desktop.md`.

## Unresolved questions

- Did the user try the d-pad jutsu inputs (Up,Up+Circle)? Were they using a full chakra gauge for the Secret Technique?

Status: DONE_WITH_CONCERNS
Summary: The game receives combos correctly. UNH 1 jutsu are Up/Down double-tap + Circle and the Secret Technique is Triangle→Circle with a full gauge (manual), so the user was likely using UNH 2/3 inputs. The PSP-accurate sceCtrl rewrite and its tests are written but not compiled or committed.
