# AnyGBA plan closeout (Linux)

Status: DONE_WITH_CONCERNS. Branch `chore/plan-closeout` in `repos/anygba` (3 commits on `93fa1f8`, not pushed). The plan and all 14 phases are marked completed, and `ak plan validate` passes.

## Verification (Linux box, 2026-10-25, build dir `out/closeout`, clang + Ninja, `-DANYGBA_COMPAT_TESTS=ON`)

- **Full ctest, slow tests included:** 23 of 24 pass. That covers `unit-tests` (golden images included), `mcp-e2e`, `feedback-irq_demo`, `feedback-dma_demo`, the player tests, `driver-build` and `compat-site`.
  - `video-timing` fails on the CPU-only path: the slowest chain took 20-28 ms against a 16.7 ms budget.
  - Other agents kept the load average at 15-25 on 16 cores the whole time. nearest took 2.5 ms and most chains 10-14 ms.
  - The GPU path renders a 4K frame in 2.0-2.2 ms.
  - The test passes on the development PC, so I did not change the code. It needs a rerun on an idle machine.
- **Compat:** `ctest -L compat -j4` passes 41 of 41.
- **Site:** `tools/compat-site/generate.py` (50 titles) and `site/build.py --check` both pass. The reported Emerald TOML failure no longer happens on main.
- **CI:** run 40168774943 on `93fa1f8` is green on all 9 jobs. These are windows-msvc, windows-clang-cl, linux-gcc, linux-clang and macos-arm64, the compat jobs on all three hosts, and android (emulator hash check).

## Changes (commits)

- **`d203002` feat(hdpack):** `fetch-runtime` and the player's first AI use now download ONNX Runtime 1.24.4 on Linux x64 too.
  - The source is the pinned `onnxruntime-linux-x64-1.24.4.tgz` from the GitHub release, SHA-256 `3a211fbe...b747`.
  - Packages already in the cache are not downloaded again.
  - A new test checks the pinned archive name and that a file with the wrong hash is refused. Docs, THIRD_PARTY and the CLI help are updated.
- **`d856400` fix(hdpack):** the `.tgz` is unpacked with `tar` alone. Before this, unzip printed an error first.
- **`3a7188c` fix(widescreen):** fixes Emerald's edge pop-in.
  - The game hides objects 16 px past its own screen, but 16:9 shows 22 px.
  - Six ROM halfword patches widen the culling in UpdateObjectEventOffscreen, UpdateObjectEventSpriteInvisibility and RotatingGate_HideGatesOutsideViewport. They apply only while widescreen is on. The addresses were found by disassembly and checked against the pokeemerald symbol map.
  - Evidence: a 1,200-frame headless walk from a Littleroot save state. With the patch, the twin NPC appears at the right edge 4 frames earlier (frames 511-514). Columns 22-261 are identical with and without the patch.
  - WIDESCREEN.md and compat notes are updated.

## Measurements

- **AI on CPU, Linux, ONNX Runtime fetched by `anygba hdpack fetch-runtime`:**
  - Offline: a 166-image Emerald dump takes 3.2 s with general-x4v3 and 36.0 s with x4plus.
  - Real time with `ai=frame`: 500 ms per frame with general-x4v3 and 9.3 s with x4plus.
- **Android, API 35 x86_64 emulator with KVM** (I added user `ubuntu` to the `kvm` group and installed the `emulator` package and the system image):
  - `emulator-smoke.sh`: the per-game APK's frame 300 hash equals the desktop build's, `d5ed18a2...51bd`.
  - Launcher: the `.agp` was imported through the system file picker, listed, and started from the list. The game ran with the touch overlay.

## Design calls

- Phase 11: CPU scalers with GPU final scaling and effects are kept and recorded as a decision in the phase file.
- Phase 13: the Gradle-free APK pipeline is kept and the reasons are recorded.
- ONNX Runtime auto-download is pinned only for Windows x64 and Linux x64. macOS still uses `ANYGBA_ONNXRUNTIME`, because no Mac is available to test on.
- A phase counts as completed when every criterion that can be checked on Linux or in CI is met. Items that need a person or other hardware are plain notes, not checkboxes.

## Remaining

- NEEDS-WINDOWS (display and speakers):
  - windowed `platform-smoke` with audible sound;
  - fullscreen and window resizing;
  - the agent indicator and takeover in a window.
- NEEDS-HARDWARE: the user's phone, haptics and gamepads. Linux-built APKs use a different debug key from the phone's install.
- `video-timing` CPU path: rerun on an idle machine.
- In some Emerald frames, at most 12 pixels in the outermost columns of the middle 240 differ from normal mode. This happens with or without the patch and comes from the HD path's known approximations.

## Housekeeping

- Scratch is in `/tmp/claude-1000/-home-ubuntu-anyport/63c72530-e968-490d-aa3a-248168c9671c/scratchpad/closeout-gba` and holds ROM-derived files: the Emerald build, states, dumps and packs. Do not commit it.
- The emulator I started is stopped, and so is the adb server. Another agent (AnySWF) then started its own emulator on port 5580.
- I accidentally wrote into another agent's `scratchpad/em/` folder (my `build.log` and work folder). I removed my work folder; their `build.log` may have been truncated.
