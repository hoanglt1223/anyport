# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this workspace is

`anyport` is a workspace (not a single repo) for native-port projects modelled on AnyPS5: real ports through relinking, static recompilation, or ahead-of-time compilation plus HLE of the target system's OS/APIs. No VMs, and no interpreter-first emulators (an interpreter is only a fallback for code the recompiler missed). `README.md` lists the projects, their suggested order, and links to each plan.

- `plans/<timestamp>-<slug>/`: the source of truth for scope. `plan.md` holds outcome, acceptance criteria, non-goals, and the phase table; `phase-NN-*.md` hold requirements, files, steps, and validation. Read the relevant plan before writing code. Validate after editing with `ak plan validate plans/<dir>`. `plans/journals/` is work history only.
- `repos/`: our own repos, each its own git repo (local only so far, no commits). Run git commands inside the specific repo, never at the workspace root.
- `refs/`: shallow clones of upstream projects (AnyPS5, PPSSPP, Ruffle, psprecomp, Moonlight-PSP, libnx, pspsdk, TIC-80, fake-08, LövePotion, OpenGMK, N64Recomp, companion-satellite, moonlight-common-c, gba-tests). Read-only reference: never edit or commit there, and check the upstream license before adapting any code.

Build, test, and lint commands are defined in each plan's phase 01; add them below as each repo gains them.

## Commands

**AnyGBA** (`repos/anygba`, CMake 3.28+, MSVC 14.44 on Windows):

```
pwsh tests/fetch-corpus.ps1   |   sh tests/fetch-corpus.sh   # test ROM corpus, hash-checked, git-ignored; fetch before configuring
cmake -S . -B <out> -G "Visual Studio 17 2022" -A x64 [-DANYGBA_WARNINGS_AS_ERRORS=ON]
cmake --build <out> --config Release
ctest --test-dir <out> -C Release [-LE slow]             # unit tests, recompiled jsmolka ROMs, smoke; `slow` = feedback-pass tests
<out>/bin/Release/anygba-tests.exe -tc="<test case name>"  # single doctest case
cmake --install <out> --config Release --prefix <prefix> # recompiler + runtime package (what release.yml ships)
anygba-recomp game.gba --output <dir> [--config game.toml] [--miss-log anygba-miss.log] [--list]
cmake --build <out> --config Release --target varooom-3d  # on-demand large generated program (also tonc-<demo>)
platform-smoke --headless --frames 60 --scale 2          # never run it windowed: no audio/windows on this PC
<game> <rom> --headless [--pace] [--frames N] [--exit-on-idle]   # generated games: always --headless on this PC
```

**AnySWF** (`repos/anyswf`; CMake + MSVC for the SDL/PC target, cargo for `swf2c`, Docker for PSP):

```
cmake -S . -B out/msvc -G "Visual Studio 17 2022" -A x64 && cmake --build out/msvc --config Release
ctest --test-dir out/msvc -C Release
out/msvc/.../hello.exe --smoke                         # headless; never run windowed on this PC
cd swf2c && cargo test && cargo clippy --all-targets -- -D warnings
swf2c inspect game.swf  |  swf2c assets game.swf -o assets.bin
anyswf-player assets.bin --screenshot f.png            # headless frame-1 render
tests/render/run.sh <anyswf-player> [max-phase]        # render tests vs Ruffle references (PYTHON=... on Windows)
swf2c compile game.swf -o <dir>                        # <dir>/game.c + assets.bin; build with cmake/anyswf-game.cmake
python tests/avm1/run-avm1-tests.py --swf2c <swf2c> --out out/avm1 --corpus out/corpus [--ruffle <ruffle avm1 dir>] --generator "Visual Studio 17 2022"
sh tests/fetch-mtasc.sh && sh tests/build-corpus.sh    # self-authored AS2 test SWFs
sh scripts/psp-build.sh                                # PSP EBOOT via pspdev Docker image (needs Docker running)
```

**PSP Companion** (`repos/psp-companion`; Rust host, C PSP client, spec in `protocol/PROTOCOL.md`):

```
cargo test --workspace                      # host unit + localhost e2e + C-vs-Rust crypto/protocol cross-checks
cargo test -p <crate> <test_name>           # single test
cargo run -p companion-host -- --headless --config <scratch config bound to 127.0.0.1>   # never launch the tray UI on this PC
cargo run -p pspc-fontgen                   # regenerate psp/font_vi.c after editing psp/assets/font-vi.hex
sh scripts/build-psp.sh                     # PSP EBOOT via pspdev Docker image (needs Docker running)
```

Host tests never inject input, touch the microphone, or play audio: desktop actions go through the `actions::Executor` trait (tests use a recording executor), the PC speaker uses `audio::capture::GeneratedSource`, and Claude, speech-to-text, text-to-speech and Bitfocus Companion are local test servers. Set `cfg.streamdeck.enabled = false` in e2e tests that do not need it (the default connects to 127.0.0.1:16622). whisper.cpp/Piper tests run only with `PSPC_WHISPER_BIN`+`PSPC_WHISPER_MODEL` / `PSPC_PIPER_BIN`+`PSPC_PIPER_VOICE`. Tagging `v*` triggers `.github/workflows/release.yml` (host exe + EBOOT to a GitHub Release).

**AnyPSP** (`repos/anypsp`; GPL-2.0-or-later; `recomp/` = PSPRecomp f6e7d41 + psp-web-recomp patches, `runtime/` = psp-web-recomp host, provenance in `THIRD_PARTY.md`):

```
cmake -S . -B out/msvc -G "Visual Studio 17 2022" -A x64 && cmake --build out/msvc --config Release
python tests/fetch-corpus.py                           # pspautotests binaries, commit + SHA-256 pinned, git-ignored
ctest --test-dir out/msvc -C Release                   # unit tests, framework test, corpus check (skips without corpus)
out/msvc/Release/anypsp_tests.exe "<name part>"        # single unit test case(s)
out/msvc/Release/anypsp-analyze.exe --out <dir> [--feedback f] EBOOT.BIN [MODULE.PRX...]
out/msvc/recomp/Release/psp_recomp.exe <ELF/PRX> --auto <gen dir> --seeds <dir>/0_<module>_seeds.csv
cmake -S . -B out/runners/<n> -DANYPSP_RUNNER_NAME=<n> -DANYPSP_RUNNER_GENERATED=<gen dir> [-DANYPSP_RUNNER_OPT=d]
python tests/feedback-pass.py <module> [--frames 300]  # analyze -> translate -> headless run -> feedback loop
```

Runners are headless (no window, no audio). Pipeline and file formats: `repos/anypsp/docs/dev/loader-and-analysis.md`. The web/EGL build in `runtime/CMakeLists.txt` is upstream's and untested here. Never import upstream `profiles/` or `pgd.cpp` (game output, KIRK keys). Write files from Python with `write_bytes`: `write_text` on Windows produces CRLF.

**rpy2psp** (`repos/rpy2psp`; Python converter + C11 engine `vnpsp/`, platform layer vendored from AnySWF in `third_party/psp-platform/`):

```
pip install -r requirements.txt && python -m unittest discover -s tests -t .     # converter + engine tests
python -m rpy2psp compile <game> -o <out> && python -m rpy2psp pack <game> -o <out> --font-dir <SDK fonts>
cmake -S . -B out/msvc -G "Visual Studio 17 2022" -A x64 -DPython3_EXECUTABLE=<python with requirements>
cmake --build out/msvc --config Release && ctest --test-dir out/msvc -C Release --output-on-failure
out/msvc/vnpsp/Release/vnpsp.exe <out> --play script.txt --trace t.txt [--fast] [--audio]   # headless scripted run
out/msvc/vnpsp/Release/vnpsp.exe <out> --headless --frames 240   # platform smoke: hidden window, dummy audio
sh scripts/psp-build.sh                                           # EBOOT via pspdev Docker image (needs Docker running)
```

Engine tests drive `vnpsp.exe` headless and compare each event with `tests/compiler/refvm.py`; never run `vnpsp.exe` without `--play` or `--headless` on this PC. Target-game tests need the games in `%TEMP%/rpy2psp-census/full` (or `RPY2PSP_TARGETS`) and cache converted data in `%TEMP%/vnpsp-targets`. Driver commands: top of `vnpsp/src/driver.c`; engine design: `docs/dev/engine.md`.

A local hook blocks paths named `build`, so put build output in a scratch folder rather than `repos/*/build`.

## Cross-project architecture decisions

- **AnySWF, Ren'Py → PSP, and the engine runners share one PSP platform layer** (GU init, input, audio, files, clock), built in AnySWF phase 01 with both a `psp/` and an `sdl/` backend. The runners phase extracts it as `psp-platform`. Reuse it; do not write a second one.
- **AnyGBA's toolchain is reused by AnySwitch**: CMake/CI skeleton, SDL3 platform layer, per-game TOML config, headless mode, and the compat tracker (`compat/*.toml` rendered to a static progress page). AnySWF, AnyPSP, and Ren'Py use the same compat format.
- **Phase 01 is a gate in several plans** (AnySwitch ABI spikes, AnyPSP evaluation of PSPRecomp, N64 decomp route spike, engine runner prior-art checks). Do not start later phases until the gate's exit criteria are recorded.
- **Forks are created only after their phase 01 decision** (N64 decomp game, TIC-80, fake-08, LövePotion, OpenGMK). Forking or pushing to GitHub is public, so ask first.
- **HLE strictness follows AnyPS5**: an unknown SVC, NID, SWI, service, or command throws with a clear name/ID message. It can only be stubbed explicitly through per-game config.

## Hard constraints

- **No game data anywhere**: no ROMs, ISOs, firmware, BIOS, keys, decrypted executables, extracted assets, or shared fonts in any repo, test fixture, or commit. Users supply their own dumps. Tests use open-source homebrew or self-authored files.
- **PSP-3000 Wi-Fi is 802.11b (~1-2 Mbps)**: no video over Wi-Fi (screen mirroring and game streaming were deliberately dropped), push-on-change only with no polling from the PSP, compress and cache, one audio stream at a time, under 300 kbps sustained total. Move work to the PC host and send small results.
- **Target hardware is the user's PSP-3000 running ARK-4 CFW.** PPSSPP is for fast iteration only; every PSP phase ends with a test on real hardware (psplink).
- PSP builds use the pspdev toolchain in the `pspdev/pspdev` Docker image, so they work from Windows.
