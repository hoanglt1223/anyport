# UNH 1 at 60 fps with correct game speed: frame interpolation

## Result

UNH 1 now renders 60 distinct pictures per second at the original game speed. The game is not patched:
its code, timers, input and sound run as before, and every frame the game draws is shown unchanged. A new
opt-in GE feature draws the extra picture on the vblank between two game frames. It is enabled with
`--interpolate on` or `Interpolate = on` in `anypsp-display.ini`.

It works by drawing every primitive twice. The real draw goes to the normal GL renderer. The second draw
goes to another GL renderer, with the post-transform vertices moved half way back to the matching
primitive from the previous game frame. That in-between picture is shown on the vblank where the new
frame appears.

anypsp commit `b234c6f` `feat(gpu): frame interpolation for games drawing at 30 fps` is local and not pushed.

## Verification (anypsp-play, interpreter, `--deterministic`)

- **Intro, logos and title, 1500 vblanks:**
  - Every vblank that shows a game frame is byte-identical to a run without interpolation (0 even-vblank hash differences).
  - Game frames stay at 754, the same as the baseline, so the logo, intro and title idle timers keep their timing.
- **Old input script up to a battle, 9000 vblanks:**
  - The game reaches the battle, and the round timer runs from 99 down to 74.
  - All real frames are identical to the baseline, and game frames stay at 4504.
  - 99.9% of primitives are paired between frames (17.9M of 17.9M).
  - In the battle, 2998 distinct pictures appear in 3000 vblanks. Without interpolation it is 1500.
- **Pictures:** contact sheets of the title scroll and the battle (camera pan, Naruto and Sakura moving) show coherent in-between pictures with no artifacts.
- **Tests:** `ctest` in out/msvc passes 6/6, with new tests in `tests/unit/ge_interp_tests.cpp` and `display_tests.cpp`. The build is warning-free.

## Why the patch approaches fail (static analysis of the local BOOT.BIN)

Relocated base is 0x08804000.

- **Main loop at `0x08804218`:** it calls `wait(sys)` at `0x0880AA1C` with `sys = *(u32*)0x08C20C70`. That waits on `sceDisplayWaitVblankStartCB`, then waits `sys[1] - sys[0]` more vblanks. The loop then calls `0x08846C70`, which wakes the game thread and polls `sceKernelReferThreadStatus` until it is done.
- **Who reads the interval:** about 50 sites read the interval byte `sys+1`. They convert seconds to frames as `60/interval` (for example `0x0889C33C`, `0x088B3C98`, `0x088DF6F8`), and `0x088A2C50` handles both intervals 1 and 2. Some scenes set it to 1 natively (`0x089ADE98`, `0x089AE954`, `0x089B3C24`).
- **Patch tried:** I changed every `li 2` before an interval write to 1 (12 sites, starting at `0x08947260`). The game rendered at 60 fps, but the logo still ended in 62 vblanks instead of 124, so the logo and intro timers are hard-coded frame counts.
- **Conclusion:** halving per-frame logic would need per-object game hooks. GE interpolation avoids that.

## Files

- `runtime/host/ge_interp.{hpp,cpp}`: `FrameMatcher`, which pairs primitives by vertex address and occurrence, falls back to shape in drawing order, and keeps one previous frame.
- `runtime/host/ge.{hpp,cpp}`: `emit_with_in_between`, which skips clears, continuation primitives, and jumps of more than a quarter of the screen (96 px in 2D).
- `runtime/host/kernel.cpp`: a flip to another buffer rotates the matcher.
- `runtime/host/ge_gl.{hpp,cpp}`: an in-between mode that never writes guest memory, forwards CPU writes, and resets the GL cache.
- `runtime/gpu/in_between.{hpp,cpp}`: a renderer that sends each call to both renderers or to one of them.
- `runtime/gpu/gl_host`: `enable_in_between`, `render_in_between` and `capture_in_between`.
- `runtime/gpu/display_loop.cpp` and `main_gpu.cpp`: when `previous == 2` they show or capture the in-between picture, unless it differs from the new frame by more than 10%. The headless run prints interpolation stats.
- `docs/user/desktop.md`: new "Frame interpolation" section, and the UNH 1 patch notes are updated.

No hook mechanism was needed, so there is no `docs/dev/game-hooks.md`.

## Not done (PC shutdown)

- The translated runner build in `out/runners/unh1-60` failed: the compiler ran out of heap and the paging file was too small (memory pressure, not a code error; 17 of 33 units were compiled). Resume it with nothing else building, or with ANYPSP_RUNNER_JOBS=2.
- Nothing was observed in a visible window: the windowed path (`display_loop`) was compiled but not run.

## Resume from here

1. Run `cmake --build out/runners/unh1-60 --config Release --target anypsp-run-unh1-gpu` in `repos/anypsp` (ANYPSP_RUNNER_JOBS=4 is already configured).
2. Smoke test it headless:

   ```
   out/runners/unh1-60/Release/anypsp-run-unh1-gpu.exe "<ISO>" --headless --deterministic --frames 1500 --hashes h.txt --interpolate on
   ```

   Expect 754 game frames and an "interpolation:" line.
3. Then launch it for the user:

   ```
   D:\Projects\personal\anyport\repos\anypsp\out\runners\unh1-60\Release\anypsp-run-unh1-gpu.exe "D:\Games\roms\psp\[Downloadgamepsp.com] Naruto_Ultimate_Ninja_Heroes_USA.iso" --window --interpolate on
   ```

   It works now with the interpreter, but slowly:

   ```
   out\msvc\Release\anypsp-play.exe <iso> --interpolate on
   ```

4. Check the window title for "interpolated" and about 60 shown fps on the real display.

## Questions

- Should interpolation be on by default for ULUS-10299, for example through a per-game display default? For now it is opt-in only.
- Is there a hotkey slot to use? None was added, to stay out of the menu redesign's input files.

Status: DONE_WITH_CONCERNS
Summary: GE-level frame interpolation gives UNH 1 60 distinct pictures per second while game frames stay identical to the unpatched game (verified deterministically through the intro, menus and a battle). The translated runner `unh1-60` build was interrupted by the shutdown; the feature is committed as b234c6f.
