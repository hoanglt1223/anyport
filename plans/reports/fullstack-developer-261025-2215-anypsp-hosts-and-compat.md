# AnyPSP: hosts, `anypsp build`, Android, arm64, CI and compat

Date: 2026-10-25 (UTC). Repo `repos/anypsp`, branch `feat/hosts-and-compat` (worktree `repos/anypsp-hosts`),
rebased onto main `e54a646`. Not pushed. Scratch output: `/home/ubuntu/anyport/scratch-out/hosts/`.

## Outcome

- **`anypsp build <iso|disc|EBOOT|prx> -o DIR [--target linux|windows|macos|android]`** (tools/anypsp): runs
  anypsp-analyze, then psp_recomp, then a CMake build of the generated code against the AnyPSP sources, and
  packages the result as `<Name>/<Name>` with nids.toml, the licence, a README and the game files. Programs
  check the executable's SHA-256 before they start. Install layout (cmake/install.cmake): the tools, plus
  `share/anypsp/source` with SDL3 as a tarball, so games build offline. A relocated install built and ran a homebrew demo.
- **UNH 1 (ULUS-10299), Linux x64:** the whole build took 39 min. The packaged program, given the scripted
  7,400-vblank input (menus, battle, pause, Return to Mode Select, Game Over, save, mode select), draws every
  frame **identically to the interpreter**: 122-163 vblanks/s against 42-45. Re-checked after both rebases.
  This is the slow ctest `unh1_regression` (tests/unh1-regression.py). It skips without the disc, and its
  baseline is kept outside the repo.
- **Android** (platform/android and tools/anypsp/android.cpp): APKs are built without Gradle, as AnyGBA does.
  - The host uses the **Vulkan GE backend through its own swapchain** (vk_present.cpp) and falls back to GLES 3.
  - Touch overlay, gamepad and keyboard input.
  - SetupActivity copies the player's ISO or disc folder, picked through the storage access framework, or the
    embedded homebrew.
  - Emulator results (API 35 x86_64):
    - cubevfpu APK: Vulkan frame matches desktop Vulkan except one pixel; GLES frame within 8 levels of
      desktop. Seen on screen under the touch overlay.
    - **UNH 1 APK** (x86_64, 45 min build): ISO extracted in the app, hash checked, battle reached
      (GLES, 5,500 vblanks in 295 s).
  - The same host builds on Linux as `anypsp-game-gles` (Mesa: UNH 1 battle).
- **Linux arm64:** `cmake/toolchains/aarch64-linux-gnu.cmake` (clang plus the GNU sysroot). The tools, the
  runtime and anypsp-play build; unit tests pass under qemu-aarch64 (32/32, 42/42, 7/7);
  `anypsp-interp cpu_alu` matches its expected output under qemu.
- **CI (not run, YAML validated):**
  - `ci.yml`: Linux (Vulkan and lavapipe, so the Vulkan screenshot test runs) and Windows build, ctest
    `-LE slow`, compat site, `anypsp build` of cubevfpu.
  - arm64 cross build with qemu tests.
  - Android APK and emulator smoke.
  - `release.yml`: Linux and Windows packages on `v*` tags.
  - `pages.yml`: deploy gated on `PAGES_ENABLED`.
- **Compat:** `compat/*.toml` (UNH 1, pspautotests cpu 37/55, cubevfpu), `tools/compat-site/generate.py`,
  CONTRIBUTING.md (legal policy) and the bring-up discussion template. Badges: HLE 564/3953 (from
  `hle-coverage.json`), VFPU native 11/104 (`anypsp-coverage`), GE commands 181/233 (static scan).
- **Desktop OSK:** SDL text input goes to `dialog_type`; Backspace erases and Enter finishes. The pad's
  keyboard bindings are paused while typing.

Tests on the final branch: ctest `-LE slow` 8/8 (corpus_analysis passed earlier, after the first rebase:
843 s); `-L slow` unh1_regression passed; driver tests 7/7.

## Design calls

- Packages ship sources, not prebuilt libraries. Every game is one CMake build of the runtime with its code,
  for any target, using the user's own compiler.
- The packaged program is main_gpu.cpp built with `main=anypsp_runner_main` and `ANYPSP_PLAY`, plus a
  launcher object, so runtime/gpu is left untouched.
- On Android, discs are not embedded by default (`--embed-game` embeds them); homebrew always is. Debug-key
  APKs are debuggable.
- The UNH 1 regression stores no game-derived hashes in the repo. Instead it compares the interpreter with
  the translated program, and both with a local baseline.
- The compat stage `playable` means "start to finish", following the plan's criteria; AnyGBA uses
  "matches mGBA".

## Shared files touched (small)

These are other agents' files:

- `recomp/loader/nid_db.*`: finds nids.toml next to the program or through `ANYPSP_NID_DATABASE`.
- `runtime/gpu/disc.cpp`: Android's libc++ uses `__int128` for file times.
- `runtime/host/io.cpp`: Android's libc++ has no `clock_cast`.
- `runtime/gpu/{main_gpu.cpp,desktop.*}`: OSK input.
- Top-level `CMakeLists.txt`: +1 include line.

## Remaining (and why)

- Windows and macOS builds have not been run (no machines here). The code paths and docs exist.
- A real ARM handheld and an Android phone (the plan asks for full speed on a mid-range phone): needs devices.
- Five or more titles: only UNH 1 is available locally.
- Translated pspautotests demos are black until the import-stub fix of the code generator lands (`ffb6e1d`,
  feat/codegen-vfpu). I verified it locally, uncommitted; the cubevfpu compat entry depends on it.
- The Android app has no in-game menu, cheats, patches or dialog UI yet (dialogs are answered automatically).
- `/dev/kvm` was opened with chmod 666 for the emulator. The AVD lives in the session scratchpad.
