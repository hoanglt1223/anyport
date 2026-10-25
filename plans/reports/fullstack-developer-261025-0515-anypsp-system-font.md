# AnyPSP: sceLibFont without Sony's fonts

Date: 2026-10-25 (UTC). Repo: `repos/anypsp`, worktree `repos/anypsp-font`, branch `feat/system-font` (from `d28d6cf`), rebased onto main `b58bda7`, commits `ca0cc99` and `2c3f17b`, not merged or pushed. Build: `out/linux` (clang, Release, Ninja). Scratch: `/home/ubuntu/anyport/scratch-out/font/`.

## Outcome

UNH 1's Edit Your Profile screen now shows the nickname "PSP" in the NAME field (`scratch-out/font/name-crop.png`: before on top, after below). When a PGF file is missing or unreadable in `flash0/font`, sceLibFont serves a bundled replacement. Real PGF files there still take priority.

## Cause (confirmed)

- A `PSPWEB_TRACE_HLE` run (`scratch-out/font/diag/`, with the `house-prefix.txt` input) logs `[font] no system fonts in .../flash0/font`, then `sceFontNewLib`, and then two `sceFontFindOptimumFont` + `sceFontOpen` pairs. Both returned 0 with error `0x80460003`.
- With a temporary debug print (since reverted), the requested styles were h/v 15.0 pt, resolution 0, family 1 (sans), style 1 (regular), language 2 (Latin, i.e. `ltn0.pgf`), and the same again with language 3 (Korean, i.e. `kr0.pgf`).
- `sceFontGetFontInfo` and every later `sceFontGetCharInfo` failed on handle 0. The NAME field is drawn with sceFont. The text comes from `sceUtilityGetSystemParamString` (nickname "PSP", `devices.cpp`). With the fallback in place, the only pixels that change are in the NAME text box (below).

## Design

I chose pre-rasterised fonts at generation time and no runtime rasteriser. `tools/gen-fallback-fonts.py` uses FreeType through Pillow to write real PGF files (revision 2, 4 bits per pixel, RLE glyphs, metric tables). They match the PSP fonts' header sizes: 0x288 = 10.125 pt for jpn0, ltn0-7 and kr0, and 0x1C0 = 7 pt for ltn8-15, all at 128 dpi. That is 18 px and 12.4 px per em. As a result, `font.cpp` reads and draws them through its existing parser and renderer, and FontInfo, CharInfo, the GlyphImage pixel formats, clipping and the alternate character all behave exactly as they do for a real PGF.

- **Fonts**: 16 Latin fonts (Noto Sans and Noto Serif in regular, bold, italic and bold italic, each at both sizes; Latin-1, Latin Extended-A and punctuation; 358 glyphs, 27-42 KB each), `sans-jp.pgf` (Noto Sans CJK JP Medium, for jpn0's "DB" weight; Shift JIS up to the end of JIS X 0208 level 1: kana, symbols and the 2965 common kanji; 3807 glyphs, 613 KB) and `sans-kr.pgf` (Noto Sans CJK KR; the 2350 KS X 1001 hangul syllables plus compatibility jamo; 2729 glyphs, 392 KB). The total is 1.55 MB, compiled into `anypsp_host` through `cmake/embed-file.cmake`, so `anypsp-play` grew from 5.7 MB to 7.2 MB. Full JIS X 0208 would have made the Japanese font 1.15 MB, so level 2 kanji fall back to the alternate character.
- **Licence**: SIL OFL 1.1. The fonts are renamed "AnyPSP Sans" and "AnyPSP Serif" because Noto is a trademark and the CJK fonts reserve the name "Source". Sources are pinned by commit and SHA-256 in the script. The licence text is in `runtime/host/fonts/OFL.txt`, and `THIRD_PARTY.md` has a new section. The generator is reproducible: a second run gave byte-identical output.
- `font.cpp`: each registry entry names its fallback. `load()` uses the flash0 file when it parses, and otherwise the bundled one. It logs one line: `[font] N of 18 system fonts not usable in <dir>: using AnyPSP's bundled Noto replacements`. A corrupt bundled font throws.

## Tests

- `anypsp_hle_tests` has 3 new cases in `tests/unit/hle_tests.cpp`. They cover font list and count with an empty `flash0/font`; FindOptimumFont mapping to ltn0, ltn5, jpn0 and kr0; FontInfo size, resolution, family, bpp, ascender and descender; CharInfo metrics for 'A', 'g' and space; the alternate character, including after SetAltCharacterCode; 8-bit image bounds; the 4-bit format; `_Clip`; CJK coverage; and a flash0 PGF taking priority while an unreadable one falls back. `Hle::call` gained the optional t0-t2 arguments that `_Clip` needs. The tests fail on the old code, because the font count is 0.
- `ctest`: 6/6 passed (5 run, `corpus_analysis` skipped because the corpus has not been fetched on this box).
- input4 (`scratch-out/ctrl/input4.txt`, 6000 vblanks): `new4/h.txt` is identical to `old4/h.txt`, and `old4` is also identical to the earlier `unh1-fu/sas/h.txt`. That run never loads sceLibFont, so no hashes change.
- Profile run (`house/`, 4000 vblanks) against the pre-change `diag/`: hashes first differ at vblank 2999, when the profile screen first appears. A pixel diff of every 50th frame finds changes only inside (46..53, 69)-(76, 80), which is the NAME text "PSP". The two boxes come from the screen's slide-in.

## Docs

`docs/user/desktop.md` explains that copying the real `flash0:/font` PGFs into the game's `flash0/font` folder in the extracted-disc cache makes them win, and that the bundled Noto fallback is used otherwise. It also states the JP and KR coverage. `THIRD_PARTY.md` lists the fonts.

## Notes

- The upstream web build (`runtime/CMakeLists.txt`, untested, and it cannot configure without a generated corpus) lists `font.cpp` but not the embedded fonts, so it would fail to link if it were ever revived. I left it unchanged.
- The fallback has no shadow glyphs. `sceFontGetCharGlyphImage` shadows were not implemented before either.
- Metrics are derived from Noto, not from Sony's files. The em size, resolution and bpp match, but per-glyph advances differ from FTT-NewRodin, so text width differs slightly from a real PSP.

## Follow-up (coordinator decisions)

- The Japanese fallback now covers all of JIS X 0208, including level 2 kanji: 7197 glyphs and 1.15 MB (`sans-jp.pgf`). The bundled fonts total 2.08 MB. The generator is still reproducible (a rerun gives the same SHA-256). `THIRD_PARTY.md` and `docs/user/desktop.md` have the new numbers.
- Per-user font folder: `Kernel::set_user_font_dir`, set by `main_gpu.cpp` (all desktop and GPU runners) to `<per-user data folder>/flash0/font`. Lookup order for each font file is the game's `flash0/font`, then the per-user folder, then the bundled font. An unreadable file is logged and the next location is tried. This is documented in `docs/user/desktop.md`. The test "sceLibFont looks in flash0/font, then the per-user font folder, then uses the bundled font" covers both folders holding a file, a file only in the per-user folder, an unreadable file in the game folder, a font in neither, and a font that is unreadable and absent.
- Rebased onto main `b58bda7` (system dialogs). The only conflict was in `tests/unit/hle_tests.cpp`, where both branches had appended tests; I kept both. `ctest -E corpus_analysis`: 5/5 passed, including the new font tests. input4 (6000 vblanks): the hashes from the rebased branch are identical to a fresh build of `b58bda7`, and they also equal the `d28d6cf` run. The UNH 1 profile still shows "PSP" (`scratch-out/font/name-crop2.png`). I removed the temporary baseline worktree.

## Unresolved questions

None.

Status: DONE
Summary: sceLibFont falls back to bundled Noto PGF fonts (now with all JIS X 0208 kanji). Real fonts are read from the game's flash0/font first, then from the per-user flash0/font. The branch is rebased on main `b58bda7`, ctest passes, and input4 hashes are unchanged.
Concerns/Blockers: The bundled fonts add 2.08 MB to each runner binary.
