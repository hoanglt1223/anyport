# AnySWF phase 01: implementation report

Status: DONE_WITH_CONCERNS. The PC (SDL3) target, the platform layer, the swf2c skeleton, and the test corpus build and pass on Windows. The PSP target is written but has not been compiled, because the Docker daemon is not running on this machine (WSL is not installed yet).

Phase file status set to `in-progress`, since the PSP build, PPSSPP run, and PSP-3000 run are still outstanding.

## Built

Everything below lives in `repos/anyswf/`. There are no commits.

- **Platform layer.** The API is in `platform/platform.h` (API v1). It has nothing Flash-specific, so it is ready to be extracted as `psp-platform`. It covers:
  - init and shutdown
  - frame begin/end with clear, plus vsync and 60 Hz pacing
  - input: 12 PSP buttons with pressed/released edges, and the analog nub with a radial dead zone
  - an audio stream callback (44.1 kHz stereo s16)
  - file I/O against a DATA or USER root, with relative-path validation, atomic `write_all`, `read_all`, mkdir and remove
  - a monotonic microsecond clock and logging
- **Shared code.** `platform/common/` holds the path and app-id validation, the dead zone, the input edges, and the whole-file helpers.
- **PSP backend** (`platform/psp/`):
  - GU with an 8888 framebuffer and stencil cleared every frame; depth test and depth writes are off
  - `sceCtrl` in analog mode
  - a `sceAudio` channel fed by a 1024-frame double-buffered thread
  - `sceIo` files, with the USER root at `ms0:/PSP/SAVEDATA/<APP_ID>/`
  - the exit callback, and 333 MHz via `scePowerSetClockFrequency`
- **SDL backend** (`platform/sdl/`):
  - SDL3 with an OpenGL 2.1 compatibility context and an 8-bit stencil
  - keyboard and gamepad input
  - an `SDL_AudioStream` callback
  - `SDL_IOStream` files, with the USER root at the SDL pref path (`anyport/<app_id>`)
  - `headless` config: hidden window plus the dummy audio driver
- **Hello app** (`apps/hello/`): draws an RGB triangle you can move with the D-pad or nub, plays a 440 Hz tone that Cross mutes, and keeps a `runs.txt` counter in the save dir. Flags are `--frames N`, `--headless`, and `--smoke` (headless and self-checking: pixel readback of the corner and centroid colours, audio frames produced, save round trip; exit code 1 on failure).
- **Build files:**
  - CMake: root `CMakeLists.txt`, `cmake/sdl3.cmake` (SDL3 3.4.18 pinned by URL and SHA-256), `cmake/psp.cmake` (wraps pspdev's toolchain file)
  - Docker: `docker/psp-build.Dockerfile` (`pspdev/pspdev:v20261001` pinned by digest)
  - `scripts/psp-build.sh`: runs Docker from the host, or CMake when already inside the container
- **swf2c:** a package that is also the workspace root. Edition 2024, toolchain pinned to 1.97.1 in `rust-toolchain.toml`, no dependencies yet. The CLI supports help and version, with unit tests.
- **Test corpus:** five self-authored AS2 tests with `.expected` trace output in `tests/swf-src/`. `tests/fetch-mtasc.sh` installs MTASC 1.14 with a pinned SHA-256: the Windows zip from the Internet Archive or the Ubuntu amd64 deb. `tests/build-corpus.sh` builds SWF 8 movies at 480x272 and 30 fps into `out/corpus`.
- **CI** (`.github/workflows/ci.yml`), with actions pinned by SHA:
  - swf2c: fmt, clippy, test
  - Linux PC: build, ctest, smoke under xvfb
  - Windows PC: build, ctest
  - PSP: build through the script, uploads `EBOOT.PBP` as an artifact
  - corpus: build, uploads the SWFs as an artifact
- **Repo files:** `LICENSE` (MIT, Henry Nguyen), `README.md`, `.gitignore` (ignores `out/`, `tools/`, `target/`, `*.swf`), `.gitattributes`.

## Verified (commands actually run on Windows 11)

- `cmake -S . -B out/msvc -G "Visual Studio 17 2022" -A x64` followed by `cmake --build out/msvc --config Release` from a clean reconfigure. Our code builds with no warnings at /W4.
- `ctest --test-dir out/msvc -C Release`: 1 of 1 passed. `test_platform` covers paths, app ids, dead zone, input edges, file round trip and overwrite, seek and size, mkdir, remove, root and path rejection, and the clock.
- `hello.exe --smoke` (headless, hidden window, dummy audio): `120 frames in 2.00 s (60.0 fps), 88064 audio frames`, `smoke: PASS`, exit code 0. The centroid readback matched about 85,85,85, so the hidden-window GL readback is real. A bad argument returns exit code 2.
- `cargo build`, `cargo test` (3 passed), `cargo fmt --check` and `cargo clippy --all-targets -D warnings` all pass in `swf2c/`.
- `tests/fetch-mtasc.sh` then `tests/build-corpus.sh`: built 5 SWFs (Windows MTASC 1.14).
- `bash -n` passes on all scripts, and git status confirms that build outputs and SWFs are ignored.

Audio and window note: two of the earlier smoke runs, before the coordinator's instruction, opened a visible window and played the tone through WASAPI for about 2 s. Since the instruction, every run was headless: a hidden window and the `dummy` audio driver, with no device output. I checked with `tasklist` and no hello or test process is left running.

## Unverified

- **PSP build.** `docker version` reports that the daemon is not running. I did not start Docker Desktop, because it opens a window. The PSP sources were checked by hand against the pspsdk headers in `refs/pspsdk`; they have not been compiled.
- **PPSSPP and PSP-3000 runs** (60 fps, tone, `ms0` save) need the EBOOT first.
- **CI workflow.** It has never run. Possible weak points:
  - the Linux SDL3 dependency list
  - whether the hidden-window GL readback works under xvfb with llvmpipe
  - whether the Ubuntu bionic MTASC binary runs on ubuntu-24.04
- **Corpus `.expected` files.** They were written from AVM1 semantics but not yet compared against Ruffle or a Flash player. Phase 04 should confirm them; `typeof null` == "null" and `0.1+0.2` printing as 0.3 are the cases most worth checking.

## Open issues

1. `sceIoRename` with a full destination path on real ms0 FAT is unconfirmed. The fallback removes the target first, so the `.tmp` copy survives a crash.
2. The phase requirement to import Ruffle's AVM1 test SWFs was not done, because the task said to use self-authored files only. It is deferred to phase 04, which already plans to run them.
3. The platform allocates a 4444 depth buffer (272 KB of VRAM) that it never uses but the GE needs to be valid. Phase 06 could reclaim it once it is proven safe on hardware.
4. Script exec bits: CI calls the scripts through `bash`. Set `git update-index --chmod=+x` on the `.sh` files at commit time if direct execution is wanted.
5. The workspace `CLAUDE.md` should get the build, test, and lint commands from the README. I did not edit it because it is outside my ownership.
