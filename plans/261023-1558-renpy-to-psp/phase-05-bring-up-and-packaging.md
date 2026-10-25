---
phase: 5
title: "Bring-up and packaging"
status: in-progress
effort: 1-2w
dependsOn: [4]
---

# Phase 05: Bring-up and packaging

## Context

Prove the converter on several games and make it usable by others.

## Requirements

- All three target games playable start to finish on the PSP-3000.
- `rpy2psp build` single command on Windows (Python packaged with its dependencies).
- Compat list in the shared format; user guide and the list of supported Ren'Py features.

## Files (create)

- `compat/*.toml`, `docs/user/USAGE.md`, `docs/user/SUPPORTED-FEATURES.md`, `.github/workflows/release.yml`

## Steps

1. Bring up the three targets and fix gaps.
2. Package and document.

## Validation

- Plan acceptance criteria in `plan.md` all met.

## Rollback

Docs and packaging only.

## Results (2026-10-25, Linux box)

- [x] `rpy2psp build <game> -o <dir>`: compile + pack + `EBOOT.PBP` from the engine's EBOOT with a PARAM.SFO title from `config.name` (UTF-8, Japanese works), ICON0 (144x80) from `config.window_icon` or `gui/window_icon.png` (`.ico` read), PIC1 (480x272) from `gui.main_menu_background`; `--title/--icon/--background/--engine` overrides. Engine found via `--engine`, `RPY2PSP_ENGINE`, `vnpsp/` next to the frozen exe, or `out/psp/vnpsp/`. Tests: `tests/test_build.py` (15).
- [x] Packaging: PyInstaller one-folder build verified on Linux (`build` of The Question from the frozen exe gives the same `data.pak` and engine as the source run). Fixed a missing `archspec` data file in frozen builds (`--collect-all archspec`).
- [x] `.github/workflows/release.yml`: `psp` job first; Windows and new Linux (ubuntu-22.04, tar.gz) jobs bundle the engine EBOOT as `vnpsp/EBOOT.PBP` and smoke-test `rpy2psp build`; publish attaches all three. New `ci.yml`: Linux build + ctest + unittest, and the PSP build. Not run on GitHub yet (needs a push and a tag).
- [x] `compat/*.toml` + `compat/schema.md` (shared format; stages defined for VNs) and `tests/test_compat.py`: The Question, Zero Echoes, Arcance at `playable` (PC full paths + PPSSPP), Ren'Py tutorial at `fails` (457 unsupported constructs, outside scope).
- [x] `docs/user/USAGE.md`, `docs/user/SUPPORTED-FEATURES.md`; README, `docs/dev/engine.md` (PPSSPP results, timing log, PPSSPP testing).
- [x] All three targets play start to finish in the PC engine on Linux (`tests/engine/test_target_games.py`, 7 tests), and their EBOOTs boot and play in PPSSPP (The Question through an ending).
- [ ] All three targets played start to finish on the PSP-3000 (plan acceptance): needs the hardware.
- [ ] Windows build of `rpy2psp build`: covered by the release workflow's Windows job, not run on this Linux box.

Verification: `python -m unittest discover -s tests -t .` 62 tests OK (target games present, ffmpeg installed); `ctest` 4/4 on Linux (Ninja, clang).
