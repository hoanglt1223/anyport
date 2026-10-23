# AnyGBA phases 02-04: implementation report (paused)

The user paused the project partway through phase 02, so only the decoder part of phase 02 is
done. That work is committed locally in `repos/anygba` as `d91ee67` ("feat: ARMv4T ARM/Thumb
decoder and disassembler checked against Capstone"). Nothing has been pushed.

Phase status lines:

- Phase 02 is `in-progress` because function discovery, the TOML config, and miss-log ingestion
  are not written yet.
- Phases 03 and 04 are still `pending`; neither was started.
- No release workflow was added (`.github/workflows/release.yml` does not exist yet).

## Phase 02: decoder and function discovery

### Built

- **`tools/recomp/decode/insn.h`**: one instruction struct (`Insn`) for both ARM and Thumb.
  - Every Thumb instruction is stored as its ARM equivalent.
  - `thumb_format` keeps the Thumb format number for the disassembler.
  - `pc_align` covers the Thumb PC-relative forms, whose base is `PC & ~3`.
  - A lone Thumb BL half decodes as `Op::BL_HI` or `Op::BL_LO`.
- **`decode/arm.cpp`** (`decode_arm`): the full ARMv4T instruction set.
  - Covered: data processing, MUL/MLA, long multiplies, SWP/SWPB, LDR/STR including the T forms, halfword and signed transfers, LDM/STM, B/BL, BX, SWI, MRS, and MSR.
  - These decode as undefined: the NV condition, coprocessor instructions, and anything from ARMv5 or later.
  - Should-be-zero fields are ignored, as the ARM7TDMI does.
- **`decode/thumb.cpp`**: all 19 Thumb formats.
  - `decode_thumb` decodes a single halfword.
  - `decode_thumb_at` joins a BL prefix and the suffix after it into one 4-byte `BL` with its absolute target.
- **`decode/disasm.cpp`** (`disassemble`): prints instructions in Capstone's syntax.
  - This includes LLVM's rule for writing a rotated immediate as `#bits, #rot` and the push/pop aliases.
  - The two BL halves have no Capstone form, so they print as `bl.hi` and `bl.lo`.
- **CMake**:
  - New `anygba_decode` static library, meant to be shared with the runtime interpreter later.
  - toml++ v3.4.0 pinned by SHA-256, linked into the recomp library but not used yet.
  - Capstone 5.0.6 pinned by SHA-256. It is linked only into `anygba-tests` and is `EXCLUDE_FROM_ALL`, so nothing shipped depends on it.
- **`tests/recomp/decode_tests.cpp`**: the Capstone comparison tests, described below.

### Verified

- **Build:** `cmake --build out/msvc --config Release` with `ANYGBA_WARNINGS_AS_ERRORS=ON` (MSVC `/W4 /WX`) builds cleanly.
- **Decoder tests** (`anygba-tests -tc="*decoder*"`): 4 of 4 test cases pass.
  - **Thumb, all 65,536 halfwords:**
    - 58,222 decoded to exactly the same text as Capstone.
    - 2,401 are post-ARMv4T encodings (IT, CBZ, BLX, and similar).
    - 2,066 are valid on ARMv4T but have no Capstone equivalent: lone BL suffixes and empty register lists.
    - 2,911 are undefined in both.
    - Every BL prefix was also checked as a pair with a suffix.
  - **ARM, sampled:** all 4,096 instruction classes (bits 27-20 and 7-4), 64 random words per class.
    - 170,180 decoded to the same text as Capstone.
    - 58,518 are post-ARMv4T or NV-condition encodings.
    - 5,048 are valid on the ARM7TDMI but rejected by Capstone, in three groups: empty register lists, MOV/MVN with a nonzero Rn, and MRS with nonzero low bits.
  - **ARM edge cases:** 40 hand-picked encodings, plus spot checks on decoded fields.
- **How "post-ARMv4T" is decided:** the test only accepts that label when Capstone's mnemonic is on a reviewed list of later-architecture and coprocessor mnemonics in the test file. A decoder that wrongly rejects a valid ARMv4T instruction still fails the test.
- **Full suite:** `ctest --test-dir out/msvc -C Release` passes 2 of 2 (unit tests and the headless platform smoke).

### Not done or unverified

- Steps 3-6 are not written: the CFG walker, function discovery, jump-table recognition, the per-game TOML schema, and miss-log ingestion. The files `analysis/*`, `config/game_config.*`, `io/miss_log.*`, and `tests/recomp/discovery_tests.cpp` do not exist yet.
- The decoder has only been built with MSVC; it has not been compiled on Linux or macOS.
- **Ground-truth limitation for discovery validation.** The only ELF in the corpus is `armwrestler-gba-fixed.elf`.
  - The tonc binaries ship without ELFs.
  - gba-tests has only assembler source.
  - This machine has no devkitARM and no Docker to build ELFs.
  - So the "95% of ELF symbols" target can only be measured on armwrestler unless someone provides ELFs.

## Phases 03 and 04

Not started. Design notes written during this session are under "Resume from here".

## Open issues

1. **Capstone archive hash.** Capstone is fetched from a GitHub tag archive, not a release asset. GitHub says these archives are stable, but if the hash ever changes, re-pin it.
2. **Validating tonc discovery.** This needs either ELFs built with devkitARM elsewhere, or a decision to use trace feedback as the ground truth instead.
3. **Multiboot builds.** The tonc demos are multiboot builds: crt0 copies the image to EWRAM at `0x02000000`. Discovery therefore needs a config RAM region `(0x08000000 -> 0x02000000, whole image, arm)` before it finds anything past crt0.

## Resume from here

- **State:** the repo is at `d91ee67` with a clean working tree. The build dir is `repos/anygba/out/msvc` (Visual Studio generator). Python 3.13 is at `%LOCALAPPDATA%\Programs\Python\Python313\python.exe`; the bare `python` on PATH is the Store alias and does not work.
- **Next step:** phase 02 step 3. Create `tools/recomp/analysis/cfg.{h,cpp}` and `functions.{h,cpp}`:
  - A worklist CFG walker over a ROM image plus mapped RAM regions, tracking ARM/Thumb mode.
  - Function starts come from: the entry point, BL targets, BX/literal-pool pointers with bit 0 giving the mode, and the IRQ handler stored to `0x03007FFC`.
  - Stop a block at an unconditional B, at `BX LR`, at `POP {PC}`, and at `MOV PC, LR`.
  - Treat `mov lr, pc` followed by an indirect branch as a call, so the walk continues after it.
  - Then write `jumptables.*`, `config/game_config.*` (toml++, already linked), and `io/miss_log.*`, plus `discovery_tests.cpp`, measured against the symbols in the armwrestler ELF.
- **Design decided for phase 03/04** (not yet coded):
  - Each function becomes `void f_XXXXXXXX(cpu_t*)`.
  - A function always leaves the next PC in `r[15]` and returns.
  - A BL call site pushes its expected return address onto a shadow stack, calls the function, then checks `r[15] == ret`.
  - If the check fails, `anygba_return_mismatch` handles it. If the PC matches an outer frame, it unwinds by returning. Otherwise it trampolines through the dispatcher (a recompiled function, or the interpreter until it reaches one) until the PC matches. `longjmp` is used only when the C stack gets too deep.
  - The reference interpreter executes `Insn` with its own C++ semantics, independent of the `cpu.h` helpers that generated code uses, so the differential test stays meaningful.
  - jsmolka arm and thumb pass when the ROM reaches its `idle` self-loop with r12 == 0.
- **Still owed from the brief:** `.github/workflows/release.yml`, which builds `anygba-recomp` and the runtime on tag `v*` for Windows, Linux, and macOS and attaches them to a GitHub Release.

## Unresolved questions

- Where should ELF ground truth for the tonc demos come from (a devkitARM build elsewhere, or a CI job)?
