# Menu redesign merge: AnyGBA and AnyPSP

Status: DONE_WITH_CONCERNS. Both merges are committed on `main`, with fast-forward added and all tests
passing. The AnyPSP UNH 1 runner build was still compiling when the PC had to shut down.

## AnyGBA (`repos/anygba`, main)

- `ee9af77`: merge of `feat/menu-redesign`.
  - The menu loop now uses the display-timing `menu_pacer`.
  - Every Video row renders in the new Video tab: smoothing, refresh, VRR, sync to monitor, Menu FPS and FPS cap.
  - On/off switches now come from a new `video::MenuItem::toggle` flag. Before, any value reading "off" became a switch, so FPS cap, AI upscaling and Widescreen wrongly showed as switches.
  - Vietnamese strings were added.
  - A new golden `video-end-1x-dark`, plus label checks, covers the end of the Video page.
- `a3eb412` (feat): the Game tab has a "Speed" section.
  - It holds Speed, Fast-forward (hold) and Normal-speed music; that last row moved from the Audio tab.
  - Each row shows its keyboard and gamepad hotkeys.
- **Verified:** full ctest including slow passes (24/24). The Android arm64 runtime builds, with only the existing `windows_runtime` warning.
- **Built:** install package in `repos/anygba/out/mm-prefix`.
- **Launch:** `D:\Games\anygba\out7\POKEMON EMER.exe`

## AnyPSP (`repos/anypsp`, main fast-forwarded to `ec7efc3`)

The work was done in the worktree `repos/anypsp-menu-merge` on branch `merge/menu-redesign`, so the other agent's uncommitted files were never touched. Their changes to `runtime/host/devices.cpp`, `kernel.*` and `tests/unit/hle_tests.cpp` are still uncommitted in the main checkout.

- `8e4c0bc`: merge of b9a6cc1.
  - The Video tab has Smoothing, Refresh, Variable refresh, Sync game to monitor, Menu FPS (`PauseFps`), FPS cap and Game patches (on/off; "No patch file" when none is loaded). Changes save to `anypsp-display.ini`.
  - The Pause key now opens and closes the menu, which pauses the game; the old separate pause mode is gone. The menu is paced at `PauseFps`.
  - The Scaling setting (sharp) also applies to blended frames.
- `8c18760` (feat): fast-forward.
  - A `FastForward` hold binding: Space or RightTrigger by default, rebindable in the Controls tab and the ini.
  - `[player]` gains `Speed` (100-400) and `FastForwardSpeed` (150-800 or unlimited).
  - `speed.{hpp,cpp}` spreads PSP vblanks per shown picture evenly. Sound plays at the speed up to 400% and is muted above that and at unlimited.
  - The title and badge show the speed. The Game tab has a Speed section. Docs: `docs/user/desktop.md` "Speed".
- `ec7efc3`: merge of main (b234c6f, frame interpolation). Frame interpolation is added to the Video tab. Interpolation and smoothing pause while the speed is above 100%.
- **Verified:** ctest passes 6/6 (corpus skipped). The new `speed_tests.cpp` covers the speed math, and the goldens are updated.
- **Not verified:** fast-forward in a real window, because of the no-windows rule.

## Resume from here

1. **Build the UNH 1 runner.** The build was interrupted and no exe exists yet. Build from the clean worktree, not the shared checkout, because the shared one has the other agent's uncommitted kernel changes:
   ```
   cd D:/Projects/personal/anyport/repos/anypsp-menu-merge
   cmake --build D:/Projects/personal/anyport/repos/anypsp/out/runners/unh1-menu --config Release --target anypsp-run-unh1-gpu -- -m:1
   ```
   The cache is already configured with `ANYPSP_RUNNER_JOBS=4`, OPT 2 and gen `out/gen/unh1`. Use `-m:1`: `-m:2` ran the compiler out of heap.
2. **Launch:**
   ```
   D:\Projects\personal\anyport\repos\anypsp\out\runners\unh1-menu\Release\anypsp-run-unh1-gpu.exe "D:\Games\roms\psp\[Downloadgamepsp.com] Naruto_Ultimate_Ninja_Heroes_USA.iso" --window
   ```
3. **Clean up afterwards:**
   ```
   git -C repos/anypsp worktree remove ../anypsp-menu-merge
   git -C repos/anypsp branch -d merge/menu-redesign feat/menu-redesign
   ```

Nothing is pushed.

Status: DONE_WITH_CONCERNS
Summary: Both menu redesigns are merged into main with all the display options in the Video tab, the speed sections and AnyPSP fast-forward added, and tests green. The Emerald exe is built; the UNH 1 runner build must be finished with the command above.
