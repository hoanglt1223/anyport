---
phase: 5
title: "Gen 3 text printer override, Emerald and FireRed"
status: in-progress
effort: 1-1.5w
dependsOn: [4]
---

# Phase 05: Gen 3 text printer override, Emerald and FireRed

## Context

The first real use: the dialogue overlay added on 2026-10-25 draws text over the game's box by
reading memory each frame. With overrides, the Gen 3 text printer itself can hand each glyph run to
the host, so English and Vietnamese text render through the host font at window resolution inside
the game's own layout, with no overlay box and with scrolling, colours and speed preserved.

## Requirements

1. Decomp (phase 04) and verify (phase 03) the Gen 3 text printer path: glyph rendering into window
   tiles and the per-frame printer step; keep the original as fallback.
2. Override renders glyphs into a host text layer aligned to the game window/tiles; colours from the
   printer's palette; translation (existing table) applied at the string level.
3. Engine module `overrides/pokemon-gen3/` used by Emerald and FireRed, differing only in symbol
   tables (FireRed symbols from the pret/pokefirered reference, user's own ROM).
4. Toggle in the menu next to "Dialogue translation"; falls back to the overlay when the override is
   off.

## Files

- `overrides/pokemon-gen3/` (engine module, no ROM data), `compat/symbols/BPEE.toml`, a FireRed
  symbols file, `docs/user/TRANSLATION.md`

## Steps

1. Decomp + difftest the printer functions; enable for Emerald.
2. Host glyph layer and palette mapping; screenshots in field and battle.
3. FireRed symbols; same module; screenshots.

## Validation

- Difftest passes for every overridden printer function (≥10,000 states, recorded real states
  included).
- Headless screenshots at 1920x1080 in field, battle and menu text for Emerald and FireRed show host
  font text, correct colours and page breaks; frame pacing at 60 fps.
- With overrides off, frame hashes match the current build.

## Risks and rollback

- Battle and menu windows may use different printers; cover them one by one and keep the overlay
  path for any not yet overridden.

### Results (2026-10-25, Linux box, branch `feat/function-overrides` rebased on main d856400, e0ae3e9..6c9f1e6)

Done (requirement 1, part of 3):

- Emerald (BPEE) printer path overridden (module kept outside the repo, see "Shipping" below):
  RunTextPrinters (per-frame step), RenderFont, FontFunc_Normal, RenderText (printer state machine),
  DecompressGlyph_Normal, DecompressGlyphTile, CopyGlyphToWindow (glyph into window tiles), ClearTextSpan,
  TextPrinterDrawDownArrow, TextPrinterWaitWithDownArrow. Written by `anygba decomp` (claude-cli/opus,
  Ghidra 12.2, JDK 25 on Linux): 9 of 10 on the first or second answer, RenderText after the recompiler fix
  below (2 answers). Model cost reported 5.6 USD in total.
- Gate met for every function: ABI PASS on 10,000 random states plus the recorded states (RenderText 3,000,
  RunTextPrinters/RenderFont/FontFunc_Normal/DecompressGlyphTile 2,000, CopyGlyphToWindow 1,153,
  DecompressGlyph_Normal 1,139, the two arrow functions 634, ClearTextSpan 64), 100% normal returns,
  `verified = true` written by `anygba difftest --mark-verified`. Block coverage 100% except
  RunTextPrinters 13/15 (printer callback never set in the recorded play), RenderText 102/106,
  CopyGlyphToWindow 78/79. Full state identical everywhere except RenderText's exit flags (NZCV, not ABI).
- Recorded states: base save state taken in Prof. Birch's speech (`--script` Shift+F1 at frame 2010 of a
  scripted run from reset), then `<game> --load-state ... --keys a:... --record-entry FUNC --count 2000`
  per function (scratch only, ROM-derived). DrawDownArrow and GetGlyphWidth_Normal are not called in
  dialogue and were left out.
- Frame hashes: a 9,000-frame scripted run from reset (title, intro, truck, first dialogue) gives the same
  10 screenshots, final frame hash, EWRAM and VRAM with `--overrides off`, `on` and `all`; the 41 compat
  checkpoints and `ctest -LE slow` (65 tests) pass.
- FireRed: `compat/symbols/BPRE.toml` (v1.0 / rev 0) from `pokefirered.sym` on pret's `symbols` branch
  (no Docker build needed: the symbols branch is published).

Shipping (controller decision): the printer overrides replay Emerald's own code, so they are NOT in the
repository (public). The generated module, symbol-based and ready for `anygba build --overrides`, is at
`~/anyport-out/overrides/pokemon-gen3-printer/` on the Linux box (overrides.toml + 10 .cpp + difftest.toml).
The repo holds only what reproduces them: `overrides/pokemon-gen3/decomp/BPEE-printer.funcs` (names) and
`BPEE-printer.toml` (difftest shapes), plus the [functions] names in `compat/symbols/BPEE.toml`. Users
regenerate with (docs/dev/OVERRIDES.md, "Emerald's text printer"; checked with `--engine none`):

```
anygba decomp emerald.gba --funcs overrides/pokemon-gen3/decomp/BPEE-printer.funcs \
    --symbols compat/symbols/BPEE.toml --spec overrides/pokemon-gen3/decomp/BPEE-printer.toml \
    --load-state <dialogue state> --recorded <FUNC>.states ... --engine claude-cli --attempts 6
```

After the rebase on main (shipped BPEE config with xbrz4x and widescreen culling) the module still builds,
all ten difftests pass with the same coverage, and the 9,000-frame run matches with overrides on and off.

Design calls:

- Engine reuse is not "symbols only" for the printer: FireRed compiles RunTextPrinters, RenderText,
  CopyGlyphToWindow, DecompressGlyphTile, DecompressGlyph_Normal, ClearTextSpan, DrawDownArrow and
  TextPrinterDrawDownArrow to code of other sizes, and an override replays one translation block by
  block (plus hard-coded callee addresses). New `[[override]] games = [...]` limits entries to the game
  they were verified on; FireRed builds skip them. StringCopy, RenderFont, FontFunc_Normal and
  TextPrinterWaitWithDownArrow have the same size in both games and are the candidates for sharing once
  a FireRed difftest confirms them. The acceptance criterion "same override source runs on FireRed with
  only a symbols table change" needs per-game overrides (a FireRed `anygba decomp` run) for the rest.
- Recompiler (accepted as a correctness fix and a deliberate exception to the plan's non-goal "changing
  the recompiler's default output"): agbcc's switch (`cmp; bls table; b default`) lost its case bound at the branch target, so
  RenderText's translation was a 3-block trampoline into the dispatcher and could not be overridden.
  Taken `bls`/`bcc` branches now carry case bounds (Emerald frames/EWRAM/VRAM unchanged over 9,000
  frames; 20 fewer stand-alone functions).
- Difftest spec: shapes take `memory = [{ addr, size, bytes }]` to plant globals (gCurGlyph, gTextFlags,
  a whole printer and its text), which raised CopyGlyphToWindow from 31/79 to 78/79 blocks and
  RenderText from 68/106 to 102/106.

Remaining:

- Requirement 2 and 4, Step 2 (host glyph layer, palette mapping, menu toggle, 1920x1080 screenshots):
  needs the Windows AnyGBA work not yet on `main` (translate/, window `set_layer`/`set_hud`).
- FireRed verification and screenshots: no FireRed ROM on the Linux box. With one: build with
  `--overrides overrides/pokemon-gen3` (StringCopy applies through BPRE.toml), record states as above,
  run `anygba decomp` on the printer functions for BPRE (`games = ["BPRE"]` entries), difftest.
- Battle and menu printers: only the intro/field dialogue was recorded; record in battle and the Start
  menu once a save that reaches them is available.

Integration points for the host text layer (when the Windows code lands):

(Still not on main at d856400: no translate/ or window `set_layer`/`set_hud`. The override files named below
live in the user's regenerated module, so the host calls go into the guest API and the decomp prompt's
rules, and users regenerate; or they go into small hand-written hooks that wrap the generated overrides.)

- Guest API: add a host service to `runtime/include/anygba/override.hpp` next to `osd()`, e.g.
  `g.text_glyph(window_id, x, y, char_code, fg, bg, shadow)` and `g.text_clear(window_id, x, y, w, h)`,
  forwarded by `runtime/src/overrides/` to the window's text layer (`set_layer`) when a player runs and
  ignored headless/in difftests (so the gate is unchanged).
- `pokemon_gen3_RenderText` (render_text.cpp): in state 0 after the character is fetched (before
  DecompressGlyph via `g.call`), report the printer's window id (+4), currentX/currentY (+8/+9), fg/bg/
  shadow colours (+0xC/+0xD nibbles) and the char code; the translation table applies at the string level
  here (printer->currentChar at entry of state 0 points at the string; look it up once per printer start
  in AddTextPrinter's string).
- `pokemon_gen3_CopyGlyphToWindow` (copy_glyph_to_window.cpp): exact glyph rectangle in window pixels
  (x, y, clipped width/height from gCurGlyph +0x80/+0x81); map window pixels to screen with gWindows
  (0x02020004 + 12*id: bg, tilemapLeft, tilemapTop, width, height) for the host layer's position.
- `pokemon_gen3_ClearTextSpan` and the scroll states of RenderText (states 4/5) clear or scroll the host
  layer; `TextPrinterDrawDownArrow` positions the arrow. Palette: the window's paletteNum from gWindows
  plus fg/bg/shadow indices give BGR555 colours from palette RAM.
- Menu toggle next to "Dialogue translation": an `--overrides`-style runtime switch of these entries
  (`ag_override_on[]` per override) so off falls back to the overlay path.

