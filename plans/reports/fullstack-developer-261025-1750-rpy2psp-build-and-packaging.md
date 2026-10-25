# rpy2psp: Linux build, `rpy2psp build`, packaging, and PPSSPP checks

Date: 2026-10-25. Plan: `plans/261023-1558-renpy-to-psp` (phases 04 and 05). Repo: `repos/rpy2psp`, branch `feat/build-and-packaging` (12 commits, not pushed).

## Outcome

The Linux build and all tests pass. `rpy2psp build` now makes a folder that is ready to copy to the PSP. It contains `EBOOT.PBP`, with the title in PARAM.SFO plus ICON0 and PIC1 taken from the game's own images, alongside `script.vnb` and `data.pak`.

The PSP EBOOT was built with psp-gcc and runs in PPSSPPHeadless:

- **The Question:** title, dialogue, a menu choice, save, load, then that ending through to the title again. Its screenshots match the PC engine.
- **Japanese build, Zero Echoes, Arcance:** the openings render correctly, including CJK text.
- **Saves:** written under `ms0:/PSP/SAVEDATA/<folder>/`.
- **Music:** the loop is gapless and sample-identical to the PC mix.

The release workflow now has a Linux job, and both converter packages include the engine. A CI workflow is new. The compat records, the user guide and the supported-features page are written. Only the real PSP-3000 checks remain.

The target games were fetched legally: full checkouts at the census commits (MIT, CC-BY-4.0, Apache-2.0) into `/home/ubuntu/anyport-scratch/rpy2psp-games`. None of their data is in the repo.

## Evidence

| Check | Result |
|---|---|
| `ctest` (Linux, Ninja, clang) | 4/4 |
| `python -m unittest discover -s tests -t .` (target games present, ffmpeg installed) | 62 OK, 0 skipped |
| Target games on the PC engine (`tests/engine/test_target_games.py`) | 7/7: all paths or samples identical to refvm, saves, 55-step rollback, Japanese |
| PSP build (`sh scripts/psp-build.sh`) | Clean. Only minimp3's own `-Wstringop-overflow` warnings |
| PPSSPP, The Question (`tests/psp/the-question.timeline`) | 17 shots at 30.6-50.5 dB PSNR vs PC. The lowest two differ only in the save timestamp. The final shot equals the title screen (99 dB) |
| PPSSPP, openings (`first-lines.timeline`) | Japanese 39.9-52.1 dB, Zero Echoes 41.0-51.4, Arcance 35.9-50.5 |
| Saves | `PSP/SAVEDATA/TheQuestion/slot-01.sav` and `persistent.bin`; the load returns to the saved line |
| Music loop (`tests/psp/music_loop_check.py`) | PSP mix vs PC mix: at most 1 LSB difference over 5 loops |
| Timing (PPSSPP, emulated) | Start-up 54-70 ms. First scenes 155-348 KB in 16-36 ms. 59.9 fps at 0.2-0.5 ms CPU per frame. Mixer with minimp3: 4.4-5.3% of real time. A save or load stalls one frame for about 0.3 s |
| Frozen PyInstaller build (Linux) | Its `build` of The Question gives the same `data.pak` and the same engine as the source run |

## Changes (commits on `feat/build-and-packaging`)

| Commit | Change |
|---|---|
| `8a8a1b7` | `fix(vnpsp)`: the Linux build failed (C11 mode does not declare `strcasecmp`) |
| `6eadade` | `build(psp)`: `psp-build.sh` re-executes itself under bash when started by `sh` (dash), and runs as the calling user so `out/psp` is not owned by root |
| `47ae758` | `feat(vnpsp)`: logs start-up time, scene load times, and a perf line every 5 s (fps, frame CPU, the mixer's share of real time) through `plat_log`. Driver traces are unchanged |
| `1fc8cd6` | `feat(cli)`: `rpy2psp build`. `rpy2psp/eboot.py` holds the PBP and SFO reader/writer and the ICON0/PIC1 images; `rpy2psp/build.py` handles engine lookup and image choice. Tests: `tests/test_build.py` |
| `a2afce8`, `f417171` | `ci`: `release.yml` runs psp first, then Windows and Linux jobs that bundle the engine, then publish. New `ci.yml` (Linux tests, PSP build). `--collect-all archspec` fixes a crash in the frozen build |
| `99f26d2`, `8414f00`, `064e2d4` | `test(psp)`: `ppsspp_run.py` (a button timeline in PPSSPP and on the PC, PSNR, timing, saves), `music_loop_check.py`, and the timelines |
| `21f344e` | `compat/` records, `schema.md` and `tests/test_compat.py` |
| `df81ff7`, `159bcc4` | `docs/user/USAGE.md`, `SUPPORTED-FEATURES.md`, README, `docs/dev/engine.md`; `fetch_games.py --full` |

## Design calls

- **The output folder is the PSP game folder.** `-o <dir>`: its name becomes the save folder on the PSP. `manifest.json` is also written there, so `verify` can be run on the output.
- **The engine is wrapped, not rebuilt.** `build` keeps the engine EBOOT's DATA.PSP and all its SFO keys (MEMSIZE=2 included) and replaces only TITLE, ICON0 and PIC1. The keys are written sorted.
- **Fallback images.** ICON0 uses the window icon, fitted with transparent sides, or else the menu image cropped to fill. Games without either image (Arcance) get no ICON0 or PIC1.
- **Engine lookup order:** `--engine`, `$RPY2PSP_ENGINE`, `vnpsp/` next to the frozen exe, `out/psp/vnpsp/`. Release zips ship the engine in `vnpsp/`.
- **The Linux release job runs on ubuntu-22.04** so the package works on older glibc versions.
- **VN stages for compat.** `in-game` means the whole game matches refvm on the PC; `playable` adds PPSSPP shots that match; `perfect` means played on a PSP-3000.
- **Music check.** The MP3 seams deviate about 5.5% from a perfect period on both the PC and the PSP, so the period test only catches gaps. Sample equality with the PC mix is the real check.

## Remaining

- **Real PSP-3000 (ARK-4) via psplink:**
  - Memory Stick read times: PPSSPP emulates I/O timing.
  - minimp3's real cost at 333 MHz.
  - Memory headroom.
  - The XMB showing the title, ICON0 and PIC1.
  - All three targets played start to finish, including a save, which is a plan acceptance criterion.

  Phase 04 and phase 05 stay `in-progress` until then.
- **GitHub runs.** The release and CI workflows have not run on GitHub yet; that needs a push and a tag. The Windows job was not run on this box.
- **Opening-only PPSSPP runs.** Zero Echoes and Arcance were only run through their openings in PPSSPP. Their full paths are covered on the PC engine.

## Side effects

- `ffmpeg` was installed with apt so the movie test runs.
- Scratch output lives in `/home/ubuntu/anyport-scratch/` (games, built folders, PPSSPP runs, PyInstaller output).
- No processes are left running.
- The rpy2psp section of the workspace `CLAUDE.md` gained the commands for `build`, fetching the targets, the PPSSPP checks and the Linux setup.
