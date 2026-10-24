# Display timing options for AnyGBA and AnyPSP

## Smoothing landed first (lead's order)

The safe smoothing mode is in both projects. It is off by default and can be switched while playing.

- AnyGBA `6e5be07` `feat(video): optional motion smoothing between frames on high-refresh monitors`. Toggle it with the
  Video page row "Smoothing", Ctrl+I (`Smoothing` hotkey), or `--video smoothing=true`.
- AnyPSP `b06b59e` `feat(desktop): optional smoothing for games drawing at 30 fps`. Toggle it with F9,
  `--smoothing on`, or `Smoothing = on` in `anypsp-display.ini`.

Neither mode warps pictures or adds wrong pixels:

- **AnyGBA:** when two frames differ only by small motion, the PPU redraws the frame with background scroll,
  affine reference points and sprite positions moved part of the way. Small motion means at most 16 px, no
  palette, register, sprite-attribute or visibility changes, and no bitmap mode or forced blank. Every other
  frame is shown as it is, with no blending.
- **AnyPSP:** when the previous game frame was on screen for exactly two vblanks, the vblank where the new frame
  appears shows a 50/50 blend of the two. If the two frames differ a lot (scene cut, over 10% mean difference
  measured on 60x34 copies), it shows the new frame as it is.

Both docs mention the added input latency: up to one GBA frame for AnyGBA, one vblank for AnyPSP.

## Commits (local, not pushed)

| Repo | Commit | What |
|---|---|---|
| anygba | `6e5be07` | Motion smoothing (`video/motion.{h,cpp}`), Video row, Ctrl+I, PPU-based tests |
| anygba | `ea636a1` | Refresh auto/manual, cadence pacing with vsync and a timer guard, VRR, sync to monitor with dynamic audio rate, menu fps and fps cap, a `Monitor` stats line |
| anypsp | `b06b59e` | Smoothing, `anypsp-display.ini`, F9 |
| anypsp | `7fd7bb3` | The same pacing set (`display_loop.{hpp,cpp}`), hotkeys F4-F8 and Pause, a title showing monitor Hz / game fps / shown fps |
| anypsp | `8e2f430` | Per-game patch files (`--patches auto\|FILE`). No UNH 1 data file ships; see below |

Another agent committed `270ed2f fix(gpu)` in anypsp while I worked. I did not touch its files.

## How the timing works

- **Game rate:** game logic always runs at the console rate: GBA 16777216/280896 = 59.7275 Hz, PSP 1e9/16683000
  = 59.94 Hz. A higher monitor rate only adds presents. The logic runs faster only through fast-forward and the
  speed setting, plus the opt-in "sync to monitor", which allows at most a 1% change.
- **Cadence:** each emulated frame n first shows on display vblank ceil(n·D/G), using integer micro-hertz so
  nothing drifts. Each present is a vsync-blocking swap.
  - A timer guard sleeps when the swap returned more than half a period early (vsync not honoured). With
    vsync, the guard re-anchors to the display clock.
  - If a vblank has already passed, its picture is skipped rather than slowing the game.
  - After a stall of 250 ms or more, the schedule restarts.
- **Manual refresh:** a manual rate that is not within 1% of the detected rate turns vsync off and uses
  timer-only pacing.
- **Auto refresh:** the monitor is detected once a second via `SDL_GetCurrentDisplayMode(SDL_GetDisplayForWindow)`,
  so moving the window to another monitor is picked up.
- **VRR:** vsync is off (SDL renderer and SDL GL swap interval 0, so tearing is allowed where the driver
  supports it). Each frame is presented when ready:
  - AnyGBA uses its old audio-led loop.
  - AnyPSP uses a 59.94 Hz timer.
  - VRR cannot be detected through SDL, so it is a setting, off by default.
- **Sync to monitor:** the game rate becomes D/k (k = 1..4) when that is within 1% of the native rate. For
  example, 60 Hz runs the GBA 0.46% faster and the PSP 0.1% faster. Sound is resampled by that factor.
- **Audio while display-paced:** the sound card no longer sets the pace. A dynamic rate control (±0.5%) keeps
  the queue near its target.
  - AnyGBA does this through its resampler.
  - AnyPSP does it through `SDL_SetAudioStreamFrequencyRatio`.
- **Caps:**
  - FPS cap: presents every ⌈D/cap⌉-th vblank (swap interval N, falling back to the timer).
  - Menu/pause cap: 30 by default, or 60.
  - Fast-forward is the only uncapped mode.
- **Stats:**
  - AnyGBA Ctrl+F gains `Monitor 144 Hz auto, vsync[, synced 60.00 fps]`. The existing `FPS x host, y GBA`
    line gives the shown fps and the game fps.
  - The AnyPSP title reads `144 Hz auto vsync / game 30 fps / shown 144 fps / 60 vblank/s [/ synced]
    [/ smoothing] [/ paused]`.

AnyPSP hotkeys: F5 refresh, F6 VRR, F7 sync, F8 fps cap, F4 pause fps, Pause key, F9 smoothing. Changes are saved
to `%APPDATA%\anyport\anypsp\anypsp-display.ini`.

## Tests

- **AnyGBA:**
  - `display_timing_tests.cpp` checks the cadence for 59.73 on 60/75/120/144/165 Hz: floor or ceil per frame,
    never a whole vblank off the ideal, and the right repeat counts. It also covers sync within 1%, cap
    intervals, audio steering and the settings round-trip.
  - `motion_tests.cpp` runs golden frames on corpus homebrew: brin_demo and sbb_reg (BG scroll) and obj_demo
    (sprite). Each check asserts that t=0.01 equals the previous frame and t=0.99 equals the current one, and
    pins the SHA-256 of the half-way picture.
  - Full `ctest -LE compat` passes 24/24. The compat run after the smoothing commit passed too.
- **AnyPSP:** `anypsp_desktop_tests` passes 21/21. It covers the settings, smoothing decisions, the cadence on
  60/75/120/144/165 Hz, sync, caps, audio steering, patch parse/apply (including pointer and `if` cases) and
  disc ID lookup.
- **Windowed runs:** windowed AnyGBA runs used SDL's dummy video and audio drivers, so no window was visible.
  300 frames took 5.4-5.6 s in every mode (default, sync, smoothing, fps-cap 30, vrr, refresh=144), against
  5.02 s of game time plus start-up. So the game rate holds and no mode speeds the game up.
- **Not tested:** real vsync blocking, VRR and high-refresh presentation could not be observed. This PC has no
  visible display for tests.

## UNH 1 60 fps patch: investigated, not shipped

- **How the game waits:** the frame wait at `0x0880AA1C` calls `sceDisplayWaitVblankStartCB` and then waits
  `interval - elapsed` more vblanks. The interval is a byte at `[*(u32*)0x08C20C70] + 1`. Scene set-up code
  writes 2 (for example `0x08963294`, `0x08987B80`, `0x0898E1A8`) or a per-scene value (`0x088818D4`).
- **Patch tried:** `vblank u8 [0x08C20C70]+1 = 1 if 2`. With `--deterministic` and 1500 vblanks, game frames
  went from 754 to 1484, so it renders at 60 fps.
- **Why it fails:** game speed is wrong. The logic counts drawn frames, so with the patch:
  - the Bandai Namco logo ends at vblank about 150 instead of 300;
  - the intro reaches the title at about 400 instead of 700;
  - the title's idle timer restarts the attract intro at about 2200 instead of after 4000.

  Both runs were deterministic and compared by frame hashes and contact sheets.
- **Result:** a data patch cannot halve per-frame speeds, so no `ULUS-10299.ini` ships. The patch mechanism is
  committed and documented, with these findings in `docs/user/desktop.md#game-patches`. I did not check
  battles separately, because the menus and intro already fail the speed requirement.

## Build dirs and launch commands

- **UNH 1:** the new runner build dir is `D:\Projects\personal\anyport\repos\anypsp\out\runners\unh1-display`
  (`unh1-lazy` was not touched). It was rebuilt after all commits, and with `--deterministic` it gives the
  same flip counts as the interpreter: 754 game frames in 1500 vblanks, or 1484 with the trial patch. A longer
  run with the trial patch confirms the 2x speed: the attract intro repeats every ~1950 vblanks instead of
  ~3800.
- **Emerald:** rebuilt with the new runtime into `D:\Projects\personal\anyport\repos\anygba\out\em-dt`, from the
  runtime package in `out\dt-prefix` and the existing `out\em\all2.log` miss log.

Emerald (the ROM is embedded). Smoothing and sync are optional; Refresh defaults to Auto. Everything is also on
the Video page (Esc), and Ctrl+I toggles smoothing:

```
"D:\Projects\personal\anyport\repos\anygba\out\em-dt\POKEMON EMER.exe" --video "smoothing=true;sync-to-monitor=true"
"D:\Projects\personal\anyport\repos\anygba\out\em-dt\POKEMON EMER.exe" --video "refresh=144;fps-cap=off;menu-fps=30"
"D:\Projects\personal\anyport\repos\anygba\out\em-dt\POKEMON EMER.exe" --video "vrr=true"
```

UNH 1 (translated runner, window). Settings persist in `%APPDATA%\anyport\anypsp\anypsp-display.ini`, and these
hotkeys work while playing: F9 smoothing, F5 refresh, F6 VRR, F7 sync, F8 fps cap, F4 pause fps, Pause.

```
D:\Projects\personal\anyport\repos\anypsp\out\runners\unh1-display\Release\anypsp-run-unh1-gpu.exe "D:\Games\roms\psp\[Downloadgamepsp.com] Naruto_Ultimate_Ninja_Heroes_USA.iso" --window --smoothing on --sync-to-monitor on
D:\Projects\personal\anyport\repos\anypsp\out\runners\unh1-display\Release\anypsp-run-unh1-gpu.exe "D:\Games\roms\psp\[Downloadgamepsp.com] Naruto_Ultimate_Ninja_Heroes_USA.iso" --window --refresh 144 --fps-cap off
```

Smoke checks: the new Emerald runs headless with all the new `--video` keys, and with dummy SDL drivers it ran
600 frames in 10.6-11.3 s, which is the game rate in every mode. The AnyPSP full `ctest` passes 6/6.

## Concerns and open questions

- Nothing windowed was observed on a real display: vsync blocking, swap interval N for the fps cap, VRR
  tearing, `SDL_SetAudioStreamFrequencyRatio` steering, or the smoothing pictures on screen. Please check
  `Monitor`/title figures on the 60 Hz and high-refresh monitors.
- **VRR is a manual setting.** SDL3 exposes no VRR query.
- **AnyPSP pause FPS:** AnyPSP has no menu, so "menu and pause" is a pause key (Pause) with a pause fps setting
  (ini `PauseFps`).
- **Interpreter speed:** `anypsp-play` with the interpreter runs UNH 1 at about 32 vblanks/s windowed (hidden-window
  test, before and after this change, also with VRR). That is the interpreter's own speed. Use the translated
  runner above to play.
- **Smoothing and the HD renderer:** AnyGBA smoothing is skipped while the HD renderer is active (internal
  scale above 1, packs, AI, widescreen).
- **Menu changes:** menu changes are rows only: Smoothing, Refresh, Variable refresh, Sync game to monitor, Menu
  FPS and FPS cap were added to the Video page with no restyling.
- **UNH 1 60 fps:** a correct-speed 60 fps patch for UNH 1 would need code changes (halving per-frame speeds),
  not data. Should that be pursued as per-game code work?

Status: DONE_WITH_CONCERNS
Summary: Both projects now have toggleable smoothing (committed first), monitor-matched frame pacing with manual
refresh, VRR, sync-to-monitor with resampled audio, menu/pause and overall fps caps, and refresh/fps figures in
the stats overlay and window title. Unit and golden tests pass. AnyPSP also gained per-game memory patch files.
The UNH 1 60 fps patch was investigated and not shipped: it renders at 60 fps but makes the game run twice as
fast. Windowed vsync/VRR behaviour is untested on this headless PC.
