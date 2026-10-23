# AnySWF phases 02, 04 and 03: implementation report (handover)

Phase 02 is complete. Phase 04 is in progress: 158 of 199 selected Ruffle tests pass, against a target of at least 80%. Phase 03 has not started as its own phase, although part of its PC-side work landed in phase 02. Nothing has been pushed, and nothing is uncommitted in `repos/anyswf`.

Commits in `repos/anyswf`, oldest first:

1. `90609ae`: the swf2c converter modules
2. `4015da9`: the assets.bin pipeline, the PC renderer, and the render tests
3. `f545a9d`: the AVM1 compiler and runtime (work in progress)

Docker was not available (`docker info` failed), so no PSP build was made. The PSP target is also guarded off in the top-level `CMakeLists.txt`: `runtime` and `apps/player` build only when `NOT PSP`, until `runtime/src/render/ge.c` exists.

## Phase 02: SWF parsing and assets (completed)

### Built

- **swf2c** (Rust, pinned dependencies; the `swf` crate is 0.3.0 with flate2 only, so ZWS is rejected with a clear message):
  - `inspect` and `assets` commands.
  - A lenient tag reader: a damaged tag is skipped with a warning, and a damaged sprite keeps the tags that can still be read.
  - Shape edge linking ported from Ruffle, with lyon tessellation. Tolerance and hairline width depend on each character's placement scale through nested sprites.
  - Baked gradients: a 1D ramp for linear, and a 2D texture sized to the gradient's screen diameter (32 to 256) for radial and focal.
  - Bitmaps (JPEG, JPEG with alpha, embedded PNG and GIF, lossless):
    - scaled by the stage scale
    - CLUT8 when it reaches 40 dB PSNR; otherwise 565, 5551 or 4444
    - power-of-two padding that repeats the edge pixels
    - a resampled power-of-two variant only when a fill actually wraps
    - 512 px tiles with clipping in UV space
    - GE swizzle
  - Morph frames for every ratio the timelines use.
  - Static text baked into meshes; embedded font glyph meshes; the device-font atlas from TIC-80 (MIT).
  - Sounds: event sounds become IMA ADPCM, and MP3 streams are kept as MP3.
  - Timeline command streams.
  - Format documentation: `docs/dev/assets-bin-format.md`.
- **Runtime** (C):
  - A validating loader (`runtime/src/assets.c`).
  - Display list and timeline with Flash-style backward gotos.
  - An OpenGL backend with colour transforms (a second pass for the additive term) and stencil masks.
  - Basic edit-text drawing.
  - `apps/player` (`anyswf-player`) with a headless PNG screenshot.
- **Tests:**
  - `tests/render`: 13 SWFs from `swf2c/examples/gen_test_swfs.rs` and 14 SWFs from Ruffle (copied to `tests/ruffle/` with LICENSE.md).
  - Reference PNGs in `tests/render/ref`, made by Ruffle's exporter (built from `refs/ruffle` at 8b25621 into a scratch target directory; see `tests/render/make-render-refs.py`).
  - `tests/runtime/test_runtime.c`, which covers loader corruption cases and the timeline.

### Verified

- `cargo test`: 38 tests pass; clippy reports nothing with `-D warnings`; fmt is clean.
- `ctest`: 2 of 2 pass.
- `hello --smoke` passes.
- `tests/render/run.sh <player> 2`: 20 of 20 pass, plus one known failure. `ruffle_gradient_radial_same_ratios` needs anti-aliasing, which is a plan non-goal.
- A mutated image fails the comparison metric.
- A 3.3 MB SWF produced a 5.3 MB assets.bin. This was measured with a scratch build, and the SWF was not committed.

### Unverified

- The PSP build, the GE renderer, and runs in PPSSPP or on hardware.
- The CI render job; it is set to `max-phase 2` and has never run.

## Phase 04: AVM1 ahead-of-time compiler (in-progress)

### Built

- **`swf2c compile game.swf -o dir`** writes `dir/game.c` and `dir/assets.bin`. The code is in `swf2c/src/avm1/{decode,stack_analysis,strings,emit_c}.rs`, and the script numbering is in `scripts.rs`.
  - Static stack depths become fixed array slots. Blocks with a dynamic stack (for-in loops, runtime counts) use `sp`.
  - With/Try/Catch/Finally bodies are inline regions. A jump that leaves a region exits that region, as in Ruffle.
  - Exceptions use setjmp. NaN and infinity are emitted through `swf_f64_bits`.
- **Runtime:**
  - The API for generated code is in `runtime/include/swfrt/{value.h,avm1.h}`.
  - The implementation is in `runtime/src/avm1/`: `value.c` (UTF-16 strings and a weak atom table), `object.c`, `coerce.c` (Flash number formatting and parsing ported from Ruffle), `call.c`, `scope.c`, `ops.c`, `clip.c`, `gc.c`, `builtins*.c` and `vm.c`.
  - The GC runs only between frames, so C locals need no rooting.
  - Frame scripts are queued and run after `swf_movie_advance`, through `swf_vm_run_queue`.
  - The execution list runs newest clip first.
  - Debug-player warnings are printed as trace lines ("Warning: ...").
  - `_global` is a bare object.
  - The global registers are cleared after each frame.
- **Build:** `cmake/anyswf-game.cmake` provides `anyswf_add_game(target game.c)`. The plain player links `swfrt_nocode`.
- **Runner:** `tests/avm1/run-avm1-tests.py` selects tests statically before running them. A test is excluded if it:
  - uses AVM2
  - is a known failure in Ruffle
  - has clip-event or button scripts
  - has text fields
  - calls getURL
  - names any built-in in `UNSUPPORTED`

### Verified

- Self-authored corpus (`out/corpus`, from `tests/build-corpus.sh`): 5 of 5 pass.
- Ruffle AVM1 tests: 204 selected, 523 excluded; 158 of 199 pass, or 79.4%. Five of the selected tests came from the self-authored corpus, which gives the 199.

### Known failing tests

- **Recursion and property limits:** `infinite_recursion_*`, `virtual_property_recursion_*`, `watch_recursion_*`, `watch_virtual_property_proto`, `watch`, `timeout`.
- **Ordering:** `looping_child_*` (order of the execution list after a loop), `goto_frame` and `goto_frame2` (scenes and the end of the timeline), `looping_real_1_declared_2`, `shared_stack` (the AVM1 stack is shared between action blocks), `placeobject_occupied_depth`.
- **Built-ins:**
  - `string_methods` (Unicode case mapping)
  - `primitive_type_globals` (`Number.toString(radix)` for fractions)
  - `as_set_prop_flags_version`, `assetnative*`, `delete2` (it expects a FP warning line)
  - `get_bytes_total` (per-clip byte sizes)
  - `stage_property_representation` (`_x` read back from a float matrix)
  - `waitforframe2`
- **Paths and targets:** `path_string`, `set_target_2_swf5`, `removed_base_clip_tell_target`, `swf6_case_insensitive`, `o`, `object_resolve`, `funky_function_calls` (instance naming should be `instanceN` in creation order), `button_v5`/`button_v6`, `call` (`call()` is not implemented), `issue_9885`.
- **SWF4:** `equals_swf4`, `lessthan_swf4`.

### Unverified

- The PSP build of the runtime.
- Trace output on PSP. The trace sink is stdout; there is no file or psplink sink yet.

## Phase 03: GE renderer and display list (not started as a phase)

Pulled forward into phase 02:

- display list and timeline
- the GL backend, colour transforms and stencil masks

Render cases tagged `phase = 3` in `tests/render/cases.toml` are not yet in the gate: masks and color_transform pass, and blend add, multiply and screen fail. Not done:

- `render/ge.c`
- blend-mode parity
- removing the PSP guard
- frame-rate checks on PSP

The release workflow (`.github/workflows/release.yml`) was not written.

## Resume from here

1. **Finish phase 04** (target: at least 80% of the selected Ruffle tests). The next fixes, in order of how many tests each should recover:
   - Execution order after a loop or goto: match Ruffle's `MovieClip::goto_frame` and the execution-list placement of re-created clips, using `looping_child_*` (in `runtime/src/display/timeline.c`, `goto_backward`).
   - Ruffle's property and function recursion limits (`Error::PropertyRecursionLimit`, 256-deep getter and setter handling in `object.c`).
   - `instanceN` naming by a creation counter (`clip.c` `path_rec`; this needs a field in `swf_dobj`).
   - SWF4 comparisons (`swf_op_equals` and `swf_op_less` in SWF4 return 1/0 numbers; check the Ruffle tests).
   - Then commit and set phase 04 to `completed`.
2. **Copy the selected Ruffle AVM1 tests into the repo.** Use `tests/ruffle-avm1/<name>/{test.swf,output.txt,test.toml}`, generating the list from the `PASS`/`FAIL` lines of `out/avm1r.log`. Add a LICENSE notice. The `.gitignore` already allows `tests/ruffle/**/*.swf`; extend it to `tests/ruffle-avm1`. Then point the runner and CI at that directory. At the moment the runner reads from `refs/ruffle`.
3. **Phase 03:**
   - `runtime/src/render/ge.c`, implementing the `render.h` API with sceGu, 16-bit vertex scale folded into the model matrix, stencil, and CLUT upload.
   - Blend modes.
   - Remove the `if(NOT PSP)` guard in the top-level `CMakeLists.txt`.
   - Raise the CI render job to all phases.
   - Add `.github/workflows/release.yml`: on tag `v*`, build swf2c for Windows, Linux and macOS, and build the PSP runtime with `scripts/psp-build.sh`. Do not create tags.

### Commands (Windows, Git Bash)

```
export CARGO_TARGET_DIR="$(pwd -W)/out/cargo"   # a hook blocks paths named target/build
(cd swf2c && cargo test && cargo clippy --all-targets -- -D warnings && cargo fmt --check)
cmake -S . -B out/msvc -G "Visual Studio 17 2022" -A x64 && cmake --build out/msvc --config Release && ctest --test-dir out/msvc -C Release
PYTHON=<python313> bash tests/render/run.sh out/msvc/apps/player/Release/anyswf-player.exe 2
sh tests/fetch-mtasc.sh && sh tests/build-corpus.sh
python tests/avm1/run-avm1-tests.py --swf2c out/cargo/release/swf2c.exe --out out/avm1r \
  --corpus out/corpus --ruffle ../../refs/ruffle/tests/tests/swfs/avm1 --generator "Visual Studio 17 2022" --list-selection
```

The CMake output directory for tests is `out/avm1r/cmake-out`.

### Gotchas

- Python is at `C:\Users\nguye\AppData\Local\Programs\Python\Python313\python.exe`; the `python` on PATH is a Store stub.
- Bash heredocs collapse `\\`, so write files that contain backslashes with the Write or Edit tools.
- The Ruffle exporter binary is in the session scratchpad and has to be rebuilt in a new session.

Status: DONE_WITH_CONCERNS
Summary: Phase 02 is completed and committed; it passes 20 of 20 render tests against Ruffle references plus 1 known failure. Phase 04 is committed but in progress: the self-authored corpus passes 5 of 5, and selected Ruffle AVM1 tests pass 158 of 199 (79.4%, target 80%). Phase 03 and the release workflow are not done.
Concerns/Blockers: The PSP build has never run because Docker was unavailable. The Ruffle AVM1 tests are still read from refs and are not yet copied into the repo.
