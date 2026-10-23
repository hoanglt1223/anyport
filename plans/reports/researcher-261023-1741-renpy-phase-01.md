# Ren'Py to PSP, phase 01: prior art and feature census

Date: 2026-10-23. Plan: `plans/261023-1558-renpy-to-psp`. Phase status set to `blocked` (gate not met, a decision is needed).

## Gate result

- **Subset fully covers at least 10 of 15 games: FAIL (5 of 15).** Covered: the_question, wanted_dragon, chemistry_hero, arcance, zero_echoes. Adding static custom screens and the missing effects reaches 7 of 15. The other 8 games use Python functions and classes together with custom screens that run Python, which is the non-goal in `plan.md`. A supplementary set of 7 NaNoRenO jam games scores 1 of 7, so small jam games are not simpler.
- **At least three target games fully inside the subset: PASS.**

## Subset decision

The core is the phase 02 list plus additions the data shows are common and cheap. Full list: `repos/rpy2psp/tools/census/subset.json`. Rationale: `repos/rpy2psp/docs/dev/census.md`.

- Control flow: named menus, label parameters and call arguments, `call`/`jump expression`, local labels, `show expression`/`show text`, `say ... with`, temporary say attributes.
- Transitions: vpunch/hpunch, ease*, wipe*, push*, `Pause()`, `Move()` shakes, `define.move_transitions` names.
- Expressions: subscript assignment, named stores, `len str int min max abs round set list`, and common string and container methods.
- Ren'Py APIs with a direct engine equivalent: pause, input (PSP on-screen keyboard), random, notify, rollback and save calls, music and sound, and `movie_cutscene` as PSMF. Platform checks fold to PSP constants.
- Build-time image baking: `Image`, `im.*`, `Composite`, `Crop`, `Solid`, `Position` and static `Transform`, and the cookbook "auto-define images from a folder" loop.
- ATL: `on`, parameterised transforms, `parallel`/`block`/`choice`, crop, size, rotate, additive. Text tags: size, font, s, u, cps, vspace, space, and `a` as plain text.
- Ignored, because vnpsp replaces them natively: the template UI files (`gui.rpy`, `screens.rpy`, `options.rpy`), config and style settings, default screens, and custom screens never invoked from the story.
- Out of the subset, reported as build errors: user Python `def`/`class`/`for`/`import`, custom screens shown from the story, creator-defined statements, `python early`, transitions held in variables, ImageDissolve, CropMove, blinds/iris/zoom, layeredimage, ConditionSwitch, Movie sprites, matrixcolor, blur, custom text tags, ATL `function`.

## Target games

| # | Game | License | Ren'Py | Notes |
|---|---|---|---|---|
| 1 | the_question (renpy/renpy) | MIT | 8.5 | 71 lines. Translations include Japanese, Korean, and Chinese, which exercises CJK. |
| 2 | Zero Echoes (Trcmoe/Zero-Echoes) | CC-BY-4.0 | 8.3.3 | Chinese text, `renpy.input` password entry. |
| 3 | Arcance (nsobczak/Arcance) | Apache-2.0 | 6.99 | 307 lines; `im.*` side images baked at build time. |
| Alt | Wanted: Dragon (qirien/wanted-dragon) | CC BY-NC-SA 4.0 | 6.18 | 2,765 lines, NVL, Spanish. Stretch target, but the license is non-commercial. |

## Prior art

Nothing reusable as an engine. Leave-Us-Alone/RenPy-PSP (Lua, no license, 2022) and AG_VN_ENGINE_Portable (Stackless Python on PSP, no license) are interpreters. VNPSP (VNDS, 2014) is dead. onscripter-psp (GPL-2) uses a different script model. For phase 02 readers, use unrpyc (MIT) and rpatool (WTFPL) as references. Details: `repos/rpy2psp/docs/dev/prior-art.md`.

## Recommendation (ranked)

1. Keep the ahead-of-time design and the core subset. Narrow the plan's claim to dialogue-driven VNs, and change the gate to "three target games fully covered; corpus coverage measured". This needs user approval because it changes the plan's acceptance criteria.
2. Optionally add static custom screens and mask transitions later (7 of 15).
3. Do not embed a Python runtime on the PSP. That is the scope of a full Ren'Py port and conflicts with the workspace's rule against interpreter-first ports.

## Deliverables

- `repos/rpy2psp/tools/census/` contains the lexer, analyzer, CLI, fetch script, manifest (22 games at pinned commits), subset, unit tests, and README with the parser's limits. It parses only and never executes game code.
- `repos/rpy2psp/docs/dev/prior-art.md` and `docs/dev/census.md`.
- `repos/rpy2psp/LICENSE` (MIT, Henry Nguyen) and `.gitignore` (game scripts and archives are ignored except under `tests/`).
- The corpus is in `%TEMP%\rpy2psp-census\games` (sparse `.rpy` clones), outside the repo. Nothing was committed.

## Unresolved questions

1. Do you accept narrowing the gate and acceptance criteria (option 1), or should phase 02 add static screens and effects first?
2. Is a non-commercial license (Wanted: Dragon) acceptable for a stretch target?
3. Should the census be re-run on itch.io free VNs that ship `.rpy`? Their downloads need a browser flow, and their licenses are usually unstated.
