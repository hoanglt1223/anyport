# AnySWF: phase 04 closed, phase 03 PC complete with the GE backend, release workflow, PSP build

## Outcome

- **Phase 04 is completed.** The 199 selected Ruffle AVM1 tests are copied unmodified from Ruffle commit 8b25621 into `repos/anyswf/tests/ruffle-avm1/`, with `LICENSE.md` and a README. `.gitignore` allows their SWFs, and THIRD_PARTY.md lists them. The runner now reads `tests/ruffle-avm1` by default. A new CI job, `avm1`, builds swf2c and the corpus, then runs the runner under xvfb.
  - A rerun from the copied tests gives 164/199 (82.4%) plus 5/5 self-authored, the same as before.
  - The phase file records that the PSP half of the "PC and PSP" check is deferred to phase 06's on-device runs.
- **Phase 03 is in-progress.**
  - On PC, all 26 render tests pass at every phase, including blend add, multiply and screen. A blended object is drawn into an offscreen FBO layer (premultiplied, with `glBlendFuncSeparate`) and composited onto the frame. The 4-deep layer stack falls back to per-shape blending if FBOs are missing. Blend modes other than normal, layer, multiply, screen and add now warn once and draw as normal.
  - CI runs the render tests at all phases.
  - `runtime/src/render/ge.c` implements `render.h`. It is unverified on PSP hardware and in PPSSPP.
  - The phase stays open only for the PSP-3000 frame-rate run that CLAUDE.md requires.
- **The PSP target builds.** `scripts/psp-build.sh` produces both `out/psp/apps/hello/EBOOT.PBP` and `out/psp/apps/player/EBOOT.PBP` with no warnings. I removed the `if(NOT PSP)` guard and fixed these PSP-only errors:
  - `memalign` needed `<malloc.h>`.
  - `uint32_t` is `long` on newlib, so the format strings now use `PRIu32`.
  - A sign-compare and a truncation warning in avm1.
  - A `/*` inside a comment.
- **Release workflow added.** On a `v*` tag, `.github/workflows/release.yml` builds and tests swf2c and anyswf-player on Windows, Linux and macOS, builds the PSP EBOOTs, zips each one and publishes a GitHub Release. Every action is pinned by SHA; I resolved the download-artifact v8.0.2 SHA with `gh api`. No tags were created.

Commits in `repos/anyswf`, all local and not pushed:

- aeb983e: Ruffle AVM1 tests and the CI job.
- ea34aa6: GL blend layers.
- 7983e7d: GE backend and PSP build.
- 521e980: release.yml.
- d8b91b8: docs.

Workspace docs updated: phase 03/04 status lines and the plan table, and the AnySWF commands in CLAUDE.md. I made no workspace commit.

## Resume from here

1. **Test on PSP hardware (closes phase 03).** The PSP player needs an assets.bin path on the device; check `apps/player/main.c` for how the PSP build locates it. Then run the render-test SWFs through psplink on the PSP-3000 and compare them by eye with `tests/render/ref/`.
   - Points in `ge.c` to verify:
     - The 32768 scale for 16-bit vertices.
     - Stencil INCR/DECR on the alpha byte with `sceGuPixelMask(0)` plus the FIX/FIX blend for mask writes.
     - The multiply factor `GU_SRC_COLOR`, which the GE reads as the destination colour when used as a source factor.
     - The `GU_TFX_BLEND` additive pass.
   - PPSSPP is a quicker first check if a headless build is available.
2. **Optionally raise the AVM1 pass rate.** The remaining failures are in `out/avm1v.log`; the categories are listed in the previous report (`fullstack-developer-261024-0016-anyswf-phases-03-04.md`).
3. **Watch the first CI run** of the new `avm1` job and of the all-phase render job on Linux with Mesa. The first push is the user's decision.
4. **Phase 05**, runtime built-ins, is next by dependency.

Commands are as in the previous report. The PSP build needs `export PATH="$PATH:/c/Program Files/Docker/Docker/resources/bin"` in Git Bash, and Docker Desktop must be running.

Status: DONE_WITH_CONCERNS
Summary: Phase 04 is closed with the Ruffle AVM1 tests in the repo and in CI. Phase 03 passes every PC render test, including blend modes, and has a GE backend. release.yml is added, and the PSP target now builds both EBOOTs cleanly.
Concerns/Blockers: `ge.c` has not run on hardware or in PPSSPP, so phase 03 stays in-progress. The new CI jobs and release.yml have not run on GitHub yet.
