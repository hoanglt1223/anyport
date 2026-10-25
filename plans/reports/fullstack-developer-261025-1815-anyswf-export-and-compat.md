# AnySWF: native export (phase 08) and compat tracking (phase 07)

Branch `feat/export-and-compat` in worktree `repos/anyswf-export` (10 commits, not pushed).

## Done, with evidence

- `anyswf build game.swf --target psp|linux|windows|macos|android -o DIR`: a second binary
  in the swf2c crate (`swf2c/src/anyswf/`), plus `swf2c assets|compile --target`.
  - Linux: `Scaled-Stage` from `g12_scaled_stage.swf` renders its native 550x400 stage
    headless; the PNG is byte-identical to anyswf-player's.
  - PSP: EBOOT built through the pspdev Docker image renders letterboxed under
    PPSSPPHeadless. The AS2 corpus passes 5/5 as EBOOTs (new `tests/psp/run-psp-corpus.py`).
  - Android: debug APK (arm64-v8a + x86_64, 5.7 MB). zipalign `-P 16` and apksigner
    v2/v3 pass. It runs on an API 35 x86_64 emulator on OpenGL ES 1.1 and shows the
    letterboxed stage with on-screen d-pad, Z and SPACE buttons. MSAA was not available
    there, and the fallback worked.
- Platform API v2 (SDL backend): logical screen size letterboxed in a resizable window,
  MSAA with a fallback, pointer (mouse or first free touch) in stage pixels, held keys as
  Flash key codes, touch buttons, and `plat_set_screen_size`. A headless window is
  recreated because the offscreen driver has a fixed-size surface. On PSP only
  480x272 is accepted.
- Header bytes 48-51 of assets.bin now hold the logical screen size (0 = 480x272, which
  stays compatible with older files). PSP builds refuse other sizes.
- Phase 07: `compat/*.toml` (20 records: 5 AS2 corpus, 13 render corpus, 2 Ruffle suites),
  `compat/schema.md`, `tools/compat-site/` (adapted from AnyGBA, with unittest),
  `.github/workflows/pages.yml` (deploys only when `vars.PAGES_ENABLED == 'true'`),
  `CONTRIBUTING.md`.
- CI: the existing pc-linux job now also exports and runs a Linux game. A new android job
  builds an APK. Releases ship `anyswf` plus the source tree in `share/anyswf/source`.
- Docs: `docs/user/EXPORT.md`, README, THIRD_PARTY (SDL, toml), and the workspace
  CLAUDE.md commands.
- Pre-existing fix: `posix_memalign` was undeclared under strict C11, which broke the
  Linux clang build.

Tests: ctest 2/2, hello smoke PASS, swf2c and anyswf cargo tests (36 + 14 + 4 + 2) with
fmt and clippy clean, render tests 26/26 (1 known failure), AVM1 at 5/5 self and
164/199 Ruffle (82.4%), compat unittest 3/3.

## Design calls

- `anyswf` is a second binary in the swf2c crate, so the compile pipeline is shared
  (`swf2c::pipeline`).
- Android follows AnyGBA's approach of SDK command-line tools without Gradle. The JDK
  `jar` tool adds the dex and stored libraries instead of a custom zip writer.
- The Android renderer uses OpenGL ES 1.1 (fixed function) through `platform/plat_gl.h`
  rather than a shader rewrite. This keeps `gl.c` nearly unchanged and the desktop output
  identical.
- Compat uses AnyGBA's stage names (the AnyGBA schema says AnySWF shares the format).
  The plan's "renders" maps to `boots`.
- Default work dir is `<out>.work`. Desktop targets build only on their own OS.

## Remaining (and why)

- Windows and macOS exports have not been run, because this box is Linux. The CI
  pc-windows job compiles the platform changes.
- Real Android phone and PSP-3000 hardware runs are not done (no devices here).
- The plan's three test games and the ten-game bring-up need game SWFs that are not
  on this box.
- Wiring the Key and Mouse built-ins to `plat_input.keys` and the pointer belongs to the
  parallel phase 05 work.

## Notes

- On the emulator, a "not responding / Wait" dialog showed once during the first launch
  with SwiftShader. No ANR line was logged and frames kept arriving.
- I added the `ubuntu` user to the `kvm` group to run the emulator. Another agent runs
  its own adb from `/home/ubuntu/android-sdk`, so I used `ANDROID_ADB_SERVER_PORT=5038`.
  An adb server I started earlier is still on 5037. The emulator is stopped.
