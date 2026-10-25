# AnyGBA function overrides: Linux reruns, two bug fixes, phase 05 (Emerald printer), FireRed symbols

Branch `feat/function-overrides` in `repos/anygba-overrides` (not pushed), rebased onto main d856400:
e0ae3e9..6c9f1e6 (the 4 earlier branch commits were rewritten by the rebase too, so pushing needs a force push).
Plan files updated in `/home/ubuntu/anyport-overrides/plans/261025-1559-anygba-function-overrides/`
(phase 05 now `in-progress` with results, remaining work and host-layer integration points).

## Done

1. **Linux reruns.** `ctest -LE slow` (65 tests incl. the 41 compat checkpoints) passes. `video-timing`
   (4K CPU filter budget) and `mcp-e2e` fail only under the shared box's load (load average 27) and pass
   when rerun. Linux-only failure fixed: `anygba build` of a game with C++ overrides failed because CMake
   scanned for C++ modules and clang-scan-deps is missing; generated games now set
   `CXX_SCAN_FOR_MODULES OFF` (fb5477f, test in `override_config_tests.cpp`).
2. **`[[skip]]` hang (26c1865).** Decision: discovered entries (call, branch, table, miss log) inside a
   skip range, or whose first instruction does not decode, are not generated and stay in the
   interpreter (with a note); entry points named by the config (`[entry]`, `[[ram_region]]`,
   `[[replace]]`, `[[override]]`) inside a skip range are a config error. Tests in
   `discovery_tests.cpp` and `override_config_tests.cpp`.
3. **difftest exit codes (a42c4f6).** The front end always has the game write its JSON report and accepts
   0/1/3 only when the report's `status` matches; otherwise exit 2 with "the game stopped with exit code N
   before finishing the difftest". `decomp.py` checks the same. Test in `override-difftest.cmake`.
4. **Phase 05, Emerald.** 10 printer functions overridden in `overrides/pokemon-gen3/` (BPEE only), all
   `verified = true` by `anygba difftest --mark-verified`: ABI pass on 10,000 random + 64-3,000 recorded
   dialogue states, 100% normal returns, block coverage 87-100%. Frames/EWRAM/VRAM identical with overrides
   off/on/all over a 9,000-frame scripted run. Needed along the way:
   - d08ada9: recompiler resolves agbcc's `cmp; bls table; b default` switch (RenderText was a trampoline
     before); Emerald output behaviour unchanged, compat green.
   - a9df017: difftest shapes take `memory = [{ addr, size, bytes }]` to plant globals (coverage of
     CopyGlyphToWindow 31 -> 78 of 79 blocks, RenderText 68 -> 102 of 106).
   - ea6d9cf: `[[override]] games = [...]`, because the printer overrides replay Emerald's machine code.
5. **FireRed symbols (9191dcf).** `compat/symbols/BPRE.toml` (v1.0) from pret/pokefirered's published
   `symbols` branch, so no agbcc Docker build was needed.

## Remaining (why)

- Host glyph layer, palette mapping, menu toggle, 1920x1080 screenshots: needs the Windows AnyGBA code
  (translate/, `set_layer`/`set_hud`) that is not committed. Integration points are in the phase file.
- FireRed verification: no FireRed ROM on this box. Most printer functions compile differently in FireRed
  (other sizes), so they need their own `anygba decomp` run; only StringCopy, RenderFont, FontFunc_Normal
  and TextPrinterWaitWithDownArrow may be shareable. The plan's "symbols-only reuse" criterion does not
  hold for the printer.
- Battle/menu printers: only intro and field dialogue states were recorded.

## Controller decisions applied

- The 10 printer overrides were removed from the repository: the commit that added them was rewritten, and
  it never existed on the remote. The generated module is at `~/anyport-out/overrides/pokemon-gen3-printer/`
  (overrides.toml, 10 .cpp, difftest.toml). The repo keeps
  `overrides/pokemon-gen3/decomp/BPEE-printer.{funcs,toml}` (names and difftest shapes). The command that
  regenerates the module is in `docs/dev/OVERRIDES.md` and the phase file. It was checked with
  `--engine none`.
- The plan now records the agbcc switch fix as an accepted exception to its non-goal.
- Rebased on main d856400. There were two conflicts, both resolved by keeping both sides:
  `cmake/install.cmake` (configs and overrides installs) and `tools/anygba/build.cpp` (shipped symbols for
  overrides, then main's shipped config).
- After the rebase: `ctest -LE slow` passes 65/65 and `ctest -L compat` passes 41/41. Emerald built with
  both modules and main's shipped BPEE config still passes all ten difftests with the same coverage. The
  9,000-frame run is identical with overrides on and off.

## Concerns

- Both earlier concerns are resolved by the controller decisions above. One remains: the switch fix
  was not tested on agbcc games other than Emerald.
