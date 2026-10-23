# AnyPSP: base import done, phase 02 started (paused)

The base is imported and builds on Windows. Phase 02 has started, but no phase-02 code is written yet: the user paused the project while I was still mapping the gaps. Phase 01 is `completed` and phase 02 is `in-progress`. All work is committed locally in `repos/anypsp`, nothing is uncommitted, and nothing was pushed.

## Built (commits on `main` in `repos/anypsp`)

| Commit | What |
|---|---|
| `c888677` chore: import PSPRecomp f6e7d41 | Merge of PSPRecomp history, filtered with git-filter-repo to `src include tools tests configs CMakeLists.txt LICENSE docs/ARCHITECTURE.md docs/SOURCE_PROVENANCE.md` and moved under `recomp/`. Each upstream commit has an `Upstream-Commit:` trailer. `profiles/` (per-game code and generated game output) is excluded from the whole history. |
| `9816ea8` feat: apply psp-web-recomp generic pipeline patches | The 10 patches from psp-web-recomp@37826ab, applied in order with `git apply --directory=recomp`, all clean. |
| `9a994d3` chore: import psp-web-recomp host runtime at 37826ab | Merge of filtered history: `profile/host`, `profile/third_party`, `profile/CMakeLists.txt` and `LICENSE`, moved under `runtime/`. |
| `5f892e5` fix: drop key-based PGD decryption | PGD files are now detected and rejected with a clear message. |
| `700624e` chore: license as GPL-2.0-or-later | Adds `LICENSE` (FSF GPL-2.0 text) and `THIRD_PARTY.md`, which records sources, commits, copyright holders, the LGPL at3 decoder and the PPSSPP policy. |
| `e65e081` build: top-level CMake | Root `CMakeLists.txt` with `enable_testing()` and `recomp/`, plus a `.gitignore` covering `out/` and `tests/corpus/`. |
| `284f6a7` test: pinned corpus | `tests/fetch-corpus.py` and `tests/corpus-manifest.txt`: 31 pspautotests binaries at commit `713b8ccc4f2830c54ce3c20bbafc085f3506e810`, each with a SHA-256. The 9 demo `.elf` files are the symbol-bearing ones (7 are unstripped). |
| `af55fbc` docs: README status | The README status section now matches reality, with build commands. |

### Deviation: the history import is filtered, not a plain merge

**A plain merge would have broken the "no game data / no keys" rule.**

- PSPRecomp's history contains `profiles/`, which holds generated game code.
- psp-web-recomp's `profile/host/pgd.cpp` embeds KIRK key-vault AES keys in every revision.

So both imports are filtered. `pgd.cpp` and `pgd.hpp` are removed from the whole imported history, and I checked that no imported revision contains "kirk". Provenance is kept through the trailers and `THIRD_PARTY.md`. The temporary remotes and import refs were deleted, so no profile objects stay referenced.

## Verified

| Command | Result |
|---|---|
| `cmake -S . -B out/msvc -G "Visual Studio 17 2022" -A x64 && cmake --build out/msvc --config Release` | 0 errors. There are warnings from upstream code (C4324, C4244, D9025). |
| `ctest --test-dir out/msvc -C Release` | 1/1 passed (`psprecomp_tests`, the upstream test plus the auto-pipeline tests). |
| `python tests/fetch-corpus.py` | 31/31 files verified. Re-running it is idempotent. |
| Baseline `psp_analyze` over the whole corpus | 30 of 31 files load. |

Two gaps showed up in the baseline:

- `tests/modules/cutrel/child_cut.prx` fails with "Truncated ELF structure". Its relocation sections lie past the end of the file, and the parser rejects that instead of tolerating it.
- `bss.prx`, `alarm.prx` and `threads.prx` each report 15 "unsupported" relocations. These are likely `R_MIPS_GPREL16` or `R_MIPS_NONE`, which PPSSPP ignores, and `R_MIPS_16`, which it handles.

I also compile-checked the host with MSVC, using a stub GL type header in the scratchpad. `io.cpp` (with the PGD change), `kernel.cpp`, `modules.cpp`, `devices.cpp`, `sas.cpp`, `mpeg.cpp`, `font.cpp` and `atrac.cpp` all compile. `savedata.cpp` has 2 POSIX errors (`stat` on `path::value_type`, `localtime_r`). The real blocker is that every host file includes `ge_gl.hpp`, which includes `GLES3/gl3.h`, through `ge.hpp`.

## Unverified / not done

- None of the phase-02 deliverables exist yet:
  - `recomp/loader/elf_prx.*`, `relocs.*`, `nid_db.*`
  - `recomp/analysis/cfg.*`, `functions.*`, `jumptables.*`
  - `data/nids.toml`
  - trace-feedback recording and ingestion
- The phase validation has not run: 100% of symbol functions found after one feedback pass, and every import resolved or reported.
- No recompiled code was executed. A Windows host is still missing.

## Resume from here

1. **Gaps, already mapped from the code.** `recomp/src/elf32.cpp` handles only `SHT_PSPREL` *sections* with type-A relocations, and finds module info only by section name. Missing:
   - program-header relocations `0x700000A0` and the packed `0x700000A1` format (PPSSPP `Core/ELF/ElfReader.cpp:265 LoadRelocations2`; the GPL code belongs in a new `recomp/loader/relocs.cpp`);
   - module info via `segments[0].p_paddr & 0x7FFFFFFF` when there are no sections;
   - lenient parsing of sections past EOF;
   - `R_MIPS_16`, and ignoring NONE/GPREL16;
   - export-table parsing (the host's `modules.cpp:register_exports` shows the layout) and variable imports;
   - PBP `DATA.PSP` extraction.
2. **Next step.** Write `recomp/loader/relocs.{hpp,cpp}`, `elf_prx.{hpp,cpp}` and `nid_db.{hpp,cpp}` (namespace `anypsp::loader`, GPL headers), plus a GPL test executable. Then add `tools/gen_nids.py`, which extracts `{nid, "name"}` and `RegisterHLEModule` from `refs/ppsspp/Core/HLE/*.cpp` at `902e5ccd8c1400b4387b73942491cded655e5f9c` into `data/nids.toml`, using SHA-1 to verify the names. Add both to the PPSSPP list in `THIRD_PARTY.md`.
3. **Analysis design.**
   - Add an `AnalysisOptions` overload to `psprecomp::analyze_program` (`recomp/src/program_analysis.cpp`) that takes extra seeds and relocation sites.
   - `analysis/cfg.*` builds delay-slot-aware blocks: a branch block includes its slot; a likely branch's slot runs only on the taken edge; a branch into a delay slot splits it.
   - `jumptables.*` does a symbolic forward evaluation over the `sltiu`/`sll`/`lui`/`addu`/`lw`/`jr` window, and reads the table from relocated memory.
   - `functions.*` iterates seeds to a fixpoint: exports, syslib module_start/stop NIDs, constant `a1`/`a2` at `jal` to the `sceKernelCreateThread`/`CreateCallback`/`SetAlarm`/VTimer/SubIntr stubs, jump-table targets, and feedback addresses.
   - Add a `--seeds <csv>` option to `psp_recomp --auto` (`recomp/tools/codegen_main.cpp:1554 generate_auto`).
   - Record missing code to the file named by `PSPRECOMP_FEEDBACK_FILE` at the three `g_missing_code_handler` fallbacks in `recomp/src/runtime.cpp` (~lines 609, 686, 750), appending each address once and flushing.
4. **Validation input.** Measure static symbol coverage on the 7 unstripped demo ELFs. Running the feedback pass end to end needs a Windows host: a null GE backend seam between `ge.hpp` and `ge_gl.hpp`, plus the two `savedata.cpp` fixes. Decide whether that host belongs in phase 02, as the decision-base gap table says, or in phase 05/06.
5. **Not modified yet:** `runtime/host/modules.cpp` and `main.cpp` still use `Elf32Image::load_and_relocate`. Once the new loader exists, switch them to it so the static and runtime relocation agree.

## Open issues

- `plan.md`'s phase table still shows `pending` for phases 01 and 02. I edited the phase front-matter status lines, but `ak plan phase close/update 261023-1558-anypsp-static-recompiler …` fails with "planstore: plan not found", and I did not edit the table cells directly. `ak plan validate` passes.
- git-filter-repo was installed with `pip --user`, so it is available for future imports.

Status: DONE_WITH_CONCERNS
Summary: The base is imported (filtered history, patches applied, GPL-2.0-or-later with third-party notices, pinned corpus) and builds and tests on Windows. Phase 02 has started, but no phase-02 code is written because of the pause.
Concerns/Blockers: Running recompiled homebrew on Windows needs a GL-free host seam, which the phase 02 feedback validation depends on. The plan-store CLI cannot find the plan, so the phase table in plan.md is stale.
