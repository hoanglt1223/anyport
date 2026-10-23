# AnyPSP phase 01: prior art and base decision

**Recommendation: fork.** AnyPSP becomes a new GPL-2.0-or-later repo built from two MIT sources. The first is the jessicanataliagta/PSPRecomp framework at `f6e7d41` with snuri00/psp-web-recomp's 10 patches applied (framework only, never `profiles/`). The second is psp-web-recomp's generic `profile/host`, which seeds the HLE runtime. Generic fixes go back upstream as MIT PRs. sp00nznet/psprecomp, sal063's ACX recomp and PPSSPP serve as references and code sources.

Full write-ups:
- `D:\Projects\personal\anyport\repos\anypsp\docs\dev\prior-art.md`
- `D:\Projects\personal\anyport\repos\anypsp\docs\dev\decision-base.md`

## Key findings

- **The plan conflates three different "PSPRecomp" frameworks.** The GTA LCS/VCS ports are built on jessicanataliagta/PSPRecomp (C++20, MIT). PSP2i is built on sp00nznet/psprecomp (C11, MIT), which `refs/psprecomp` (zmbkilla) forks. The "Rust analyser, C++17, SDL2 + OpenGL 3.3" project is wizardengineer/psprecomp (GPL-2.0, Patapon). Ace Combat X uses sal063's own GPL-2.0 codebase. `plan.md`'s overview should be corrected; I did not edit it because that was out of scope.
- **The codegen with the best track record also has the weakest upstream.** PSPRecomp runs VCS, LCS and both God of War games at playable speed. Its upstream has been inactive since 2026-08-28, with one PR merged and eight open, and it puts HLE and the renderer in per-game profiles.
- **psp-web-recomp is the generic proof.** It is MIT, has about 14.5k lines of HLE/GE host with no game code, and turns any ISO into a build with one script. Its patches add runtime PRX translation and an interpreter fallback. All 10 patches apply cleanly to PSPRecomp HEAD.
- **sp00nznet/psprecomp is the healthiest upstream but the least proven.** It has 186 commits and 18 merged outside PRs, and the best docs and bring-up instruments. It has only reached a title screen, renders in software, and its policy forbids PPSSPP code.
- **License: GPL-2.0-or-later.** That lets us adapt PPSSPP's VFPU, ATRAC, MPEG, PGF and GE code. MIT and LGPL-2.1+ sources fold in with their notices kept. Avoid GPL-3.0 sources (gow-psp-recomp, the highcmd ports). Never commit generated output; the LCS and VCS repos commit 96 MB and 2.3M lines of it.

## Build evidence (copies under %TEMP%, no game data)

The inputs were open-source pspautotests PRX files.

- **zmbkilla/psprecomp:** builds with CMake + MSVC 14.44 and passes 14/14 ctest. `info`, `cover`, `funcs` and `emit` work on all four PRX files. The emitted C compiles and links against the runtime once two host hooks are stubbed.
- **PSPRecomp, plain and patched:** builds and passes 1/1 tests. `psp_analyze` and `psp_recomp --auto` work on homebrew.
- **wizardengineer:** `cargo build` succeeds. 304 tests pass and 1 fails only because no `c++` is on PATH. `analyze` was not run because it needs Ghidra 12.0.2 + JDK 21.
- **Not done:** running recompiled homebrew. No framework ships a generic Windows host, and Docker/WSL are absent. This becomes phase 02's first task.

## Phase status

I set `status: in-progress` rather than completed. The gate needs "agreement on scope with upstream where possible", and contacting maintainers needs the user's approval. Draft messages are in `decision-base.md`.

## Sources

- [jessicanataliagta/PSPRecomp](https://github.com/jessicanataliagta/PSPRecomp)
- [snuri00/psp-web-recomp](https://github.com/snuri00/psp-web-recomp)
- [sp00nznet/psprecomp](https://github.com/sp00nznet/psprecomp)
- [zmbkilla/psprecomp](https://github.com/zmbkilla/psprecomp)
- [zmbkilla/PSP2I_Recomp](https://github.com/zmbkilla/PSP2I_Recomp)
- [wizardengineer/psprecomp](https://github.com/wizardengineer/psprecomp)
- [sal063/Ace-Combat-X-Recompilation](https://github.com/sal063/Ace-Combat-X-Recompilation)
- [sal063/PSP-recompilation-project](https://github.com/sal063/PSP-recompilation-project)
- [elmasas/lcs-recomp](https://github.com/elmasas/lcs-recomp)
- [OverkillLabs3/vice-city-stories-recomp](https://github.com/OverkillLabs3/vice-city-stories-recomp)
- [codepdbh/PSPRecomp-VCS-Android](https://github.com/codepdbh/PSPRecomp-VCS-Android)
- [DrummingBird1/gow-psp-recomp](https://github.com/DrummingBird1/gow-psp-recomp)
- [hrydgard/pspautotests](https://github.com/hrydgard/pspautotests)
- [uofw/uofw](https://github.com/uofw/uofw)
- [ixbt.games on the LCS port](https://ixbt.games/en/news/2026/09/25/spustia-21-god-na-pk-perenesli-gta-liberty-city-stories-poiavilsia-fanatskii-port-igry.html)

## Unresolved questions

1. Does the user approve contacting snuri00 and jessicanataliagta with the drafted messages? Forking or publishing is public, so this needs approval.
2. Should `plan.md`'s overview be corrected to name the right frameworks?
3. Is GPL-2.0-or-later acceptable, given that it closes the door to upstreaming PPSSPP-derived work into the MIT projects?
4. Is it acceptable to set up Docker (pspdev) or WSL so homebrew can be built and run end to end in phase 02?
