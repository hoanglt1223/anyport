# N64 decomp to PSP: prior art, route comparison, game choice (phase 01, research part)

Date: 2026-10-23. Scope: the parts of `plans/261023-1548-n64-decomp-psp-port/phase-01-survey-and-route-spike.md` that need no ROM. Real-build measurements and the spike need the user's ROM, so this report only lists them.

## Bottom line

- **Most of the plan's candidates are already on the PSP, or being ported now.**
  - SM64, MK64 and OoT have released native PSP ports.
  - Majora's Mask and Star Fox 64 are active works in progress.
- **Paper Mario is the only N64 candidate left with no PSP port.**
- **Every working N64-on-PSP port uses route B**: original decomp C, plus a slim C Fast3D (descended from sm64-port), plus sceGu or PSPGL. None uses libultraship.
- **Recommendation: Paper Mario via route B.** Take the MIT-licensed parts of MK64 Portable's port layer as the starting point.
- **Ranked alternative: contribute to sf64-psp** (CC0, explicitly asks for contributors, sceGu renderer still to do).

The plan's overview says "No search found an existing PSP port of SF64, MK64 or OoT", and its route A premise is that "one backend unlocks SF64, MK64, OoT". Both are now false. `plan.md` should be revised. This report does not edit it.

## Prior art (searched 2026-10-23)

| Game | PSP port | State | License of port code | Verdict |
|---|---|---|---|---|
| Super Mario 64 | [z2442/sm64-port](https://github.com/z2442/sm64-port) (`make TARGET_PSP=1`). Fast3D sceGu backend by Hayden Kowalchuk (mrneo240), 2020. Forks such as [blckbearx/sm64-port-psp](https://github.com/blckbearx/sm64-port-psp). | Mature; still updated in 2026-08 | None stated (sm64-port publishes no license). The texture manager is BSD-3. | Drop |
| Mario Kart 64 | [beckerd/psp_mk64_portable](https://github.com/beckerd/psp_mk64_portable) | v1.7, 2026-09-29. 60 fps in 1P on every model, including the PSP-1000 (32 MB). Media Engine audio, ad hoc multiplayer, ROM-to-cache extraction on first boot (about 13 MB). | MIT for its own port layer (`ultra_shim.c`, `segments.c`, `src/port/psp/*` except `gfx_scegu.c`, `tools/psp`). `gfx_pc.c` and `gfx_scegu.c` are used "on the same basis as" sm64-port, which has no license. | Drop. Reuse as a base (see below). |
| Ocarina of Time | [z2442/oot-PSP](https://github.com/z2442/oot-PSP) | 1.0 released 2026-08-30 (4.5k downloads). "Full speed", NTSC 1.0. Open issues: transparency, some textures, 16:9. Also [SloppyHenry/SlopcarinaOfTime](https://github.com/SloppyHenry/SlopcarinaOfTime) (GPL-3.0, PAL 1.0, WIP). | None stated | Drop |
| Majora's Mask | [z2442/mm-PSP](https://github.com/z2442/mm-PSP) | WIP with no release; commits to 2026-09-10. Backend derived from oot-PSP, 8 MiB game arena, `MEMSIZE=1`, so PSP-2000 or later only. | None stated | Drop (taken) |
| Star Fox 64 | [TheMrIron2/sf64-psp](https://github.com/TheMrIron2/sf64-psp) by Daniel Welch | Active WIP (commit 2026-10-17). PSPGL renderer, with sceGu next. 30 Hz simulation shown at 60 fps with interpolation. Media Engine audio. Uses the [n64psp](https://github.com/TheMrIron2/n64psp) library. | CC0 (fork of sonicdcer/sf64). n64psp is GPL-3.0. | Contribute (rank 2) |
| Paper Mario | **None found** (GitHub, web). PC ports: [HarbourMasters/PaperBoat](https://github.com/HarbourMasters/PaperBoat), released 2026-09-22. Vita: [kaziema/pmvita](https://github.com/kaziema/pmvita), PaperShip on libultraship, 30 fps on Vita. | Decomp [pmret/papermario](https://github.com/pmret/papermario) is 100% for US | n/a | **Go (rank 1)** |
| pokeemerald / pokefirered | None found | These are GBA decomps, not N64; Fast3D does not apply. gpSP already runs GBA on PSP (`gpsp_libretro_psp` on the libretro buildbot), and AnyGBA covers GBA. | n/a | Skip (out of scope) |

The same authors also have a Perfect Dark PSP fork (`z2442/perfect_dark-PSP`) and `z2442/pikmin-psp`. The PSP N64 porting scene is active and coordinates on the PSP Homebrew Community Discord.

## Route A vs route B for 52 MB RAM and 2 MB VRAM

| Dimension | Route A: libultraship plus a GE backend | Route B: decomp plus slim C Fast3D plus libultra shim |
|---|---|---|
| Evidence on PSP | None. The only small-device data point is pmvita on the Vita, which has 512 MB. | Five ports: SM64 (2020), MK64 (60 fps on the 32 MB PSP-1000), OoT 1.0, MM WIP, SF64 WIP. Off-PSP: SM64 on DSi (16 MB) and MK64/SF64 on Dreamcast (16 MB) use the same pattern. |
| Code size | C++20. `src/fast/interpreter.cpp` alone is 215 KB. ImGui (`Fast3dGui.cpp`), the prism shader preprocessor, thread-pool, Monocypher, libgfxd, a resource manager, and `.o2r` archives (optional StormLib MPQ). | C. sm64-port `gfx_pc.c` is 59 KB; MK64 Portable's grew to 176 KB with PSP work. The sceGu backend is 43 KB. |
| Renderer fit | Every backend is shader-based: OpenGL, D3D11, Metal. Combiners are compiled to shaders, so a GE backend needs a fixed-function mapping that the backend API does not model. | Backends already map the combiner to `sceGuTexFunc` and multi-pass on GE (MK64, OoT, MM docs). |
| Pointer and endianness | PC ports are 64-bit, so game code and assets were reworked for 64-bit pointers and resource paths (`__OTR__` lookups). | N64 and PSP pointers are both 32-bit. Only endianness differs (N64 big-endian, PSP little-endian), and the existing extractors already handle it. |
| Memory | No public figure found for any libultraship title. The resource cache and archives are designed for desktop RAM. | MK64 fits in the 24 MB user partition of a PSP-1000. MM uses an 8 MiB game arena. |
| What route A was meant to buy | One backend for SF64, MK64 and OoT. All three are already ported natively, so this is now moot. | Ports one game at a time. Shared layers already exist (n64psp, MK64 port layer). |

**Route B wins on every dimension that matters here.** The plan's route A also needs ImGui and threads on a 333 MHz single-core CPU, with no evidence it fits. Drop it rather than spike it.

### VRAM budget (2 MB)

| Layout | Front + back (stride 512) | Depth (16-bit) | Left for textures |
|---|---|---|---|
| 16-bit colour | 2 x 278,528 B | 278,528 B | about 1.2 MB |
| 32-bit colour | 2 x 557,056 B | 278,528 B | about 0.6 MB |

The GE can also texture from main RAM (slower). The existing ports use a texture manager that keeps hot textures in VRAM (`psp_texture_manager.c`, BSD-3). Paper Mario's sprites are mostly CI4 and CI8, and the GE samples CLUT textures natively, which is a good fit.

## Recommendation

1. **Paper Mario (US), route B (rank 1).**
   - Fork pmret/papermario.
   - Port the MIT parts of MK64 Portable:
     - `ultra_shim.c` (single-threaded libultra)
     - `segments.c` (segmented addressing)
     - first-boot asset generation from the user's ROM (`assets_gen.c`, recipe tooling)
     - the Media Engine mixer glue
     - `psp_main.c`
   - Keep the BSD-3 texture manager with its notice.
   - `gfx_pc.c`, `gfx_cc.c` and `gfx_scegu.c` have no license (inherited from sm64-port). Either use them on the same basis as every other port does, or write a clean F3DEX2 interpreter. This is the user's call.
   - Do not take n64psp (GPL-3.0) unless the user accepts GPL-3.0 for the fork.
   - Why Paper Mario:
     - It is the only open slot left.
     - The decomp is 100% complete.
     - We believe it runs in the base 4 MB of N64 RAM (no Expansion Pak); the spike should confirm this.
     - It runs at 30 fps on N64.
     - Its 2D sprite-heavy rendering is light on the GE.
2. **Contribute to sf64-psp (rank 2).**
   - Lowest effort and community benefit. The sceGu renderer is on their roadmap.
   - It fits a contribute decision better than our own fork.
   - It does not meet the plan's "one repo per game" outcome. Choose it if the user wants least work over a new port.
3. **Do not start SM64, MK64, OoT or MM.**

### Paper Mario risks

- **Framebuffer effects.** `gDPSetColorImage` (render to a non-screen buffer) appears in at least 15 source files:
  - `background_gfx.c`, `screen_render_util.c`, `curtains.c`, `sprite_shading.c`, `model.c`, `hud_element.c`, `windows.c`
  - several `effects/` and `world/` files
  
  The GE can render into a VRAM texture, but the VRAM budget above is tight. This is the main technical risk. Map each use early.
- **Combiner and sprite shading.** `sprite_shading.c` does per-sprite lighting. Check how it maps onto GE texture functions.
- **Licensing.** The decomp has no license (Nintendo code), like every port listed. Same legal model as the plan.

## Measurements to run later (need the user's ROM)

Run these on a PC route B build compiled with `-m32`, so pointers are 32-bit like the PSP. Unless noted, use the decomp and a PC Fast3D (sm64-port style). Then repeat the starred items on PPSSPP and the PSP-3000.

1. **Peak heap and resident set.** Use `/usr/bin/time -v` (max RSS) and `heaptrack` or `valgrind --tool=massif` over a scripted path: boot, then Goomba Village, Toad Town, a battle, Shy Guy's Toy Box, and Flower Fields. Gate: under 45 MB.*
2. **Asset footprint.** Measure the total size of extracted assets and the largest single area plus battle set resident at once.
3. **Triangles per frame.** Add a counter to the F3DEX2 triangle commands in `gfx_pc.c` and record the maximum and 95th percentile per area. Also count vertices and display-list commands per frame.*
4. **Texture memory per frame.** Record unique texture bytes referenced per frame, cache-miss upload bytes per frame, and peak live texture cache, converted to PSP formats (CI4, CI8, 5551, 8888).*
5. **Framebuffer effects.** Count `gDPSetColorImage` targets, their sizes, and which areas and menus use them.
6. **On PSP (spike).** Record free memory after boot and after each area load (`sceKernelTotalFreeMemSize`, `sceKernelMaxFreeMemSize`). Split frame time into game logic, display-list interpretation and GE wait.
7. **Baseline.** Note PaperBoat's RSS on the same path for comparison only. It is 64-bit, so expect it to overstate memory.

## Adoption risk of reused code

- MK64 Portable has one author, started 2026-08, and is MIT. The code is AI-assisted (README). It is active and released. Medium risk; we would vendor the code, not depend on it.
- sf64-psp and n64psp have several contributors and are active. n64psp is GPL-3.0.
- The z2442 ports have no license, so use them as reference only and do not copy code.

## Limitations

- No measurements were taken (no ROM). The Paper Mario fit is inferred from comparable ports, not measured.
- No public memory figures exist for libultraship titles. Route A was rejected on evidence and fit, not on a measured heap.
- Paper Mario's Expansion Pak status and microcode (the repo has F3DEX2 and S2DEX headers) were checked only through code search, not by reading the full source.
- Discord-only work (the PSP Homebrew Community) was not searched. Someone may already be on Paper Mario PSP. **Ask there before forking.**

## Unresolved questions

1. Paper Mario (new port) or contributing to sf64-psp?
2. Is reusing the unlicensed sm64-port lineage (`gfx_pc.c`, `gfx_scegu.c`) acceptable, or do we need a clean-room F3DEX2 interpreter?
3. Is a GPL-3.0 fork acceptable if we adopt n64psp?
4. Should `plan.md` be rewritten now (prior-art table, drop route A, swap the `n64-psp-shim` extraction for an n64psp evaluation)?

## Sources

- [beckerd/psp_mk64_portable](https://github.com/beckerd/psp_mk64_portable) (README, LICENSE, `docs/fps60.md`)
- [z2442/oot-PSP](https://github.com/z2442/oot-PSP), [z2442/mm-PSP `docs/psp-port.md`](https://github.com/z2442/mm-PSP/blob/main/docs/psp-port.md), [z2442/sm64-port](https://github.com/z2442/sm64-port)
- [TheMrIron2/sf64-psp](https://github.com/TheMrIron2/sf64-psp), [TheMrIron2/n64psp](https://github.com/TheMrIron2/n64psp), [Generation Amiga on SF64 PSP](https://www.generationamiga.com/2026/07/28/star-fox-64-psp-port-shows-impressive-progress/), [Retro Dodo on SF64 PSP](https://retrododo.com/star-fox-64-is-now-running-on-psp-at-60fps/)
- [SloppyHenry/SlopcarinaOfTime](https://github.com/SloppyHenry/SlopcarinaOfTime)
- [pmret/papermario](https://github.com/pmret/papermario), [HarbourMasters/PaperBoat](https://github.com/HarbourMasters/PaperBoat), [Steam Deck HQ on PaperBoat](https://steamdeckhq.com/news/harbour-masters-next-n64-pc-port-is-paper-mario/), [GameBrew: Paper Mario Vita](https://www.gamebrew.org/wiki/Paper_Mario_Vita)
- [Kenix3/libultraship](https://github.com/Kenix3/libultraship) (`src/fast`, `cmake/dependencies/common.cmake`), [sm64-port/sm64-port `src/pc/gfx`](https://github.com/sm64-port/sm64-port)
- [Recalbox on jnmartin84 Dreamcast ports](https://www.recalbox.com/blog/2025-10-30-star-fox-64-nintendo-sega-dreamcast-homebrew-retrogaming/), [Dreamcast Junkyard N64 ports](https://www.thedreamcastjunkyard.co.uk/search/label/Nintendo%2064%20Port)
- [libretro PSP nightly cores](https://buildbot.libretro.com/nightly/playstation/psp/latest/)
