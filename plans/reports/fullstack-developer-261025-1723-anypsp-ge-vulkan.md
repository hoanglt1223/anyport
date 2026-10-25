# AnyPSP: Vulkan GE backend and GE accuracy

Date: 2026-10-25. Branch `feat/ge-vulkan` in worktree `repos/anypsp-vulkan` (from main `b1c7af5`), 7 commits, not pushed. Built and tested on the Linux box (clang, Ninja, Mesa llvmpipe GL and lavapipe Vulkan 1.4).

## Outcome

- **Vulkan backend works headless** (`--renderer vulkan`, `--msaa 1|2|4|8`, `--vk-cache file|off`). It matches GL on all 28 GE screenshot tests (MSE 0 between the two) and gives identical text on all 113 GE conformance tests. The Khronos validation layer reports nothing on the suite, including synchronization validation on the render-target tests.
- **GE screenshot tests: 18/28 exact on both renderers** (was 13/28). GE text tests: 26/113 (was 23); the rest wait on HLE work (scheduling markers, `scePowerSetClockFrequency`, `sceGeListDeQueue`).
- **UNH 1, GL, refactor only:** frame hashes byte-identical to main over 9,000 frames (intro and title) and 12,000 frames (to a battle). The 28 test pictures were byte-identical too.
- **UNH 1, accuracy changes:** these change GL frames on purpose. Mean MSE against the old GL frames is 18.5 (max 24.6) over 120 sampled frames, visually the same. The difference is UNH 1's 16-bit 5551 framebuffers now keeping 5 bits per channel as on hardware (mean -3.5), plus the game's dither pattern.
- **UNH 1, Vulkan vs GL (same build), 12,000 frames:** mean MSE 0.28, max 3.5. 14 of 120 sampled frames are pixel-identical. The differences are pixels on filtered sprite edges. 23 pipelines were created; with a warm cache none are compiled.
- **Speed (shared, loaded box):** GL 757 s and Vulkan 808 s for 12,000 interpreter frames. The CPU interpreter dominates in both.
- **MSAA 4x on UNH 1:** clean under validation. MSE against 1x is 0 to 6 (antialiased edges).

## Design (decisions made)

- **The surface manager is split out of `GeGl`** into the API-independent `GeSurfaces` (`runtime/host/ge_surfaces.{hpp,cpp}`, now in `anypsp_host`). It covers VRAM surfaces, coherence, stencil-in-alpha, reinterpretation and transfers. It drives a small `GeGpu` device interface (`ge_gpu.hpp`): targets, copies, reads and writes, reinterpret, alpha and stencil passes, draws.
- **Two devices:** `GlGpu` (`ge_gl.cpp`) and `VkGpu` (`runtime/gpu/vulkan/vk_gpu.cpp`). `GeGl`'s public API is unchanged for the web host, GlHost and in-between rendering.
- **One shader source for both:** `runtime/host/shaders/*.inc` are GLSL wrapped in C++ raw strings. GL prepends a GLSL ES 3.00 / 3.30 prelude at run time. For Vulkan, `cmake/vk-shader-source.cmake` strips the wrapper and adds a 4.50 prelude, and `glslangValidator` compiles to SPIR-V at build time, embedded with `embed-file.cmake`. Parameters are 8 vec4s (128 bytes): GL uniforms, Vulkan push constants.
- **Vulkan device:**
  - Headless context (`VkContext::create_headless`, external contexts possible for the Android host) and RGBA8 + D24S8 targets.
  - Synchronous submits at readbacks and presents, layout tracking with barriers, a sub-allocating memory pool and a staging arena.
  - Pipelines keyed by fixed-function state with dynamic stencil and blend values; the pipeline cache is validated by header and saved atomically.
  - MSAA renders into multisampled images resolved each render pass; single-sampled writes are "unresolved" back before the next pass.
  - Presents into `output_image()` for hosts with a swapchain.
- **Vulkan is headless only for now:** windowed play, the menu and frame interpolation stay on GL.
- **Accuracy follows PPSSPP's software renderer, which records hardware probes** (attributed in `THIRD_PARTY.md`):
  - integer texture functions;
  - 1/16-texel nearest and 4-bit bilinear sampling (native-scale targets and all decoded textures);
  - masked alpha reference, fog per vertex from view depth, dither, and the immediate-mode fog and dither flags;
  - 16-bit framebuffer quantization;
  - position-less vertex culling and UV/normal carry between draws;
  - the integer lighting colour model with specular, spot and powered diffuse;
  - depth floored to the GE's 16 bits in the fragment shader.
- **Tried and reverted:**
  - Screen-linear (noperspective) colour and fog break UNH 1's large near-clipped geometry.
  - Flooring x/y to 1/16 pixel (the GE floors in float24) loses against the tests with our float32 transform, so rounding stays.

## Bugs found on the way

- **Block transfers right after drawing copied stale VRAM** (the batch was not flushed). Fixed in `GeSurfaces::before_transfer`, with a unit test.
- **The title buttons vanished on GL:** a GEQUAL draw at the same depth failed on GL's extra precision. Fixed by the 16-bit fragment depth.
- **`tests/ge-screenshots.py` ran `complex` without its `test.tga`.** Tests now run with their folder as `disc0:` (MSE 4659 to exact).

## Tests

- `ctest` (Linux, all targets): 8/8 pass, including the new `ge_screenshots_gl` and `ge_screenshots_vulkan` gates (the 18 exact tests). They skip without the corpus, and the Vulkan one without a Vulkan device.
- New unit tests: `tests/unit/ge_transform_tests.cpp` (skinning, morphing, attribute carry, per-vertex fog, position-less culling) and `ge_surfaces_tests.cpp` (16-bit packing on readback, only drawn pixels written, transfer after unflushed draws). `anypsp_hle_tests`: 36/36.
- Vertex morph is verified by the now-exact `vertices/morph`; skinning by a unit test (no pspautotests screenshot exists).

## Remaining (and why)

- **Ten tests not exact:**
  - `triangle`, `bezier`, `spline`: Gouraud planes and 1-off colours; exact matching needs per-triangle fixed-point planes.
  - `reflection`, `rendertarget`: the PSP's integer blend rounding, which fixed-function blending cannot do; edge pixels.
  - `texmtx/prims`: the GE's own split of projected sprites.
  - `negq`, `normals`: float24 reciprocal precision.
  - `immediate`: 0.0008, 1-off pixels.
- **A Vulkan window/swapchain, MoltenVK, Windows/MSVC build of the Vulkan backend:** not possible on this box. It needs the Vulkan SDK on Windows; CMake skips the backend cleanly without it.
- **Not checked:** the web/EGL build (no emscripten here; `ge_surfaces.cpp` was added to `runtime/CMakeLists.txt`); GLSL ES lacks nothing the shaders use.
- **Real PSP and 4x checks:** "commercial title at 4x" needs a display or real hardware comparison. Exact sampling is used at 1x and for decoded textures; upscaled render targets use GPU filtering.

## Files

- New: `runtime/host/{ge_gpu.hpp,ge_surfaces.hpp,ge_surfaces.cpp}`, `runtime/host/shaders/*.inc`, `runtime/gpu/vulkan/{vk_gpu.hpp,vk_gpu.cpp,vulkan.cmake}`, `cmake/vk-shader-source.cmake`, `tests/unit/ge_{transform,surfaces}_tests.cpp`.
- Changed: `runtime/host/{ge.cpp,ge.hpp,ge_gl.cpp,ge_gl.hpp,ge_renderer.hpp}`, `runtime/gpu/{main_gpu.cpp,gpu.cmake,gl_api.hpp}`, `tests/ge-screenshots.py`, `CMakeLists.txt`, `runtime/CMakeLists.txt`, `README.md`, `THIRD_PARTY.md`, `docs/user/desktop.md`.
- Workspace: `CLAUDE.md` AnyPSP lines (not committed) and the phase-05 progress section.

## Notes

- Commands: `python3 tests/ge-screenshots.py [--renderer vulkan] [--msaa n] [--against out/<earlier>]`. Use `ANYPSP_VK_VALIDATION=1` for the validation layer.
- Linux setup: `sudo apt install mesa-vulkan-drivers libvulkan-dev glslang-tools vulkan-validationlayers` (already installed on this box).
- The worktree has an untracked symlink `tests/corpus` pointing at the main checkout's corpus. Do not commit it.
- No processes are left running.
