# rpy2psp phase 04: the vnpsp engine

Date: 2026-10-23/24. Plan: `plans/261023-1558-renpy-to-psp`. Repo: `repos/rpy2psp`. There are three new local commits, and nothing was pushed:

| Commit | What |
|---|---|
| `56a84c6` | Converter format changes the engine needs |
| `08b432e` | The engine, tests, build, and workflow |
| `8be1ac3` | A corrupt-input regression test |

**Outcome.** The engine runs on PC. All three target games play start to finish there, headless, with saves, rollback of 55 checkpoints, and Japanese text. Every event matches the reference interpreter. The PSP side is written, and it type-checks against pspsdk's headers, but it was never built or run. The Docker daemon is not running (`docker info` cannot reach `//./pipe/docker_engine`), and WSL has no distribution. Phase 04's status is therefore `in-progress`, not `completed`: its validation (PPSSPP, then the PSP-3000) is still open.

## Built

C11 engine in `vnpsp/` (about 11,800 lines). Design and controls: `docs/dev/engine.md`.

**Phase 04 requirements:**

| Requirement | Where | State |
|---|---|---|
| Interpreter with call stack, variables, deterministic state | `vm.c`, `value.c` | Done. Values follow Python. `renpy.random` is CPython's Mersenne Twister, so seed 0 matches `refvm` |
| Backgrounds and sprites with tags, layers, ATL, transitions | `scene.c`, `atl.c`, `transitions.c` | Done. Ren'Py's attribute rule, `behind` and `zorder`. Transitions: dissolve, fade, pixellate, the wipes, slides and pushes, move/ease with enter and leave, `vpunch` and `hpunch` |
| Text box: typewriter, text tags, NVL, history, auto and skip | `text.c`, `engine.c`, `menu.c` | Done. All tags in bytecode.md, `[interpolation]` with conversions and format specs, CJK line breaking with kinsoku, side images (explicit and automatic) |
| Menus with the D-pad and analog nub | `menu.c` | Done, with key repeat. `renpy.input` gets an on-screen keyboard |
| 30 save slots with thumbnails in `ms0:/PSP/SAVEDATA/`, quick save and load, rollback of at least 50 steps | `save.c`, `rollback.c` | Done. 120x68 thumbnails, CRC-32, a script hash, and atomic writes. Rollback keeps 128 checkpoints within 2 MiB. Persistent data is stored by variable name |
| Settings: text speed, volumes, auto speed | `settings.c` | Done |
| Streaming loader, LRU cache in RAM and VRAM | `assets.c`, `gfx_gu.c` | Done. 12 MiB RAM cache with per-scene prefetch. On the PSP, a VRAM pool of about 144 KiB with LRU |
| Audio | `audio.c` | Done. minimp3 music with gapless loops, PCM and IMA ADPCM effects, a mixer with fades and channel volumes |

**Renderers:**

- `gfx_soft.c` (PC): a deterministic software renderer with the GE's DXT, CLUT and blending semantics. Frames can be hashed. The windowed PC player blits its frame through GL.
- `gfx_gu.c` (PSP): draws into the platform layer's display list.

**Platform layer:** AnySWF's, vendored unmodified in `third_party/psp-platform/`, with `VENDORED.md` naming commit `4015da9`. The anyswf repo was not touched.

**Headless driver** (`--play script.txt`): presses buttons frame by frame. Its trace has the story events, the shown text, and frame, state and audio hashes, PNG shots, and save, load and rollback. It needs no window and no audio device. A separate platform smoke run (`--headless --frames N`) uses the SDL path with a hidden window and the dummy audio driver.

**Build and release:**

- Top-level `CMakeLists.txt` with a `vncore` library, `vnpsp`, `vnpsp_tests`, and four ctest tests.
- `scripts/psp-build.sh` and `docker/psp-build.Dockerfile`, adapted from AnySWF.
- `release.yml`: a `psp` job builds `EBOOT.PBP` in the pinned pspdev image, and a `publish` job attaches it next to the Windows zip.

**Docs updated:** `docs/dev/engine.md` (new), README status and usage, `THIRD_PARTY.md`, and the rpy2psp section of the workspace `CLAUDE.md`.

### Converter changes (`56a84c6`)

- **f64 float constants.** `PUSH_FLOAT` now stores a double, and the bytecode version is 2. With f32, `0.1 + 0.2` and values like Arcance's `0.649` could not match Python. The golden listings changed by address shifts only, which I checked line by line.
- **`META` section.** It holds the game title and version for the main menu. Both join the glyph set: the Japanese title `ザ・クエスチョン` was drawing `?`.
- **`MUS1` music header.** It stores the source length and the 1105-frame encoder delay, which closes open issue 2 of the phase 02-03 report (gapless loops). `verify` checks both. Measured with minimp3, the trim gives the exact length and phase 0, and a loop repeats sample for sample.
- **Spec fix.** `bytecode.md`'s opcode table was off by one from `SAY` (0x22) onward. The code was right, and the doc now follows it.

**Open issue 3 (script hash in saves).** It is handled in the engine: each save records an FNV-1a hash of `script.vnb`, and a mismatch is refused with a message.

## Verification (PC, headless)

| Check | Result |
|---|---|
| `ctest` (unit, engine-vs-reference, test-game build, platform smoke) | 4/4 pass |
| `python -m unittest discover -s tests -t .` | 46 pass |
| Test game, every menu path vs `refvm` (one with real timing) | Identical event traces |
| The Question: 3/3 paths; Japanese build: 3/3 with real timing | Identical, 0 missing glyphs |
| Zero Echoes: every 4th of 164 finished paths (passwords typed on the keyboard) | Identical |
| Arcance: every 10th of 854 finished paths in the suite; all 854 in a one-off run during development | Identical |
| About 95 expressions and 14 format specs vs Python's `repr` and `format` | Identical |
| Save and load (test game and each target) | Same state hash and same frame hash |
| Rollback: 10 steps (test game), 55 checkpoints (Arcance), then forward again | Same states and frames |
| Same script twice | Identical traces, frames, and audio hash |
| 150 KB texture cache vs 12 MiB | Same frames, more reads |
| Music loop | Gapless and phase-continuous |
| Damaged save | Refused with a message |
| Persistent data across restarts | Kept |
| Corrupt `script.vnb` / `data.pak` (30 cases in the suite, 240 one-off) | No crash; clean error or normal run |
| Largest scene prefetch (Arcance) | 348 KB, about 0.2 s at a Memory Stick's 1.5-2 MB/s. This is an estimate, not a measurement |
| PSP-build sources (22 files) with clang for MIPS32 against `refs/pspsdk` headers, `-Wall -Wextra` | Clean. This found and fixed one bug: an `asm` statement used inside an expression in the audio ring |
| Visual spot checks (PNG shots) | Correct: menus, text tags, NVL, centered and rotated sprites, side images, keyboard, history, save screen, slide, push, pixellate |

**Rules followed:** no audio was played and no window was shown, because headless runs use dummy drivers or no platform at all. Game data stayed in `%TEMP%`.

**Side effects:**

- The SDL smoke run creates an empty `%APPDATA%\anyport\vnpsp` folder (SDL's pref path).
- One test run once failed with "no trace file", and I could not reproduce it in three full reruns; the likely cause is the antivirus scanning the freshly built exe. The harness now reports the exit code and stderr if it happens again.

## Decisions and deviations

- **Music decoder.** Music uses minimp3 on both PC and PSP instead of `sceMp3`, so the decoder the tests verify is the one the PSP runs. Its CPU cost at 333 MHz is unmeasured. If it is too high, a `sceMp3` source can implement the same interface.
- **PC rendering.** The PC renders in software, and GL only displays the result. This gives deterministic hashes and needs no GPU in tests.
- **Save location.** Saves go to `ms0:/PSP/SAVEDATA/<EBOOT folder name>/` as plain files. There is no `PARAM.SFO`, so the XMB save manager does not list them.
- **Not supported yet:**
  - Movie cutscenes are skipped with a log line; no target uses them.
  - `window` and `nvl` transitions switch at once.
  - The keyboard is ASCII-only.
  - `upper`, `lower`, `title` and `capitalize` change ASCII letters only.
- **Timed pauses.** They are interactions but not rollback checkpoints, as in Ren'Py.

## Not verified

- Everything specific to the PSP:
  - the GE renderer and its VRAM pool, transition targets, and CLUT uploads;
  - the draw-buffer parity assumption: frame buffers in AnySWF's `gu_setup` order;
  - DXT bilinear sampling at the bottom edge of a texture whose stored rows are fewer than its power-of-two height;
  - the audio thread, minimp3 speed, `ms0:` file I/O and its timing;
  - memory headroom on a PSP-3000.
- The release workflow, on GitHub: it needs a tag and a push.

## Resume from here

1. Start Docker Desktop after the reboot, then run `sh scripts/psp-build.sh`. Fix any psp-gcc or newlib differences; the clang check covered types and APIs only.
2. Put `script.vnb` and `data.pak` (from `rpy2psp compile` and `pack`) next to `EBOOT.PBP`. Test in PPSSPP: frames against PC `shot` PNGs, saves in `ms0:/PSP/SAVEDATA/<folder>/`, music loop, CPU headroom.
3. Then test on the PSP-3000 via psplink. When that passes, mark phase 04 completed.
4. Phase 05 (packaging) can start in parallel: `rpy2psp build <game>` producing the EBOOT folder, a `PARAM.SFO` title from `META`, and an icon.

Status: DONE_WITH_CONCERNS
Summary: The vnpsp engine is implemented, documented and committed locally (`56a84c6`, `08b432e`, `8be1ac3`). On PC, headless, all three target games play start to finish with traces identical to the reference interpreter, plus working saves, a 55-checkpoint rollback, CJK text and gapless music (ctest 4/4, 46 Python tests).
Concerns/Blockers: The PSP build was never compiled with psp-gcc or run, because the Docker daemon is not running; it only type-checks with clang against pspsdk headers. Phase 04 stays `in-progress` until PPSSPP and PSP-3000 validation. Music uses minimp3 rather than `sceMp3`, and its CPU cost on the PSP is unmeasured.
