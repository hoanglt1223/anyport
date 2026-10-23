---
phase: 4
title: "AVM1 ahead-of-time compiler"
status: pending
effort: 3-4w
dependsOn: [2]
---

# Phase 04: AVM1 ahead-of-time compiler

## Context

AS1/AS2 compiles to AVM1, a stack bytecode in `DoAction`, `DoInitAction`, button and clip event actions, and `DefineFunction`/`DefineFunction2`. AVM1 can only evaluate variable paths from strings, never new code, so every script in a SWF can be compiled to C ahead of time.

## Requirements

- Translate every AVM1 action (SWF 4-8 set): stack ops, arithmetic with AVM1 coercion rules, string ops, `GetVariable`/`SetVariable` with path syntax, `GetMember`/`SetMember`, `CallFunction`/`CallMethod`, `NewObject`/`NewMethod`, `InitObject`/`InitArray`, `Enumerate2`, `With`, `Try`/`Throw`, `Jump`/`If`, `GotoFrame2`, `WaitForFrame`, `StoreRegister`, `ConstantPool`, `CastOp`, `InstanceOf`, `Extends`, `ImplementsOp`.
- Generated code operates on a tagged `swf_value` (undefined, null, bool, number, string, object) and a runtime API; stack slots become C locals where the stack depth is statically known.
- SWF-version-specific semantics (case-insensitive identifiers before SWF 7, `undefined` to string coercion) chosen at compile time.
- Constant pools and literal names interned at build time; property access by interned id.
- Each script becomes a C function; functions defined in scripts become C functions with closure scope objects.
- Ruffle's AVM1 implementation is the semantic reference.

## Files (create)

- `swf2c/src/avm1/decode.rs`, `avm1/stack_analysis.rs`, `avm1/emit_c.rs`, `avm1/strings.rs`
- `runtime/include/swfrt/value.h`, `runtime/src/avm1/value.c`, `avm1/object.c`, `avm1/coerce.c`, `avm1/scope.c`, `avm1/gc.c`
- `tests/avm1/*` (MTASC sources with expected trace output)

## Steps

1. Value model, objects, prototype chain, and a simple mark-sweep GC.
2. Emit C for expressions and control flow; `trace()` to stdout for tests.
3. Functions, closures, `with`, exceptions.
4. Path resolution (`_root`, `_parent`, `_level0`, slash and dot syntax) against the display list.
5. Run the Ruffle AVM1 test SWFs that do not need missing built-ins.

## Validation

- 100% of self-authored AVM1 tests and at least 80% of the selected Ruffle AVM1 tests produce identical `trace` output on PC and PSP.

## Risks

- Coercion edge cases differ by SWF version. Keep version-tagged test cases.
- GC pauses on PSP. Use incremental marking per frame if pauses exceed 2 ms.

## Rollback

Module-scoped; revert.
