# Engine runners on PSP: prior art and porting surface (phase 01, research part)

Date: 2026-10-23. Scope: Task A of `plans/261023-1558-psp-engine-runners/phase-01-prior-art-and-shared-layer.md`.
This report does not cover the `psp-platform` extraction, which waits for AnySWF phase 01.

## Decisions

| Rank | Runner | Prior art on PSP | Decision |
|---|---|---|---|
| 1 | TIC-80 | None. Not built for PSP upstream or on the libretro PSP buildbot. | **Go.** Fork, then send an upstream PR. |
| 2 | PICO-8 (fake-08) | Frog08 and FrogR8 (binary-only, unmaintained since 2025-10), plus the `retro8` core in RetroArch PSP nightlies | **Go.** We cannot contribute because neither Frog port publishes source. Use them as performance baselines. |
| 3 | LÖVE (LövePotion) | LovePSP (LÖVE 0.8, dead since 2014). The `lutro` RetroArch core covers only a subset of the LÖVE API. | **Go, as a long-lived fork.** Upstream is unlikely to accept a PSP backend. |
| 4 | GM8 (OpenGMK) | chovy-gm, which wraps YoYo's proprietary PSP runner | **Skip.** Record a documented no-go. OpenGMK cannot run on rust-psp without a rewrite. chovy-gm cannot be redistributed or forked as a runner. |

The plan's "Prior art" column needs correcting. PICO-8 has existing PSP builds, and GM8 has a proprietary route.

## Prior art found

**TIC-80**
- Search found no TIC-80 build for the PSP: GitHub (`tic-80 psp`, `tic80 psp`), web search, and the libretro PSP buildbot index (70 cores, no `tic80`).
- In nesbox/TIC-80 issue #613, users asked for a PSP build ("perfect (x2) resolution"). nesbox invited platform code under `src/system/`.
- Upstream has merged new platforms several times:
  - 3DS: #1122 in 2020, then #2864 in 2025.
  - Bare-metal Raspberry Pi: #918.
  - Switch: #2866 on 2025-11-19, 570 additions across 19 files.
  - Metal/macOS: #2973 in 2026.
- A Symbian port (#2769) was closed without merging.

**PICO-8**
- [tzubertowski/Frog08](https://github.com/tzubertowski/Frog08) puts the fake-08 libretro core in a small PSP frontend.
  - Releases: v0.1.0 (2025-10-04) and v0.1.1 (2025-10-17), 218 downloads.
  - The repo contains only a README. Issue #1 asks for the source.
  - The author's release note: "much better compatibility than retro8. Sadly performance is much worse… I recommend disabling audio for better performance."
- [tzubertowski/FrogR8](https://github.com/tzubertowski/FrogR8) wraps retro8 in the same way.
  - It is GPL-2.0-or-later, but only the binary is published (issue #2).
  - Its README says it is best for "older Pico-8 titles".
  - Issue #1 reports a black screen on a PSP-3004.
- `retro8_libretro_psp.PBP.zip` is built nightly on the [libretro buildbot](https://buildbot.libretro.com/nightly/playstation/psp/latest/). [libretro/retro8](https://github.com/libretro/retro8) is GPL-3.0, and PSP support was added in PR #8.
- fake-08 issue #236 (2024) asked for a PSP build. The maintainer replied: "It should be possible… I would expect performance problems on heavier games", and said he had never set up a PSP build environment.
- Conclusion: a fake-08 PSP build already exists and is slow. The value of our fork is a native, open-source build that is faster than Frog08. Frog08 gives us a measured baseline to beat.

**LÖVE**
- [slemonide/lovepsp](https://github.com/slemonide/lovepsp) targets LÖVE 0.8.0 and has 3 commits.
  - It is a bridge onto PGE (Phoenix Game Engine), and has been untouched since 2014.
  - Its README calls it "very instable".
- `lutro_libretro_psp` is built nightly. [libretro-lutro](https://github.com/libretro/libretro-lutro) (MIT) is "an experimental lua game framework… following the LÖVE API".
  - Lutro implements only "the strict minimum", so it is not LÖVE 11 compatible.
- Nothing newer turned up: GitHub `love2d psp` and `love psp lua`, web search, and love2d.org forum threads.

**GameMaker 8**
- [LiEnby/chovy-gm](https://github.com/LiEnby/chovy-gm) (LGPL-2.1, archived 2022-04-18) is a decompiled and patched GM asset compiler.
  - Input is GM 8.1 projects.
  - It packs them with the EBOOT from YoYo's 2011 PSP Mini *Karoshi*. The README says that runner "was NEVER released publicly as an GM export module".
  - It uses Sony's `at3tool` and `umdgenc`.
  - Several GM8.1 homebrew games on itch.io were built this way.
- chovy-gm is not usable as a base. The runner is proprietary and cannot be redistributed. It needs project source, not the compiled `.exe` games we target. The author also says they "can only fix compilation bugs, not runner bugs".
- In principle, OpenGMK's `gm8decompiler` turned into a `.gm81` and fed to chovy-gm could run some games. That is a user-side workaround and falls outside this repo's legal model.
- Not applicable here: Butterscotch and Cinnamon (3DS and Wii U) run GameMaker Studio bytecode, not GM8.

## Porting surface per upstream (from the clones in `refs/`)

| | TIC-80 | fake-08 | LövePotion | OpenGMK |
|---|---|---|---|---|
| License | MIT | MIT. Submodule z8lua (MIT) is fetched separately. | MIT | GPL-2.0 |
| Clone HEAD | 2026-10-22 | 2026-06-13 | 2026-04-26 (`main`). `3.1.0-development` is 106 commits ahead and active on 2026-10-20. | 2026-10-14 |
| Where backends live | `src/system/<platform>/` plus `cmake/<platform>.cmake` | `platform/<name>/source/*Host.cpp` plus `platform/<name>/Makefile` | `platform/{ctr,hac,cafe}/` holding `*_ext.cpp` specialisations, plus `Console::Platform` in `include/common/console.hpp` | `gm8emulator/src/render/opengl*`, `game/platform/windows.rs`, `game/external/*` |
| What a PSP backend implements | A player loop on the public API (`include/tic80.h`): `tic80_create`, `tic80_load`, `tic80_tick`, `tic80_sound`, and reading `tic->screen`. The best template is `src/system/sdl/player.c` (267 lines). For comparison, 3DS `main.c` is 645 lines and Switch is 68 lines over SDL2. | One `Host` class (`source/host.h`, about 40 methods): `drawFrame` (128x128 indexed framebuffer plus palette map), `scanInput`, audio buffer fill/play, `waitForTargetFps`, `listcarts`, and file/settings I/O. Vita is 335 lines, 3DS 774. | About 26 files per platform (5.4k to 7k lines): graphics renderer, framebuffer, texture, font rasteriser, DSP audio, HID, joystick, timer, system, window. Common code is about 51k lines and is templated on `Console::Which`. | `RendererTrait` (108 methods, GL 3.3 core plus GLSL), windowing via `ramen` (Win32/X11), audio via `udon` and `libsoundio-sys`, plus imgui (TAS UI), clipboard, libffi externals |
| Scripting VM | Lua 5.3.6 (submodule pinned to `v5.3.6`). Uses `double` numbers and 64-bit integers. Other languages are off unless `BUILD_WITH_ALL`. | z8lua with `LUA_NUMBER = z8::fix32` (16.16 fixed point) | PUC Lua 5.1 (devkitPro portlib) plus lua53 compat. Uses `double`. | GML interpreter. `Real` wraps `f64` to match Delphi Double. |
| Memory need (estimate from code) | Small. RAM 96 KB (`TIC_RAM_SIZE`). Cart up to 8 x 64 KB code banks plus assets. Lua heap per cart. A few MB in total. | Small. `PicoRam` (64 KB address space) plus the Lua heap (PICO-8 caps Lua RAM at 2 MB) plus cart. | Per game. Images are decoded to RGBA, plus Lua heap, fonts and audio. The 3DS (64 MB on old 3DS) is the nearest analogue. | Large and unbounded. Every sprite and background is decoded and atlas-packed at load. GM8 executables are often tens of MB. |
| Upstream accepts new platforms | **Yes.** It has invited ports (#613) and merged Switch in 2025-11. | **Yes.** 13 platform folders, many contributed. The maintainer is positive about PSP (#236). | **Unlikely.** The README says "LÖVE for Nintendo Homebrew". The build is coupled to devkitPro (`pkg_check_modules` portlibs). There is one maintainer, who declined DSi for lacking an FPU (#255) and left Wii open "for lack of time" (#222). | **No signal.** Port requests #131 (Android) and #134 (libretro/WASM) have no maintainer reply. |

### PSP-specific findings that change effort

1. **The Allegrex FPU is single-precision only**, so `double` arithmetic is done in software. Sources: the [PPSSPP Allegrex overview](https://www.ppsspp.org/docs/psp-hardware/cpu/allegrex-overview), and a 2014 [lua-l post](https://lua-users.org/lists/lua-l/2014-10/msg00339.html) from a PSP developer who builds Lua with `float` for that reason.
   - fake-08 avoids this completely because z8lua uses fixed point. This is the best fit of the four.
   - TIC-80 (Lua 5.3) and LövePotion (Lua 5.1) should be built with float numbers. For TIC-80 that means `LUA_32BITS` (int32 plus float). For Lua 5.1 it means `LUA_NUMBER float`.
   - The cost is precision. Integers above 2^24 lose exactness, and `time()` in milliseconds becomes inexact after about 4.6 hours. Count any cart or game that breaks as a compatibility finding.
   - OpenGMK cannot take this route, because GM8 behaviour depends on f64.
2. **pspdev ships SDL2.** fake-08's `SDL2Common` host and TIC-80's SDL player would compile almost unchanged.
   - Use that only as a day-one baseline. The workspace decision is the shared `psp-platform` layer.
   - Final backends should be thin hosts over `psp-platform`. Upload the indexed framebuffer as a CLUT8 texture so the GE does the palette lookup and the 2x scale.
3. **Screen fit.** TIC-80's 240x136 scales 2x to exactly 480x272. fake-08 128x128 at 2x is 256x256, which fits the 272-pixel height.

### OpenGMK on `mipsel-sony-psp` (assessment only, nothing built)

- **The rust-psp target is `no_std` plus `alloc`.**
  - [rust-psp](https://github.com/overdrivenpotato/rust-psp) lists "Add `std` support" as a roadmap item. The latest commit was 2026-09-27, and it requires nightly 2026-08-26 or later.
  - The `RUST_PSP_BUILD_STD` path is experimental. A maintainer said in issue #168 (2024) that it "probably fell apart with upstream updates".
- **OpenGMK needs `std` throughout.**
  - Its source uses `std::fs` (21 places), `std::env` (9), `std::time` (7), `std::thread` (3), `std::sync` and `std::net`.
  - `gm8exe` uses `rayon` for parallel asset decoding.
- **Dependencies that block the build:**
  - `ramen`: a git crate for Win32/X11 windowing.
  - `imgui`/`imgui-sys`: C++ built through `cc`.
  - `udon`, which pulls in `libsoundio-sys`, a C library over OS audio APIs.
  - `lzzzz`: LZ4 in C through `cc`.
  - `clipboard`.
  - `getrandom` 0.2: no PSP backend.
  - `time` with `local-offset` (libc).
  - `libffi` (Windows only).
  - These are 132 crates in `Cargo.lock`. Pure-Rust crates (`flate2` `rust_backend`, `image`, `serde`, `bincode`) would still need `std`.
- **Toolchain conflict.** OpenGMK pins Rust 1.77 to keep Windows 7 support. rust-psp needs a 2026 nightly.
- **Runtime cost.**
  - All GML numbers are f64, which is software float on Allegrex.
  - Every sprite is decoded and atlas-packed at load. GE textures are limited to 512x512, and VRAM is 2 MB.
  - The renderer is 108 trait methods built on GLSL 3.3.
- **Verdict.** A port would need (a) a working `std` for PSP or a `no_std` rewrite of the emulator core, (b) a new platform, audio and renderer layer, and (c) f64 performance that is probably unacceptable. That is much more than the plan's 2-6 weeks.
  - Record this as the documented no-go the plan allows.
  - Do not fork OpenGMK.

## Trade-off matrix (ranked)

| | TIC-80 | fake-08 | LövePotion | OpenGMK |
|---|---|---|---|---|
| Backend size | Low (about 300 to 600 lines) | Low (about 400 to 700 lines) | High (about 6k lines plus a GE 2D renderer) | Very high (Rust platform work) |
| CPU risk | Medium (Lua plus soft-float unless switched to float) | Medium to high: Frog08 shows heavy carts are slow, even though the math is fixed-point | High (Lua 5.1, many draw calls) | Very high (f64 GML) |
| Memory risk | Low | Low | Medium (assets per game) | High |
| Upstream merge | Likely | Likely | Unlikely (ask first) | Unlikely |
| Prior art to reuse or measure against | None | Frog08 and FrogR8 binaries (baseline only) | lutro (API subset) | None open |

## Adoption risk

- TIC-80 is very active (commits up to 2026-10-22), has a responsive maintainer, and is MIT. Low risk.
- fake-08 is active (last merge 2026-06), MIT, and has one maintainer. Low risk.
- LövePotion has one maintainer and a large rewrite on `3.1.0-development`. CMake declares `LOVE_VERSION "12.0"`, so the fork should start from the dev branch or expect large rebases. Its API target is LÖVE 12, which is mostly compatible with 11.x games. The acceptance criterion "LÖVE 11 games run unmodified" still holds for most games.
- OpenGMK is active, but has given no signal on new platforms.

## Measurements to schedule (later phases)

- Run Frog08 v0.1.1 and FrogR8 on the PSP-3000 for each of the 20 target carts. Record fps with audio on and off. Our fake-08 port has to beat these numbers.
- For TIC-80, compare frame time with the standard double Lua build against `LUA_32BITS` on 5 carts, and list carts that break under float.
- For LövePotion, measure peak heap per game (`sceKernelTotalFreeMemSize` before and after load) on the 5 chosen LÖVE games.

## Limitations

- Searches did not cover Discord servers (PSP Homebrew Community), where unpublished work often lives.
- Frog08 performance is the author's claim and was not measured.
- The chovy-gm fork at git.silica.codes could not be read: the page returned unrelated text, apparently an anti-scraper page. Its current status is unverified.
- Which LövePotion dependencies exist in pspdev's psp-packages (physfs, box2d, freetype, tremor/vorbisidec, modplug, turbojpeg, curl, lz4, brotli) was not verified one by one.

## Unresolved questions

1. Should the user ask nesbox and jtothebell before forking? The plan already says to ask maintainers early.
2. For LövePotion, should the fork base be `main` (3.0.2 line) or `3.1.0-development`?
3. Is a float-only Lua (a semantic deviation) acceptable for TIC-80 and LÖVE compatibility claims?

## Sources

- [nesbox/TIC-80 issue #613](https://github.com/nesbox/TIC-80/issues/613), [PR #2866 (Switch)](https://github.com/nesbox/TIC-80/pull/2866)
- [jtothebell/fake-08 issue #236](https://github.com/jtothebell/fake-08/issues/236)
- [tzubertowski/Frog08](https://github.com/tzubertowski/Frog08), [tzubertowski/FrogR8](https://github.com/tzubertowski/FrogR8)
- [libretro PSP nightly cores](https://buildbot.libretro.com/nightly/playstation/psp/latest/), [libretro/retro8](https://github.com/libretro/retro8), [libretro-lutro](https://github.com/libretro/libretro-lutro), [Lutro docs](https://docs.libretro.com/library/lutro)
- [slemonide/lovepsp](https://github.com/slemonide/lovepsp), [lovebrew/lovepotion issues #222 and #255](https://github.com/lovebrew/lovepotion/issues/222)
- [LiEnby/chovy-gm](https://github.com/LiEnby/chovy-gm), [GVC2016 PSP (chovy-gm user)](https://nazdev32.itch.io/gvc2016-psp)
- [overdrivenpotato/rust-psp](https://github.com/overdrivenpotato/rust-psp) and issue #168
- [OpenGMK issue #134](https://github.com/OpenGMK/OpenGMK/issues/134)
- [PPSSPP Allegrex overview](https://www.ppsspp.org/docs/psp-hardware/cpu/allegrex-overview), [lua-l on PSP float](https://lua-users.org/lists/lua-l/2014-10/msg00339.html)
- Local clones: `refs/TIC-80`, `refs/fake-08`, `refs/lovepotion`, `refs/OpenGMK`
