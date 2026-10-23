# AnyGBA phases 02-04: implementation report

Work resumed after the pause. Phase 02 is complete and committed (`d91ee67` decoder, `622bc76`
discovery). Phases 03 and 04 are in progress below. Nothing has been pushed.

## Phase 02: decoder and function discovery (completed)

### Built

- `tools/recomp/decode/`: ARMv4T ARM and Thumb decoder into one `Insn` struct, and a disassembler in
  Capstone's syntax (`anygba_decode` library, to be shared with the runtime interpreter).
- `tools/recomp/analysis/`: `Image` (ROM plus ROM-backed RAM regions), a worklist CFG walker with
  per-path constant and table-arithmetic tracking (`cfg`), jump tables (`jumptables`), and function
  discovery with a no-return fixpoint (`functions`). Entry sources: ROM entry, config, miss log, BL,
  constant BX/MOV PC/LDR PC targets, `bx rN` veneers, IRQ vector stores, jump and pointer tables,
  and checked literal-pool pointers.
- `tools/recomp/config/game_config`: per-game TOML (`[game]`, `[[entry]]`, `[[ram_region]]`,
  `[[skip]]`, `[[patch]]`), strict keys, errors with file and line.
- `tools/recomp/io/miss_log`: reader and formatter for `0xADDR arm|thumb [rom=0xADDR]`; RAM misses
  with `rom=` get an inferred region on the next pass.
- CLI: `--miss-log FILE` (repeatable) and `--list` (functions with disassembly and notes).
- Docs: `docs/dev/GAME-CONFIG.md`; README and ARCHITECTURE updated. CI now fetches the corpus before
  CTest so the corpus-backed tests run there.

### Verified

- `anygba-tests`: 34 test cases pass (plus 2 Capstone cases, run separately below), MSVC `/W4 /WX`.
- Decoder against Capstone 5.0.6: Thumb exhaustive (58,222 identical texts, the rest post-ARMv4T,
  ARMv4T-only, or undefined in both); ARM all 4,096 classes x 64 samples (170,180 identical).
- Discovery unit tests on hand-assembled ROMs: BL, ARM to Thumb via literal BX, both IRQ vector
  forms, `ldrls pc` and `addls pc` tables, the GCC Thumb switch idiom, tail calls, no-return calls,
  literal-pool candidates accepted and rejected, the `mov lr, pc` call idiom, RAM regions, miss log.
- armwrestler against its ELF: 98.2% of code bytes (from `$a`/`$t` mapping symbols) discovered before
  any feedback, 0 bytes decoded inside `$d` data. 2 of 7 `STT_FUNC` symbols are found; the other 5
  (`deregister_tm_clones`, `register_tm_clones`, `__do_global_dtors_aux`, `frame_dummy`, `_fini`) are
  newlib startup glue reached only through `.init_array`/`.fini_array` data, which is what trace
  feedback is for. The hand-written test functions are all found.
- Discovery runs on every corpus ROM: all 35 tonc demos, gba-tests arm/thumb/memory, and Varooom 3D
  (1,094 functions, about 1.3 s for analysis plus listing). Paths hitting undefined encodings: 0 in
  most tonc demos, 6 in txt_se2, 1 in hello, 1 in Varooom.

### Pending, not blocking

- **tonc ELF ground truth: pending Docker (devkitARM image).** tonc-bin ships no ELFs and this machine
  has neither devkitARM nor Docker, so the 95% target is measured on armwrestler only.
- **"100% after one feedback pass"** needs the runtime's miss log, so it is checked in phase 04.

## Resume from here

- State: repo at `622bc76`, clean. Build dir `repos/anygba/out/msvc` (VS generator). Python 3.13 at
  `%LOCALAPPDATA%\Programs\Python\Python313\python.exe` (bare `python` is the Store alias).
- Next: phase 03. Define `runtime/include/anygba/cpu.h`, then the reference interpreter
  (`runtime/src/interp/`) as the oracle, then the C emitter, then differential tests and jsmolka
  arm/thumb end-to-end. Afterwards phase 04 and `.github/workflows/release.yml`.
