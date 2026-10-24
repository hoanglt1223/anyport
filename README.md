# anyport

Workspace for native-port projects inspired by [AnyPS5](https://github.com/boykopovar/AnyPS5): real ports through relinking, static recompilation, or ahead-of-time compilation plus HLE, never a virtual machine.

## Layout

- `plans/`: one folder per project plan (`plan.md` and phase files), plus `journals/`.
- Project repositories are separate GitHub repos, linked in the table below.
- `refs/` (local only, not in git): shallow clones of upstream projects for reference.

## Projects (suggested order)

| # | Project | Repo | Plan |
|---|---|---|---|
| 1 | PSP Companion: Claude voice assistant, widget screen, Stream Deck mode, PC speaker | [psp-companion](https://github.com/hoanglt1223/psp-companion) | [plan](plans/261023-1558-psp-companion/plan.md) |
| 2 | AnySWF: Flash AS1/AS2 → PSP (and PC/Android) | [anyswf](https://github.com/hoanglt1223/anyswf) | [plan](plans/261023-1548-anyswf-flash-to-psp/plan.md) |
| 3 | PSP engine runners: TIC-80, PICO-8, LÖVE (GM8 cancelled) | local forks `repos/tic80-psp`, `repos/fake08-psp`, `repos/lovepotion-psp` (branch `psp`, not on GitHub yet) | [plan](plans/261023-1558-psp-engine-runners/plan.md) |
| 4 | Ren'Py → PSP | [rpy2psp](https://github.com/hoanglt1223/rpy2psp) | [plan](plans/261023-1558-renpy-to-psp/plan.md) |
| 5 | AnyGBA: GBA static recompiler | [anygba](https://github.com/hoanglt1223/anygba) | [plan](plans/261023-1514-anygba-static-recompiler/plan.md) |
| 6 | N64 decomp → PSP | fork, chosen in phase 01 | [plan](plans/261023-1548-n64-decomp-psp-port/plan.md) |
| 7 | AnyPSP: PSP static recompiler (evaluate PSPRecomp first) | [anypsp](https://github.com/hoanglt1223/anypsp) | [plan](plans/261023-1558-anypsp-static-recompiler/plan.md) |
| 8 | AnySwitch: Switch → native ARM64 relinker | private for now | private for now |

Projects 2-4 share one PSP platform layer (built in AnySWF phase 01).

## Constraints that apply everywhere

- Ship tools only. No ROMs, firmware, keys, or game assets in any repo.
- PSP-3000 Wi-Fi is 802.11b (~1-2 Mbps): no video over Wi-Fi, push-on-change only, under 300 kbps total.

## References in `refs/`

AnyPS5, N64Recomp, psprecomp, PPSSPP, Ruffle, Moonlight-PSP, moonlight-common-c, companion-satellite, LövePotion, fake-08, TIC-80, OpenGMK, libnx, pspsdk, gba-tests.
