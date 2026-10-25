---
handoff-version: 1
created: 2026-10-26 00:20 Asia/Saigon (2026-10-25 17:20 UTC)
from: Windows PC, forked Claude session (AnyGBA function overrides + Emerald translation table)
to: Linux build box dev-b3 (/home/ubuntu/anyport)
---

# Handoff: AnyGBA function overrides -> dev-b3

## Pull first

- Workspace: `git fetch origin && git switch worktree-function-overrides-plan` (or merge it into main): plan
  `plans/261025-1559-anygba-function-overrides/` (phases 01-04 completed, 05 pending) and reports
  `plans/reports/*261025-16xx..2100*` for overrides, this handoff.
- `repos/anygba`: `git fetch origin && git switch feat/function-overrides` — commits on top of ae90434:
  aec3eb9 spike (StringCopy via `[[replace]]`), fa9d5f7 override layer, 4ae6e1f difftest, b5d8037 `anygba decomp`.

## State

- Override layer: `[[override]]` entries (address or symbol, impl, enabled, engine, verified), `ANYGBA_OVERRIDE`
  registry, guest API `runtime/include/anygba/override.hpp`, `anygba build --overrides DIR`, `--overrides on|off|all`.
  Docs: `docs/dev/OVERRIDES.md`. Example module `overrides/pokemon-gen3/` (StringCopy, verified).
- Difftest: `<game> --difftest FUNC` / `anygba difftest`; gate = ABI-level equality and >=95% normal returns
  (`min_returned`, exit 3 = insufficient); full-state differences reported separately; `--record-entry`, coverage,
  minimised diff, `--json`, `--mark-verified`.
- `anygba decomp`: Ghidra headless export (Windows: Ghidra 12.2 + JDK 25 under C:\Tools; install the same on Linux)
  + `claude -p --safe-mode` (engine claude-cli; no ANTHROPIC_API_KEY anywhere) + difftest retry loop; batch mode.
  Results: 8/8 corpus functions, 5/5 Emerald string/text helpers first try.
- Tests on Windows: `ctest -LE slow` 24/24; 41 compat checkpoints green at phase 02 (not rerun after 03/04 —
  rerun them).
- Emerald dialogue table `%APPDATA%\anyport\anygba\translation\BPEE-vi.jsonl` re-translated with Claude
  (10,162/10,182 lines; 20 keep the local-model text). It is ROM-derived: never commit; copy it to the Linux
  per-user data folder if you test translation there. Script: `%TEMP%\anyport-retranslate\retranslate.py`.

## Blocker for phase 05

Phase 05 (Gen 3 text printer override drawing through the host text layer) needs the AnyGBA work still
UNCOMMITTED on the Windows `repos/anygba` main checkout (translate/, window `set_layer`/`set_hud`, stats line,
deferred HD render, English smooth-font mode, `\n`/table lookup fixes). The Windows session "Bàn giao
anyport-to-windows" owns it and commits only after the user confirms there; the HD-pack agent's files
(`runtime/src/video/hd/{ai,renderer,session}.*`, `tests/runtime/hd_pack_tests.cpp`, `tools/anygba/main.cpp`) stay
uncommitted until that agent finishes. Once main is committed and pushed: merge `feat/function-overrides` onto it
(expect conflicts in runtime/src/main.cpp, runtime/CMakeLists.txt, tests/CMakeLists.txt, docs/user/USAGE.md,
compat/symbols/BPEE.toml, tools/anygba/build.cpp), rerun `ctest -LE slow` and compat, then do phase 05.

## Next (in order)

1. Wait for / pull the committed AnyGBA main; merge `feat/function-overrides`; tests + compat.
2. Phase 05: `anygba decomp` the Gen 3 printer path (Emerald BPEE), host glyph layer, then FireRed symbols with the
   same `overrides/pokemon-gen3/` module; headless screenshots at 1920x1080 (field, battle, menu).
3. Known bug (not fixed): a `[[skip]]` range containing a function entry generates `{ AG_ENTER(...); }` with no
   exit and the game hangs.
4. `anygba difftest` front end reports any exit 1 as fail (game uses 1 for errors too); `claude-opus-5-5` API path
   untested.

## Decisions already made (do not re-ask)

- Overrides build on `[[replace]]`; missing engine symbols are a build error (not a warning).
- Difftest gate: ABI level + >=95% normal returns.
- LLM only offline through the user's Claude CLI; nothing ROM-derived in repos.
