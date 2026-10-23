# AnyPSP phase 05 (early): GE renderer with a Windows backend

Stopped early because the PC must restart. The Windows GPU backend works and is committed. GE accuracy work has started but is far from complete: on the GL renderer, 9 of the 28 pspautotests GE screenshot tests match PPSSPP's reference pictures exactly. Naruto UNH frames have not been tried yet.

## Decision: desktop OpenGL 3.3 core now, Vulkan later

The host already had a mature GLES 3 GE backend (`runtime/host/ge_gl.cpp`). It manages a surface per VRAM region, render-to-texture, stencil kept in alpha, format reinterpretation and internal scaling. Every GL call it makes also exists in desktop GL 3.3 core, so the port needed only a function loader and a shader version line. A Vulkan backend would have meant rewriting the whole surface manager, and this PC has no Vulkan SDK. Vulkan stays the target for Android and macOS (MoltenVK) and will use the same `GeRenderer` seam. The decision is also recorded in `phase-05-ge-vulkan-renderer.md`.

## Commits (in `repos/anypsp`, not pushed)

| Commit | What |
|---|---|
| `6964f07` feat: screenshot hook for the emulator device's devctl 0x20 | Adds `Kernel::set_screenshot_sink`. This was approved as a change to the other agent's `kernel.hpp` and `devices.cpp`. |
| `8cd3d5c` feat: desktop OpenGL 3.3 GE backend with an offscreen frame runner | Adds `runtime/gpu/` and the `anypsp-interp-gpu` runner, plus `-gpu` per-game runners. Adds coherent mode, `tests/ge-screenshots.py`, the GE tests in `tests/corpus-manifest.txt`, and an SDL3 entry in `THIRD_PARTY.md`. |
| `d4eb2ce` fix: GE culling, through-mode 8-bit positions and short display surfaces | Culling now applies in through mode and is skipped for clears. 8-bit positions read as 0 in through mode. A displayed framebuffer taller than its GPU surface is shown from VRAM. |

## What was built

- **`runtime/gpu/gl_api.*`.** Loads the GL 3.3 core functions at run time through `SDL_GL_GetProcAddress`, and redirects the `gl*` names that `ge_gl.cpp` uses. `ge_gl.hpp` picks this header when `ANYPSP_GL_DESKTOP` is set, and the GLES3 header otherwise (web). In desktop builds, `ge_gl.cpp` rewrites `#version 300 es` to `#version 330 core`.
- **`runtime/gpu/gl_host.*`.** Creates a GL context on a hidden SDL3 window that is never shown, and initialises no audio. It presents the display framebuffer into an offscreen FBO and reads it back.
- **`runtime/gpu/frame_output.*`.** Writes PNG files (`SDL_SavePNG`) and computes FNV-1a hashes of each frame's RGB.
- **`runtime/gpu/main_gpu.cpp`.** The runner. Options are `--renderer gl|soft`, `--scale n`, `--coherent 0|1`, `--frames-dir`, `--png-every`, `--hashes`, `--screenshot` (written at the devctl 0x20 request), `--dump`, and the same loader and IO options as `main_headless.cpp`. Its module bootstrap duplicates `main_headless.cpp`; the coordinator accepted that for now.
- **`runtime/gpu/gpu.cmake`.** Included at the end of the top-level `CMakeLists.txt`. It fetches SDL3 3.4.18, pinned by SHA-256 and linked statically, and defines `anypsp_gpu`, `anypsp-interp-gpu` and `anypsp-run-<name>-gpu`. `-DANYPSP_BUILD_GPU=OFF` skips all of it.
- **Seam additions in `ge_renderer.hpp`.** `list_started()` and `list_finished()`, both with default no-op bodies. `Ge::run_list` calls them.
- **Coherent mode in `GeGl`, on by default in the runner.** When a display list ends, GPU pixels are written back to VRAM. Before the next list, and before presenting, any surface whose VRAM the CPU changed is reloaded. Tests and some games need this because they read or write framebuffers with the CPU.

## Verification

All results come from a build in `out/ge-msvc` on an AMD RX 6600 XT (GL 3.3 core). No window appeared and no audio played.

**`python tests/ge-screenshots.py --runner out/ge-msvc/Release/anypsp-interp-gpu.exe`**

| Renderer | Exact matches (MSE 0) |
|---|---|
| GL | 9/28 |
| Software, before the culling fix | 1/28 |

Exact matches on GL:

- `commands/basic`, `commands/cull`, `commands/material`
- `primitives/rectangles`, `triangles`, `trianglefan`, `trianglestrip`
- `vertices/colors`
- `texmtx/uvs`

Near misses (MSE under 15):

- `triangle`
- `invalidprim`, `points`, `lines`, `linestrip`
- `reflection`, `rendertarget`
- `vertices/morph`

Large failures:

- `bezier` and `spline` (curves are not implemented).
- `immediate` and `continue` (immediate-mode vertices and prim continuation are not implemented).
- The other `texmtx` tests (see "Resume from here").
- `vertices/texcoords` and `indices`.
- `complex`, which stops on an unimplemented HLE file call.

**Text output of all 113 `gpu/` tests.** Run with `tests/conformance.py --runner …gpu.exe gpu/`, 22 of 113 passed. That run was taken before the other agent added `sceDmacMemcpy`. Most of those tests read VRAM through `sceDmacMemcpy` and print `[r]`/`[x]` scheduling markers, so their results depend on the HLE work.

**ctest.** Passed (3/3) after the screenshot hook, before the GPU commit. It was not rerun after the GPU commits.

## Not done

- Naruto UNH frames. They need the other agent's runner to get far enough first. Do not copy game data into the repo.
- Bezier and spline curves, lines (the GL path draws none), immediate-mode vertices, prim continuation (type 7), projective texture q, and `--hle-stubs` support in `main_gpu.cpp`.
- The software rasterizer path is behind the GL path on several tests. Games use GL; the software path serves as a reference only.
- The web/EGL build was not built after the `ge_gl.hpp` include switch. It should still compile, because without `ANYPSP_GL_DESKTOP` it uses the same GLES3 header as before.

## Resume from here

The working tree for my paths is clean; everything listed above is committed. Uncommitted changes in the repo belong to the other agent: `CMakeLists.txt` (multi-runner `ANYPSP_RUNNERS`), `tests/conformance.py` and `tests/translated-conformance.py`. Do not commit them.

1. **Build.**
   ```
   cmake -S . -B out/ge-msvc -G "Visual Studio 17 2022" -A x64
   cmake --build out/ge-msvc --config Release --target anypsp-interp-gpu
   ```
   If the run segfaults at once, the incremental build is stale: rebuild. That happened once while the other agent was editing headers.

2. **Measure.**
   ```
   python tests/fetch-corpus.py
   python tests/ge-screenshots.py --runner out/ge-msvc/Release/anypsp-interp-gpu.exe --out out/ge-shots --json out/ge-shots/gl.json
   ```
   Results: `out/ge-shots/<test>/actual-gl.png`. Test sources are not in the repo; fetch them from pspautotests at `713b8cc` (`tests/gpu/**.cpp`).

3. **Next fix: projective texture q (`texmtx/prims`, `normals`, `source`).** `decode_vertex` (map mode 1) divides by q per vertex. It must divide per pixel. Plan:
   - Add `float q{1.0f}` as the last field of `GlVertex`, `Ge::Vertex` and `Ge::ClipVertex`.
   - Interpolate q in the near-plane clip lerp, copy it in `to_screen`, and set `out.q = projected[2]` instead of dividing.
   - Add a vertex attribute (location 3) and divide `uv / q` in the fragment shader.
   - In the software rasterizer, interpolate q and divide.
   - Pre-divide q for sprites.

   The first attempt failed with "Permission denied" while writing `ge_renderer.hpp` (a transient lock) and was not applied.
4. **Then:**
   - Lines and points: the GL path ignores types 1 and 2. PPSSPP's `GPU/Software/TransformUnit.cpp` is the behaviour reference.
   - Prim continuation (type 7) and immediate vertices: `primitives/continue`, `immediate`.
   - Bezier and spline: adapt `GPU/Common/SplineCommon.cpp` with attribution in `THIRD_PARTY.md`.
5. **Mirror `--hle-stubs` into `main_gpu.cpp`** once the other agent commits `Kernel::set_hle_stubs` (currently uncommitted). With strict HLE, tests that call unimplemented functions stop.
6. **Check the per-game GPU runner.** `gpu.cmake` builds `anypsp-run-<name>-gpu` when the target `anypsp_generated_${ANYPSP_RUNNER_NAME}` exists. The other agent is adding `-DANYPSP_RUNNERS="name=dir;…"`; when that lands, loop over it the same way.
7. **Naruto UNH.** Once the other agent's runner reaches gameplay, run it with frame PNGs and hashes, writing output only to the scratchpad:
   ```
   anypsp-run-<naruto>-gpu <BOOT.BIN> --disc <extracted ISO dir> --frames 600 --frames-dir <scratch>/frames --png-every 30 --hashes <scratch>/h.txt
   ```
   The local inputs are the extracted ELF at `C:/Users/nguye/AppData/Local/Temp/claude/D--Projects-personal/6abeed62-62d9-4274-ac7a-e6a4cccd14e1/scratchpad/psp-games/g6/BOOT.BIN` and the ISO in `D:/Games/roms/psp`. Never copy them, or anything generated from them, into the repo.

Status: DONE_WITH_CONCERNS
Summary: The GE now renders on Windows through desktop OpenGL 3.3 core on a hidden SDL3 window. The runner writes PNG frames, per-frame hashes and test screenshots, and 9 of the 28 pspautotests GE screenshot tests match PPSSPP exactly. The work stopped early for a PC restart, so the GE accuracy work (curves, lines, projective q, prim continuation) and the Naruto UNH frames remain.
Concerns/Blockers: ctest was not rerun after the GPU commits. Many GE text tests depend on the other agent's HLE work (`sceDmacMemcpy`, strict stubs). `main_gpu.cpp` duplicates the `main_headless.cpp` bootstrap and lacks `--hle-stubs`.
