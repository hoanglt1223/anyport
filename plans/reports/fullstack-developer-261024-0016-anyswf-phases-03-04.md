# AnySWF phases 04 and 03: implementation report (handover, cut short for a PC restart)

The phase 04 gate now passes: 164 of 199 selected Ruffle AVM1 tests (82.4%, gate 80%) and 5 of 5 self-authored tests. Phase 04 stays `in-progress` because the Ruffle tests are still read from `refs/` instead of being copied into the repo. Phase 03, `release.yml` and the PSP build were not started. The session was stopped early by the coordinator because the PC must restart.

## Done this session

Commit `f67e39e` in `repos/anyswf` (local only, not pushed): `fix(avm1): Flash case mapping, SWF4 NaN/Infinity globals, global o, trailing path colons`.

- `runtime/src/avm1/casemap.c` (new) holds Flash Player's UCS-2 upper and lower case tables, generated from Ruffle `wstr/src/tables.rs`, with `swf_char_lower`/`swf_char_upper` declared in `vm_internal.h`. Identifier folding (`value.c`), `String.toLowerCase`/`toUpperCase` and case-insensitive `Array.sort` use it. This fixed `string_methods`.
- `clip_child_by_name` (`clip.c`) decodes the UTF-8 instance names and compares them with that folding. This fixed `swf6_case_insensitive`.
- `NaN` and `Infinity` globals are undefined in SWF 4 movies (Ruffle `get_nan`), and the global `o` is `null`. This fixed `equals_swf4`, `lessthan_swf4` and `o`.
- `resolve_target_path` (`scope.c`) treats a path that is empty after trimming `:` as an empty name that resolves to nothing, as Ruffle does. This fixed `path_string`.
- `THIRD_PARTY.md` credits the case tables.
- Plan files: `plan.md` frontmatter is `in-progress`, and the phase table now matches the phase files (01 in-progress, 02 completed, 03 pending, 04 in-progress).

Verified: the full AVM1 run exited 0 (`out/avm1r.log`), `ctest` passed 2 of 2, and `cargo test --release` passed. Render tests were not rerun because only AVM1 runtime files changed.

Nothing is uncommitted in `repos/anyswf`. The plan file edits are outside the repo, which is not a git repository. No processes are left running; idle MSBuild worker nodes were stopped.

## Resume from here

1. **Finish phase 04.**
   - Copy the selected Ruffle tests into the repo at `tests/ruffle-avm1/<name>/{test.swf,output.txt,test.toml}`. Take the list from the `PASS`/`FAIL ruffle_<name>` lines of `out/avm1r.log`, where `<name>` is the directory under `refs/ruffle/tests/tests/swfs/avm1`.
   - Add a licence notice, reusing the text of `tests/ruffle/README.md` and LICENSE.md. Extend `.gitignore` (it allows `tests/ruffle/**/*.swf`) to `tests/ruffle-avm1`.
   - Point the runner's documented default and CI at `tests/ruffle-avm1`. CI is in `.github/workflows/`; check that it calls `run-avm1-tests.py`.
   - Then set `status: completed` in `phase-04-avm1-aot-compiler.md` and in the plan table.
   - Optional: raise the pass rate further. The remaining failures, with first-diff hints, are in `out/avm1r.log`:
     - `funky_function_calls`, `set_target_2_swf5` and `removed_base_clip_tell_target` involve `instanceN` naming by creation counter and `setTarget`.
     - The recursion limits (`infinite_recursion_*`, `virtual_property_recursion_*`, `watch*`) need Ruffle's 256-deep limit and `Error::PropertyRecursionLimit`.
     - The ordering tests are `looping_child_*` and `goto_frame*` (`runtime/src/display/timeline.c`).
     - `call` needs `call()` implemented.
     - `object_resolve` needs `__resolve`.
     - `primitive_type_globals` needs `Number.toString(radix)` for fractions.
2. **Phase 03.** Do the following, then run the render tests at all phases and set phase 03 `completed` when they pass:
   - Make blend modes add, multiply and screen pass in `tests/render` (cases tagged `phase = 3` in `tests/render/cases.toml`; GL backend under `runtime/src/render/`).
   - Write `runtime/src/render/ge.c` implementing `render.h` with sceGu: the 16-bit vertex scale folded into the model matrix, stencil masks, and CLUT upload.
   - Remove the `if(NOT PSP)` guard in the top-level `CMakeLists.txt`.
   - Raise the CI render job from `max-phase 2` to all phases.
3. **Add `.github/workflows/release.yml`.** On tag `v*`, build swf2c and anyswf for Windows, Linux and macOS, build the PSP runtime with `scripts/psp-build.sh` in the `pspdev/pspdev` Docker image, and attach everything to a GitHub Release. Do not create tags. `repos/psp-companion/.github/workflows/release.yml` is a working pattern.
4. **Build the PSP target.** Docker Desktop is installed (`C:\Program Files\Docker\Docker\resources\bin\docker.exe`, not on the Git Bash PATH). Its daemon was not running and WSL had no distributions, so the PSP target has never been built. Starting Docker Desktop opens a window, so ask the user to start it. Then run `sh scripts/psp-build.sh`.
5. After each step, run all tests, update the phase status lines and the plan table cells, and make local conventional commits with no AI references. Do not push.

### Commands (Git Bash on Windows)

```
cd D:/Projects/personal/anyport/repos/anyswf
export PATH="$PATH:/c/Program Files/CMake/bin" CARGO_TARGET_DIR="$(pwd -W)/out/cargo"   # hook blocks paths named target/build
PY=/c/Users/nguye/AppData/Local/Programs/Python/Python313/python.exe                   # `python` on PATH is a Store stub
(cd swf2c && cargo build --release && cargo test && cargo clippy --all-targets -- -D warnings && cargo fmt --check)
cmake --build out/msvc --config Release && ctest --test-dir out/msvc -C Release
PYTHON=$PY bash tests/render/run.sh out/msvc/apps/player/Release/anyswf-player.exe 2
$PY tests/avm1/run-avm1-tests.py --swf2c out/cargo/release/swf2c.exe --out out/avm1r --corpus out/corpus \
  --ruffle ../../refs/ruffle/tests/tests/swfs/avm1 --generator "Visual Studio 17 2022" > out/avm1r.log 2>&1   # about 6 minutes
# Quick iteration on a few tests (about 6 s after the first build in out/avm1q):
$PY tests/avm1/run-avm1-tests.py --swf2c out/cargo/release/swf2c.exe --out out/avm1q \
  --ruffle ../../refs/ruffle/tests/tests/swfs/avm1 --generator "Visual Studio 17 2022" --only ruffle_<name> ...
```

### Gotchas

- Some C sources in the working tree have CRLF line endings, but `.gitattributes` normalises to LF. Python string replacement must normalise `\r\n` first, or use the Edit tool. Bash heredocs collapse `\\`.
- Diff test output with `diff --strip-trailing-cr`, because Ruffle's `output.txt` files are CRLF. A plain diff dumps the whole file.
- Builds leave idle `MSBuild.exe` nodes. Stop them (`taskkill //IM MSBuild.exe //F`) before ending a session.
- The Ruffle exporter used for render references must be rebuilt in a new session; see `tests/render/make-render-refs.py`.
- Ruffle AVM1 source for semantics: `refs/ruffle/core/src/avm1/` (`activation.rs` has paths and actions; `globals.rs` has globals).

Status: DONE_WITH_CONCERNS
Summary: The phase 04 gate now passes at 164 of 199 Ruffle AVM1 tests (82.4%) plus 5 of 5 self-authored tests, committed as f67e39e. The session was stopped for a PC restart before the tests were copied into the repo, so phase 04 stays in-progress, and phase 03, release.yml and the PSP build were not started.
Concerns/Blockers: Docker's daemon was not running, so the PSP target is still unbuilt. The Ruffle AVM1 tests are still read from refs/.
