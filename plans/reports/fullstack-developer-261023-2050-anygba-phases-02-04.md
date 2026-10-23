# AnyGBA phases 02-04: implementation report

Phases 02, 03 and 04 are implemented, verified on this machine, and committed locally in
`repos/anygba`. Nothing has been pushed. The release workflow is added but has not run.

| Phase | Commit | Status line |
|---|---|---|
| 02 decoder and function discovery | `d91ee67`, `622bc76` | completed |
| 03 C code generator | `55970e7` | completed |
| 04 runtime core | `7db15fa`, `f832884` (test fix) | completed |

All numbers below come from `out/msvc` (Visual Studio 17 2022, x64, MSVC 14.44, CMake 4.4.4),
Release with `ANYGBA_WARNINGS_AS_ERRORS=ON` (`/W4 /WX`), unless stated otherwise.

## Phase 02: decoder and function discovery

### Built

- **Decoder** (`tools/recomp/decode/`): ARMv4T ARM and all 19 Thumb formats into one `Insn` struct.
  - Thumb is stored as its ARM equivalent. Lone BL halves stay separate ops; a BL prefix plus its suffix becomes one 4-byte BL.
  - Disassembler output uses Capstone's syntax, including LLVM's `#bits, #rot` form for non-canonical immediates.
  - Builds as the `anygba_decode` library, which the runtime interpreter also uses.
- **Analysis** (`tools/recomp/analysis/`):
  - `Image`: the ROM plus RAM regions backed by ROM bytes.
  - `cfg`: a worklist walker that tracks constants and table arithmetic along each path.
  - `jumptables`: three forms are recognised.
    - `ldr pc, [pc, rI, lsl #2]`
    - `add pc, pc, rI, lsl #2` followed by a branch list
    - GCC's Thumb `lsl / ldr =table / add / ldr / mov pc` sequence

    A table with no visible bound is read as function pointers.
  - `functions`: discovery to a fixpoint, including a fixpoint that marks functions which never return.
- **Entry sources**:
  - the ROM entry, config entries, and miss-log entries;
  - BL targets, including calls through `bx rN` veneers when the caller's `rN` is a known constant;
  - BX, MOV PC, LDR PC, and `subs pc` targets that are constants;
  - IRQ handler stores to 0x03007FFC or its mirror 0x03FFFFFC;
  - jump-table and pointer-table entries;
  - literal-pool values, accepted only after a plausibility check.
- **Per-game TOML config** (`tools/recomp/config/`, toml++ 3.4.0 pinned): sections `[game]`, `[[entry]]`, `[[ram_region]]`, `[[skip]]`, `[[patch]]`. Unknown keys are rejected. Errors give the file, line, and key.
- **Miss log** (`tools/recomp/io/`): lines of the form `0xADDR arm|thumb [rom=0xADDR]`. A RAM miss that carries `rom=` gets a RAM region inferred on the next pass.
- **CLI**: added `--miss-log` (repeatable), `--list` (functions with disassembly), and `--shards N`.

### Verified

- **Decoder against Capstone 5.0.6** (a test-only dependency, pinned by hash):
  - Thumb, all 65,536 halfwords: 58,222 produce identical text.
  - The remaining Thumb encodings each fall into a counted category: post-ARMv4T, valid on ARMv4T but rejected by Capstone, or undefined in both.
  - ARM: all 4,096 classes with 64 samples each; 170,180 produce identical text.
  - When the decoder rejects an encoding that Capstone accepts, the test passes only if Capstone's mnemonic is on a reviewed list of later-architecture or coprocessor mnemonics.
- **Discovery unit tests** use hand-assembled ROMs, one per idiom listed above, plus the config tests and miss-log tests.
- **armwrestler against its ELF**, before any feedback:
  - 98.2% of code bytes found (9,082 of 9,246, measured from the `$a`/`$t` mapping symbols).
  - 0 bytes decoded inside `$d` data.
  - Only 2 of the 7 `STT_FUNC` symbols are found. The other 5 are newlib startup glue reached only through `.init_array`/`.fini_array` data, which trace feedback covers. All of the hand-written test functions are found.
- **Discovery on the rest of the corpus**: it runs on all 35 tonc demos, on gba-tests, and on Varooom 3D.
  - Varooom 3D yields 1,094 functions, and only 1 path hits an undefined encoding.
  - That number only came down after adding the no-return fixpoint. Before it, 57 paths decoded literal pools that follow calls to Butano's assert, which never returns.

### Pending, not blocking

- **tonc ELF ground truth: pending Docker (devkitARM image).** tonc-bin ships without ELFs, and this machine has neither devkitARM nor Docker. The 95% target is therefore measured on armwrestler only.

## Phase 03: C code generator

### Built

- **`runtime/include/anygba/cpu.h`**: the `anygba_cpu` struct and the C ABI that generated code calls.
  - CPU state: 16 registers, separate N/Z/C/V flag fields, the T bit, banked registers, and the SPSR.
  - A page-table fast path for memory reads and writes.
  - Fetch costs per memory region, taken from WAITCNT.
  - Inline helpers for flags, shifts, and the ARM7 load quirks: rotated misaligned LDR and LDRH, and LDRSH on an odd address loading a sign-extended byte.
  - Macros `AG_SPEND`/`AG_TICK` for cycle accounting and `AG_CALL`/`AG_ICALL` for calls.
- **Code generator** (`tools/recomp/codegen/`): `c_emitter` (function structure), `arm_ops` (instruction semantics), `thumb_ops` (lone BL halves), and `dispatch_table` (writes `game.h`, the `funcs_NNN.c` shards, `dispatch.c` with the ROM's SHA-256, and a `CMakeLists.txt`). Translation rules:
  - Branches inside a function become `goto`; conditional instructions become `if` blocks.
  - Bounded jump tables become a `switch` over the case labels.
  - BL becomes a direct C call that checks the return address.
  - Other indirect branches set the PC and return to the caller.
  - A branch to itself calls `anygba_idle_loop`, which skips ahead to the next scheduled event.
  - PC-relative word loads from ROM are folded into constants.
  - Cycle costs are batched and charged at labels and before control flow.
- **Return model.** Every function exits with `r[15]` set to the address where execution continues.
  - A call site compares that address with the return address it expects.
  - On a mismatch, `anygba_resume` keeps dispatching (recompiled function, else the interpreter) until the address matches. If an outer call site expects the address instead, the frames return up to that site.
  - `longjmp` (`anygba_unwind`) is used only for context switches and for an overflowing return stack.
- **Reference interpreter** (`runtime/src/interp/`): its own C++ implementation of the instruction semantics. It shares only the decoder with the recompiler. It was built early so it could serve as the test oracle.
- **Shared rules for unpredictable cases.** These are applied identically in the generated code and the interpreter, so they behave deterministically:
  - reading the PC as an operand returns the constant PC value;
  - multiply, SWP, MRS, and block-transfer writeback results that would land in R15 are dropped;
  - legacy TSTP/CMPP with Rd = PC sets CPSR from SPSR, which jsmolka test 234 checks.

### Verified

- **Differential test**: about 13,000 sampled instructions (ARM by class, Thumb at random) are generated as C at build time. Each runs from 80 random register, flag, mode, and memory states through both the generated code and the interpreter.
  - **1,025,893 states compared, 0 mismatches.** 12,667 states were skipped because their addresses fell outside the memory sandbox.
  - This test found real bugs before it passed: inconsistent PC reads, and writeback that set PC.
- **jsmolka arm.gba and thumb.gba pass as recompiled native code.** Each reaches its idle loop with r12 = 0, which means every test passed. These run as CTest entries `gba-tests-arm` and `gba-tests-thumb`.
  - Bugs found along the way: the TSTP mode switch; STM with an empty list storing PC+6 in Thumb; MSR with no field mask needing to be a no-op; `subs pc, pc, #4` needing to resolve to a constant target; the interpreter not detecting branch-to-self.
- **The interpreter on its own** also passes jsmolka arm, thumb, and memory, which confirms the oracle independently of the code generator.
- **Varooom 3D** (Butano, about 20 MB of generated C) compiles in 1 min 40 s. It then runs until its first unimplemented BIOS call: SWI 0x12, LZ77UnCompVram (phase 05).

### Deviation

- The plan called for a stub runtime that provides only memory and a text-output hook. I linked the real runtime instead, because it was already needed as the oracle. Pass/fail is read from the ROM's own r12 result register, not from captured text.

## Phase 04: runtime core

### Built

- **Memory bus** follows GBATEK.
  - Mirrors: EWRAM, IWRAM, palette, VRAM including its 32 KiB mirror, OAM, and ROM at three wait-state mirrors.
  - Byte-write rules: palette doubles the byte, VRAM accepts byte writes only to BG memory (bitmap modes included) and doubles them, and OAM ignores them.
  - SRAM is an 8-bit bus: reads return the byte repeated, writes store the selected byte lane.
  - ROM reads past the image return the open-bus pattern. BIOS reads return the last BIOS opcode.
- **IO registers**:
  - DISPSTAT and VCOUNT with LYC match, IE, IF (write 1 to clear), IME, and WAITCNT. A WAITCNT write updates the fetch costs.
  - KEYINPUT, and HALTCNT, which halts until an interrupt.
  - DMA and timer registers.
- **Scheduler**: counts cycles down to the next event: HBlank at cycle 1006, line end at 1232, 228 lines per frame, and timer overflows.
- **Interrupts and BIOS waits**:
  - Interrupts are delivered synchronously, the way the BIOS vector does it: registers saved on the IRQ stack, `lr = 0x138`, then return via `subs pc, lr, #4`.
  - SWI Halt, IntrWait, and VBlankIntrWait are implemented. Any other SWI stops the run with an error naming its number and address.
- **DMA**: channels 0-3 with immediate, VBlank, and HBlank timing; every address-control mode; repeat with destination reload; and an IRQ on completion.
  - `request_fifo_dma()` is the sound-FIFO hook that the APU will call.
  - The DMA3 video-capture timing is not triggered.
- **Timers**: read lazily, prescalers, overflow IRQs, and count-up cascade.
- **Dispatcher**: a direct table for ROM addresses and binary search for RAM addresses.
- **Miss log**: logs every address where interpretation started, plus every call target the interpreter reaches that has no recompiled code. For RAM addresses it adds the matching `rom=` source.
- **`main.cpp`** (`anygba::game_main`): the host loop for generated games.
  - Checks the ROM's SHA-256 against the one the code was generated from.
  - Driven from VBlank: presents the frame through the platform window and feeds the audio stream with silence until the APU exists.
  - Paces by audio: it waits while more than two frames of audio are queued. Holding Tab fast-forwards.
  - Headless mode can pace with `FramePacer` (`--pace`).
  - Other options: `--frames`, `--seconds`, `--exit-on-idle`, `--miss-log`. Registers are printed on stop or error.
- **Install package** (`cmake/install.cmake` with `anygbaConfig.cmake`):
  - Contents: `anygba-recomp`, the runtime libraries, headers, SDL3 (static), and a CMake package.
  - Generated projects find it with `find_package(anygba)`.
- **`.github/workflows/release.yml`**: on a pushed `v*` tag it builds the package on Windows x64, Linux x64, and macOS arm64.
  - Each package is checked by building a tiny generated project against it.
  - The archives are attached to a GitHub Release using `gh release create`.

### Verified

- `ctest --test-dir out/msvc -C Release`: **8/8 pass**:
  - `unit-tests`: 48 doctest cases, 15,550 assertions, including the Capstone and differential tests;
  - `platform-smoke-headless`;
  - `gba-tests-arm`, `gba-tests-thumb`, `gba-tests-memory`;
  - `install-runtime`;
  - `feedback-irq_demo` and `feedback-dma_demo`.
- **jsmolka memory.gba passes** (`gba-tests-memory`, r12 = 0).
- **Trace feedback, end to end through the installed package.** The `tests/feedback-pass.cmake` script recompiles, builds, runs 600 frames, recompiles with the miss log, rebuilds, and runs again.
  - irq_demo: 7 addresses missed in pass 1, **0 after one feedback pass**.
  - dma_demo: 7 missed in pass 1, **0 after one feedback pass**.
  - The RAM entries carried `rom=` sources, and their IWRAM ISR code was recompiled in pass 2.
- **Frame count over 60 s.** I ran the pass-2 builds of irq_demo (VBlank IRQ through VBlankIntrWait) and dma_demo (HBlank DMA) with `--headless --pace --seconds 60`.
  - Both showed **3586 frames in 60.02 s**.
  - The expected count is 1 (the frame at t = 0) + 60.02 × 59.7275 = 3585.8, so both are within ±1.
- **Runtime unit tests** (`tests/runtime/system_tests.cpp`):
  - VBlank at exactly 160 × 1232 cycles, and 280,896 cycles per frame.
  - Timer prescaler, overflow IRQ flag, and cascade.
  - DMA immediate transfers with all address-control modes, the completion IRQ, and HBlank repeat (160 transfers per frame).
  - The sound-FIFO DMA hook.
  - A real IRQ handler running once per VBlank.
  - VBlankIntrWait.
  - Bus quirks. This test found an SRAM bug: reads were aligned before reaching the 8-bit bus.
- **The release smoke flow, run locally**:
  - install the package;
  - make a 256-byte `b .` ROM;
  - recompile it, then configure and build it against the package;
  - run it headless: it reaches its idle loop.
- **Debug configuration**: builds without warnings, and `ctest -C Debug -LE slow` passes 6/6.
  - The Debug run exposed a test bug (a dangling reference to a temporary `Discovery`), fixed in `f832884`. It was a test bug, not a product bug.
- Both workflow files parse as YAML (PyYAML); neither has run on GitHub.

### Unverified

- **Windowed mode, audio pacing, and Tab fast-forward have never run.** This PC must not open windows or play audio. Only the headless paths were executed.
- **Neither workflow has run.** The CI changes and `release.yml` have not executed on GitHub, so Linux, macOS, and clang-cl have never compiled any of this code. With GCC or Clang, `-Wconversion` will probably produce warnings; CI does not treat warnings as errors.
- **Open bus is approximate.** Reads return 0 because recompiled code does not track the last prefetched opcode.
- **No tonc demo ran to completion with visible output.** There is no PPU yet. Demos that call other SWIs (`swi_vsync` uses 0x0F, `tmr_demo` uses 0x10) stop with a clear error until phase 05.

## Open issues

1. **Generated RAM code is never re-checked.** It is assumed to equal the ROM bytes it was compiled from. Code that changes IWRAM contents at run time (overlays, self-modifying code) would run stale native code; nothing detects this yet.
2. **The fallback interpreter is slow** (it does a function lookup after every branch). That is acceptable for misses, but a game that is largely missed will run slowly until its first feedback pass.
3. **SWI handling skips the SVC switch.** It does not switch into SVC mode or bank SVC registers. Phase 05 should decide whether any game depends on that.
4. **The feedback tests add about 70 s.** CI time grows by that much; they are labelled `slow`, so `ctest -LE slow` skips them.
5. **Capstone is fetched from a GitHub tag archive.** If its hash ever changes, re-pin it.

## Resume from here

- Repo at `f832884`, with a clean tree. Build dir `repos/anygba/out/msvc`.
- Phases 02-04 are complete. Next in the plan are phases 05 (HLE BIOS), 06 (PPU), and 07 (APU); they can run in parallel.
- Hooks already in place for them:
  - `System::swi` (`runtime/src/irq.cpp`) dispatches the SWI numbers;
  - `System::framebuffer()`;
  - `request_fifo_dma()`;
  - the silence feed in `main.cpp`, which the APU will replace.
- Before relying on CI, push and fix whatever GCC, Clang, and macOS report.

## Unresolved questions

- Where should tonc ELF ground truth come from: a devkitARM Docker image on a machine that has Docker, or a CI job?
