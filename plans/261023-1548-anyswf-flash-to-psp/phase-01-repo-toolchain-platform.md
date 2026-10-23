---
phase: 1
title: "Repo, PSP toolchain, platform layer, test corpus"
status: in-progress
effort: 1-2w
dependsOn: []
---

# Phase 01: Repo, PSP toolchain, platform layer, test corpus

## Context

Greenfield repo `anyswf`. Two targets from day one: PSP (the product) and PC via SDL3 (fast debug loop and CI).

## Requirements

- Repo layout: `swf2c/` (Rust workspace), `runtime/` (C11), `platform/psp/`, `platform/sdl/`, `tests/`.
- PSP build through the pspdev toolchain in Docker (`pspdev/pspdev` image) so Windows builds work without a native toolchain.
- Platform interface: init, frame begin/end, vsync, input state (buttons, analog nub), audio stream callback, file read/write (Memory Stick paths on PSP, user data dir on PC), monotonic clock.
- PSP backend: GU init with 8888 framebuffer and stencil, `sceCtrl` sampling with analog, `sceAudio` channel, `sceIo` files, 333 MHz clock via `scePowerSetClockFrequency`.
- Test corpus: self-authored AS2 test SWFs built with MTASC plus SWF tools, and Ruffle's MIT/Apache-licensed AVM1 test SWFs with their expected outputs.

## Files (create)

- `anyswf/CMakeLists.txt`, `anyswf/cmake/psp.cmake`, `anyswf/docker/psp-build.Dockerfile`
- `anyswf/platform/platform.h`, `platform/psp/*.c`, `platform/sdl/*.c`
- `anyswf/swf2c/Cargo.toml` (workspace skeleton)
- `anyswf/tests/swf-src/*.as` (MTASC sources), `tests/build-corpus.sh`
- `.github/workflows/ci.yml` (PC build + tests, PSP build artifact)

## Steps

1. Create repo and both build targets with a "hello triangle" that draws a colored triangle and plays a tone.
2. Run it on PPSSPP and on the real PSP-3000 through psplink.
3. Add the corpus build script and CI.

## Validation

- Hello triangle runs at 60 fps on PPSSPP and on the PSP-3000.
- CI produces an `EBOOT.PBP` artifact.

## Risks

- PPSSPP is more forgiving than hardware (cache, alignment). Test on the PSP-3000 at the end of every phase.

## Rollback

Greenfield; delete the branch.
