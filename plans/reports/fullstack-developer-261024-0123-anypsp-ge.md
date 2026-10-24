# AnyPSP phase 05: GE accuracy pass and first Naruto UNH frames

Exact GE screenshot matches went from 9 of 28 to 13 of 28. Naruto: Ultimate Ninja Heroes renders its title, loading screens and 3D fights through `anypsp-interp-gpu` on desktop GL. The frames are in the scratchpad only.

## Commits (in `repos/anypsp`, not pushed)

| Commit | What |
|---|---|
| `80ab2a4` feat: --hle-stubs, --input and NID names in the GPU runner | Brings `main_gpu.cpp` up to the `main_headless.cpp` options. |
| `7d2d440` feat: GE projective texture q per pixel, lines and 1/16-pixel vertex snapping | `q` added to `GlVertex`/`Vertex`/`ClipVertex`, GL attribute 3, `uv / q` in the fragment shader. Texgen source 2 normalizes. Lines and line strips are drawn as 1x1 sprites per pixel, covering the pixels whose centers lie in [start, end). Screen x/y snap to 1/16 pixel. |
| `1baf52e` feat: GE primitive continuation (prim type 7) | Carries the previous type, the leftover or connecting vertices and the strip parity. |
| `5aa663c` feat: GE immediate-mode vertices | Commands 0xF0-0xF9 follow PPSSPP `Execute_ImmVertexAlphaPrim`/`FlushImm`. Vertices are flushed when the primitive is complete, when another command arrives, or when the list ends. `draw_primitive` was split into `prepare_draw`, `decode_draw` and `emit_vertices`. |
| `a81efd9` feat: GE Bezier and spline patches; 32-bit vertex indices | Bezier and spline patches (commands 0x05/0x06, PPSSPP's GE-exact evaluation). `ClipVertex`/`Vertex` are now public in `ge.hpp`. Index type 3 reads 32-bit indices, masked to 16 bits. |
| `60f1dae` docs: record PPSSPP-derived GE curve and immediate-mode code | `THIRD_PARTY.md`. |
| `47f8442` fix: GE 8-bit texture coordinates in through mode scale by 1/128 | |
| `e2cd838` fix: GE sprites with projected texture coordinates interpolate q per pixel | Follows PPSSPP `AddTriangleRect`/`RotateUV`. |
| `57ab9e5` fix: GE projected q at or below zero samples the last texel | |

## Verification

Builds came from a detached worktree, `repos/anypsp/out/ge-wt` (now at `main` = `57ab9e5`, build dir `out/ge-wt/out/b`). The main tree does not compile at the moment because of the other agent's uncommitted `kernel.cpp` (`unimplemented_imports_` is undeclared).

- **`ctest`** (worktree, all targets): 4 of 4 ran and passed. `corpus_analysis` was skipped because the worktree has no corpus.
- **`tests/ge-screenshots.py`** (GL): 13 of 28 exact.
  - Newly exact: `primitives/lines`, `linestrip`, `continue`, `indices`.
  - Near misses: `texcoords` (MSE 1.4, PSP 4-bit bilinear weights), `negq` (picture exact, a few readback texels differ by 1), `normals` (0.0007), `source` (0.0001), `bezier`/`spline` (6.8, 24 pixels in the lines/points patches), `prims` (11.6), `triangle` (0.8).
  - `immediate` (MSE 53): the only wrong part is the fogged sprite. Immediate fog needs a per-vertex fog value, and the GL path computes fog from w.
  - `complex` stops at `sceIoRemove`, which needs HLE.
- **`tests/conformance.py gpu/`**: 23 of 113, the same with `anypsp-interp` and `anypsp-interp-gpu`.
  - Most failures print `[r]` where `[x]` is expected (thread scheduling markers) or the same values with a different scheduling marker.
  - Others are GE list, signal and stall semantics in `sceGe_user`.
  - 4 stop at `scePowerSetClockFrequency`, 3 at `sceGeListDeQueue`, 1 at `sceGeGetStack`.
  - All of these belong to the HLE owner.
- **Naruto UNH 1.** Command:
  `anypsp-interp-gpu.exe <g6>/BOOT.BIN --disc <psp-games>/unh1-disc --guest-path disc0:/PSP_GAME/SYSDIR/BOOT.BIN --frames 9000 --input "$(cat <psp-games>/unh1-run/input.txt)" --frames-dir <scratch>/naruto/frames2 --png-every 500 --hashes <scratch>/naruto/h2.txt`
  - Reached gameplay. Frames 6000 and 9000 show a full 3D fight (Naruto vs Hinata stage, HUD, characters, trees).
  - Runtime is about 1.5 min per 3000 frames, interpreter only.
  - Output stays in `C:/Users/nguye/AppData/Local/Temp/claude/D--Projects-personal-anyport/6abeed62-62d9-4274-ac7a-e6a4cccd14e1/scratchpad/naruto/`.
  - No window opened and no audio played.

## Resume from here

1. **Build.** Build from the worktree while the main tree does not compile:
   ```
   git -C out/ge-wt checkout -f --detach main
   cmake --build out/ge-wt/out/b --config Release --target anypsp-interp-gpu
   ```
   Once the other agent's `kernel.cpp` compiles, go back to `out/ge-msvc` and remove the worktree with `git worktree remove out/ge-wt`.
2. **Measure.**
   ```
   python tests/ge-screenshots.py --runner out/ge-wt/out/b/Release/anypsp-interp-gpu.exe --out out/ge-shots
   ```
   To find differing pixels, use the scratch helpers `pixdiff.py` and `bmp2png.py` in the scratchpad listed above (not in the repo).
3. **Next accuracy items, by expected payoff:**
   - **Immediate fog.** Add a per-vertex fog attribute, or encode immediate fog through w for immediate vertices.
   - **PSP bilinear.** Filter manually in the shader with 4-bit fractions (`texcoords`, `filtering/*`).
   - **Texel rounding.** Nearest-texel rounding in projective mode (`negq`, `normals`, `source`).
   - **Curve lines and points.** The patch line/point residue in `bezier`/`spline`.
   - **Lighting and texgen on patches.** Curves are evaluated after the vertex transform. That is exact in through mode, but in 3D, lighting and texgen are applied to the control points instead of the tessellated vertices. Move tessellation before the transform if a game shows lit patches wrong.
4. **Naruto.**
   - Compare a 3D frame against PPSSPP for wrong effects.
   - Run the per-game GPU runner once the other agent has a `-DANYPSP_RUNNERS` build for g6. `gpu.cmake` still loops over the single `ANYPSP_RUNNER_NAME` only.
5. **GE text tests.** These need HLE work from the other agent: `sceGe_user` list, signal and stall semantics, `[r]` scheduling, `scePowerSetClockFrequency`, `sceGeListDeQueue`, `sceGeGetStack`, `sceIoRemove`.

Status: DONE_WITH_CONCERNS
Summary: The GE now handles projective q, lines, prim continuation, immediate mode, Bezier/spline patches, 32-bit indices and several decode fixes, and 13 of 28 GE screenshots match PPSSPP exactly (up from 9). Naruto UNH renders through to 3D gameplay on the GL runner, with frames kept in the scratchpad.
Concerns/Blockers: The main tree does not build until the other agent's `kernel.cpp` is finished, so the builds came from the `out/ge-wt` worktree. The GE text tests are mostly limited by HLE scheduling and `sceGe` semantics outside my files. Curves are evaluated after the vertex transform, which is approximate for lit 3D patches.
