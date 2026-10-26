# Linux build box: full run across all plans (2026-10-25 17:20 to 2026-10-26 02:20 UTC)

Every plan was carried as far as this Linux box allows (no display, no PSP-3000, no Windows, no game files beyond Emerald and UNH 1). All work is merged to `main` and pushed in each repo; CI is green on the final commits listed below. What remains needs real hardware, the Windows PC, game files that are not here, a user key, or a public action.

## Repos (main, pushed)

| Repo | Head | CI | Delivered |
|---|---|---|---|
| anygba | 6c9f1e6 | green | Plan closed (14/14 phases). Linux ONNX Runtime download, Emerald 16:9 culling fix. Function overrides merged: `[[skip]]` hang and difftest exit codes fixed, agbcc switch resolution, `games = [...]` limit, FireRed symbols, Emerald text-printer regeneration specs. |
| anypsp | be7db9f | green | MSVC-only `cpu_difftest` failures fixed: MSVC quieted the constant VFPU NaN 0x7F800001 (NaN results are now decided in integer bits), and the reference `vsgn` read uninitialised stack through an S swizzle past the size. Vulkan GE backend (headless, MSAA, pipeline cache), GE exact 13 -> 18/28. HLE: kernel conformance 14 -> 134/186, sceMp3, OSK, msgpipe/TLS/VTimer, coverage counter. Codegen: 74/104 VFPU ops inline, import-stub bug (black demo frames) fixed, CPU conformance 37 -> 42/55. Hosts: `anypsp build` (UNH 1 frame-identical to the interpreter, ~3x faster), Android APK (Vulkan + GLES 3), Linux arm64, CI, release, compat page and badges. |
| anyswf | 1de6caa | green | Phase 05 built-ins (Key, Mouse, Sound, SharedObject, drawing API, Date, timers, TextField...), profiler overlay and VRAM texture cache; `anyswf build --target psp|linux|windows|macos|android`, Android APK, compat records and page, CI. AVM1: corpus 15/15, Ruffle 82.9%. |
| rpy2psp | 01ad577 | green | `rpy2psp build` (EBOOT folder with title, ICON0, PIC1), The Question played to its ending in PPSSPPHeadless matching the PC engine, saves, gapless loops, Linux package, CI, docs, compat. |
| psp-companion | 5ba1731 | green | Phase 05: power, START menu, XMB art, pairing key in SAVEDATA, settings page with pairing, Windows installer (Inno), Linux tarball + systemd unit, user guides, CI and release. whisper.cpp and Piper tests pass locally; Satellite API pinned at 1.15. |

Workspace: plans, reports and CLAUDE.md updated; `scripts/ppsspp-headless/` rebuilds the PPSSPPHeadless Docker images.

## Decisions taken

- Emerald text-printer overrides (rewrites of game code) are not in the public repo; they live in `~/anyport-out/overrides/pokemon-gen3-printer/` and are regenerated with `anygba decomp` from the user's ROM.
- The agbcc switch fix in the recompiler is accepted as a correctness fix despite the "no default output change" non-goal (compat green).
- AnyGBA: CPU pixel-art scalers stay (GPU final pass); APKs stay Gradle-free.
- AnyPSP: newer pspautotests `audio/mp3` tests not adopted (their sample file has no license).
- psp-companion Linux release has no tray (settings page instead).

## Remaining (cannot be done here)

- Real PSP-3000: every PSP phase's hardware run (AnySWF, rpy2psp, psp-companion networking/voice/battery, engine runners).
- Windows PC: AnyGBA host text layer + phase 05 integration (uncommitted Windows work), windowed/audio checks, installer run; engine runner repos exist only there and are unpushed (forking is public: user decision).
- Game files: AnySWF's three AS2 games, AnyPSP's four more titles, FireRed ROM, Paper Mario ROM for N64 phase 01 measurements.
- User key: live Claude API run for psp-companion.
- Public actions: GitHub Pages enablement (`PAGES_ENABLED`), release tags.
- AnyPSP: `dot_result` in `runtime/cpu/generated_ops.h` still turns a constant NaN into a float; it passes on MSVC today but could be quieted the same way if inlining changes. Upstream PPSSPP likely has the same uninitialised `t` in `Int_Vsgn`.
- Box changes made by agents: `ubuntu` added to the `kvm` group and `/dev/kvm` set to 0666 (emulator); Android SDKs under `~/Android/Sdk` and `~/android-sdk`; Ghidra 12.2 + JDK 25 under `~/tools`.

## Unresolved questions

- Tag new releases (anygba 0.4.0, anypsp first release, anyswf, rpy2psp, psp-companion 0.2.0) now, or after hardware checks?
- Revert `/dev/kvm` to 0660 (group access is enough now that `ubuntu` is in `kvm`)?
