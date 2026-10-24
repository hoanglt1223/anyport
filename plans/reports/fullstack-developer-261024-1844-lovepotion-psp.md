# LövePotion on PSP: the backend runs four open-source LÖVE games in PPSSPPHeadless

Date: 2026-10-24 (Asia/Saigon). Plan: `plans/261023-1558-psp-engine-runners/`, phase 04.

`repos/lovepotion-psp` (branch `psp`, from `3.1.0-development` `666f626`) now builds an EBOOT that runs
LÖVE 11 games. It covers graphics on the GE, audio, filesystem, timer, gamepad, and keyboard keys
mapped from the buttons. Four unmodified open-source games run end to end in PPSSPPHeadless at
58-60 fps, and so do the no-game screen and two self-authored test programs. Twelve local commits
are on `psp`. Nothing was pushed, and no fork was created. Nothing has run on the PSP-3000 yet.

## What was built

All of it is in `platform/psp/`; `platform/psp/README.md` is the user-facing guide.

- **Build.**
  - The `PSP` branches in `CMakeLists.txt` vendor Lua 5.1.5 (`libraries/lua51`, MIT; see its `VENDORED.md`).
  - They also add a PhysFS PSP platform file and leave out luasocket/luahttps, because Wi-Fi is never brought up.
  - `platform/psp/build.sh` runs CMake in `pspdev/pspdev` and outputs `out/psp/package/LOVEPOTION/`.
  - `MEMSIZE 1` gives the EBOOT about 52 MB on a PSP-2000 or later.
  - Our files build with no warnings.
- **Platform layer.** `libraries/psp-platform` is copied unmodified from tic80-psp (AnySWF `d8b91b8`). It provides init, the frame list, input, the audio thread, and the clock.
- **Renderer (`driver/display/GU.cpp`):**
  - At draw time, LÖVE vertices are converted to the GE layout (u, v, ABGR, x, y, z) in a 3 MB per-frame arena.
  - Projection and model matrices go to the GE unchanged.
  - The game's window size is mapped onto 480x272 through the GE viewport, so letterboxing costs nothing. Fit, stretch and integer modes are available.
  - Clears use GE clear mode, limited to the scissor.
  - Blend modes map to GE factors.
  - Stencil uses the framebuffer alpha. On the screen, alpha is write-protected except for stencil operations.
  - Points are drawn as sprites.
  - Textures and VRAM are freed only after the GE has finished the frame.
- **Textures (`Texture.cpp`):**
  - RGBA8888, swizzled, in RAM, padded to a power of two. `sceGuTexScale` keeps texture coordinates normalised.
  - Images larger than 512 px are box-downscaled on upload.
  - Canvases are stored in VRAM (983 KB, including the unused depth buffer). Canvases that are too large or don't fit are stored at reduced resolution.
  - Drawing into a canvas sets its alpha through a stencil REPLACE plus an alpha test. The GE never writes fragment alpha.
- **Audio (`driver/audio/DigitalSound.cpp`).** A software mixer behind LÖVE's voice API: 24 voices, 16.16 resampling to 44.1 kHz, looping, and pause. It is locked with a kernel semaphore.
- **Input.**
  - `love.joystick` exposes one PSP gamepad.
  - Buttons and the analog nub also send `keypressed`/`keyreleased` and answer `love.keyboard.isDown`. The defaults:
    - arrows
    - Cross → `space`
    - Circle → `x`
    - Square → `z`
    - Triangle → `c`
    - L/R → shifts
    - Start → `return`
    - Select → `escape`
  - Games or users can remap them with `t.psp.keys` in conf.lua, or with `love.keyboard.setButtonKey`.
  - `love.mouse` is a stand-in with no pointer.
- **System and window:**
  - Language, battery, firmware version and nickname come from the system.
  - Fullscreen or a zero window size means the native 480x272.
  - The fps and CPU time per frame are logged every 5 s.
- **Files:**
  - Save data goes to `ms0:/PSP/SAVEDATA/LOVEPOTION/save/<identity>`.
  - The game is `game/` or `game.love` next to the EBOOT.
  - The no-game screen images are in `romfs/` beside the EBOOT.
- **Default font.** Bitstream Vera Sans (LÖVE 11's default; the licence permits redistribution), embedded with `#embed`.

## Fixes to common code (upstream PR candidates)

- `setCanvas({canvas})` skipped the last table entry (`<` instead of `<=`), so table-form canvases never bound.
- Static sources ignored `setLooping` called before `play` (the old flag was copied).
- Missing LÖVE 11 names used by real games are now provided:
  - In `scripts/compat11.lua`: `newText`, `setNewFont`, `stencil`, `setStencilTest`/`getStencilTest`, shader stubs and `filesystem.newFile`.
  - In C++:
    - the `highdpi` and `display` window settings
    - `getPixelScale`
    - an optional display index
    - no-op gamepad mapping functions
- Modules enabled in conf.lua but not built (video, physics) are skipped with a message instead of failing.
- Lua 5.1 `goto`/labels follow LuaJIT/5.2 semantics. Two of the five games tried use `goto continue`. Jumps that leave a block with captured locals close them through a trampoline. `platform/psp/tests/lua-goto` covers this with 12 cases.

## Validation (PPSSPPHeadless, `platform/psp/run-headless.sh`)

| Program | Licence | Result |
|---|---|---|
| No-game screen | LÖVE Potion | Hearts and cartridge render |
| `tests/smoke` (self-authored) | ours | 7/7 checks pass: image, canvas, primitives, text, points, save data, audio tone; Cross arrives as `space` |
| `tests/lua-goto` (self-authored) | ours | 12/12 pass |
| GoldMiner-Rebirth (zzxzzk115) | MIT | Menu → level 1 with the hook grabbing gold; WAV + MP3 sound; 58-59 fps; frame CPU about 9.5 ms |
| love-tetronimo (Przemekkkth) | MIT | Menu → play with pieces placed; OGG effects; 60 fps (MIDI music is silent: no timidity patches) |
| Gravity-Wars (whyboris) | MIT | Aim, shot, trails and explosion; 60 fps |
| pong-video-game-lua (janaSunrise) | MIT | Loaded as `game.love`; serve and score; 60 fps (white background, as on desktop LÖVE 11, because the game passes 0-255 colours) |
| Floppy-Love2D-Game (Be1zebub) | MIT | Boots with a 3 MB MP3 that is streamed instead of fully decoded, then stops in the game's own `setPitch(math.random(0.9, 1.1))`. That call can return 0, and desktop LÖVE errors on it too |

Two other candidates were not testable: gridbattle needs shaders, and love-jam-2025 needs a git submodule.
The games were cloned to the session scratchpad only, and no game files are committed.

**Float versus double Lua** (`tests/lua-bench`, PPSSPP emulated time):

| Workload | Float | Double |
|---|---|---|
| Arithmetic | 139 ms | 1445 ms |
| Vectors | 664 ms | 1907 ms |
| Tables | 96 ms | 244 ms |
| Strings | 172 ms | 204 ms |

The precision cost shows: summing 1..50000 gives 1.250002e9. Float stays the default, as decided, and
`-DLOVE_PSP_LUA_FLOAT=OFF` builds with doubles. The four games ran at the same fps in both builds in PPSSPP.

## Limits (also in the README)

- No shaders.
- No depth test.
- No mipmaps.
- RGBA8 textures only.
- Non-power-of-two repeat textures wrap at the padded size.
- Partially transparent pixels drawn into a canvas become opaque.
- No on-screen keyboard: `setTextInput` does nothing.
- No mouse pointer.
- No networking and no microphone.
- Media Engine MP3 decoding is not used.

## Hardware test (needs the PSP-3000)

1. Copy `repos/lovepotion-psp/out/psp/package/LOVEPOTION` to `ms0:/PSP/GAME/LOVEPOTION`.
2. Add one game as `game/` or `game.love`: the four above, or `platform/psp/tests/smoke`.
3. Run it under psplink to see the 5-second fps and frame-CPU lines.
4. Compare them with the table above. Check that audio has no crackle and that HOME quits cleanly.
5. Watch for these GE behaviours that PPSSPP cannot confirm:
   - Canvases drawn at reduced size.
   - Texture uploads made in the middle of a frame.
   - The canvas alpha trick.

## Resume from here

1. **Hardware.** Run the test above. Phase 04 stays `in-progress` until it is done.
2. **Fifth game.** The validation calls for five LÖVE 11 games, and four pass. Look for another MIT or zlib game that uses LÖVE 11 colours (0-1), no shaders and no mouse-only menus.
3. **Gaps worth closing, by value:**
   1. An on-screen keyboard (`sceUtilityOsk`) for `setTextInput`.
   2. Mouse emulation: the nub moves a cursor drawn by the backend, and a button clicks. Many LÖVE menus are mouse-only.
   3. MP3 decoding on the Media Engine.
   4. A game picker when there are several `.love` files.
4. **Upstream.** When the user approves, fork `lovebrew/lovepotion` and push `psp`. The common-code fixes above can go upstream separately from the PSP backend.

## Unresolved questions

1. Should the games' MIDI music ship a small GUS patch set? Timidity patches have their own licences, so they are not bundled now.
2. Keep float Lua as the PSP default? It is about 3-10x faster in Lua-heavy code. It breaks integers above 2^24, which matters for IDs, `os.time()` arithmetic and `bit` operations on wide values.
3. The workspace `CLAUDE.md` still has someone else's uncommitted edits, which the last report noted. This session only added the LövePotion command lines.

Status: DONE_WITH_CONCERNS
Summary: The LövePotion PSP backend builds in pspdev Docker and runs the no-game screen, two self-authored tests and four unmodified MIT LÖVE games (GoldMiner-Rebirth, love-tetronimo, Gravity-Wars, a Pong clone as .love) end to end in PPSSPPHeadless at 58-60 fps with screenshots, on 12 local commits on branch `psp`.
Concerns/Blockers: Nothing has run on the PSP-3000. Four of the five games the plan asks for pass. There is no on-screen keyboard and no mouse pointer.
