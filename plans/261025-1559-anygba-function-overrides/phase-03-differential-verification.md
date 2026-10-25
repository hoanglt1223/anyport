---
phase: 3
title: "Differential verification harness"
status: pending
effort: 1-1.5w
dependsOn: [2]
---

# Phase 03: Differential verification harness

## Context

An override is trusted only when it behaves like the recompiled function it replaces. AnyPSP's
`cpu_difftest` (generated code vs reference interpreter on random states) is the model.

## Requirements

1. `anygba difftest <game> --func <name>`: runs original and override from the same starting state
   and compares registers (r0-r3, r12, sp, lr path), every guest memory write (address, size, value,
   order where it matters), IO register writes, and guest calls made (target, arguments).
2. State sources: random states shaped by a per-function argument spec (pointer ranges, string
   buffers), and recorded real states captured at the function's entry during scripted headless play
   from save states (`--record-entry <func> --count N`).
3. Coverage: report basic-block coverage of the original over the test set so gaps are visible.
4. Output: pass/fail, first diverging state minimised to a readable diff, JSON for tools (phase 04).
5. Overrides marked `verified` in config only after a passing run; unverified ones warn at startup.

## Files

- New `runtime/src/overrides/difftest.*`, CLI wiring in the `anygba` tool, tests under `tests/`

## Steps

1. Memory-write journaling hook for both executions (copy-on-write snapshot of the start state).
2. Random and recorded state providers; argument spec format.
3. Diff minimiser and JSON report; coverage from recompiled block counters.

## Validation

- A deliberately wrong override (off-by-one in a loop) is caught with a minimal diff.
- The phase 02 test override passes ≥10,000 states with ≥90% block coverage on the corpus ROM.

## Risks and rollback

- Functions with timing/IO side effects (DMA, waits) may need per-function compare masks; keep them
  explicit and listed in the report.
