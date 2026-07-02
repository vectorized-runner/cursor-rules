---
name: gc-allocation-audit
description: Audit a Unity codebase or hot path for GC allocations and fix them. Use when asked to find allocation sources, reduce GC pressure, fix GC spikes/hitches, or make a system allocation-free.
---

# GC Allocation Audit

Procedure for finding and eliminating managed allocations in a Unity (WebGL) project's hot paths.

## Step 1 — Identify the hot paths

Hot paths are code that runs per frame or per network message:

- `Update`, `FixedUpdate`, `LateUpdate`, `OnGUI`
- Coroutine loop bodies that run every frame
- Per-message/server-event handlers
- Anything called from the above (walk one level of callees)

If the user named a system, start there; otherwise grep for `void Update()` and per-frame coroutines and rank by how many instances of the component exist at runtime.

## Step 2 — Scan for the common culprits

Search each hot path for these, in rough order of frequency:

| Culprit | Detect | Fix |
|---------|--------|-----|
| String building | `$"`, `string.Format`, `+` on strings, `.ToString()` per frame | Rebuild only on value change; cache formatted strings |
| LINQ | `using System.Linq`, `.Where(`, `.Select(`, `.Any(`, `.ToList(` | `for` loops with reused buffers |
| Capturing lambdas | `=>` referencing locals/`this` inside hot methods | Cache delegate in `static readonly` field; register callbacks once |
| New collections | `new List<`, `new Dictionary<`, `new []`, `ToArray()` | Allocate once, `Clear()` per use, pre-size |
| Boxing | struct/enum passed as `object`/interface; enum dictionary keys; `foreach` over `IEnumerable<T>`-typed refs | Generic constraints, `int` keys, concrete-typed loops |
| Alloc physics | `RaycastAll`, `OverlapSphere` (non-buffer overloads) | `*NonAlloc` / buffer overloads with reused arrays |
| Coroutine yields | `new WaitForSeconds(` inside loops | Cached `static readonly WaitForSeconds` |
| Unity API allocs | `GetComponents(` (array), `mesh.vertices` (copies array), `Input.touches`, `tag ==` | Cached buffers, `List<>` overloads (`GetComponents(list)`), `CompareTag` |
| Logging | `Debug.Log` in per-frame code | Delete or gate behind `[Conditional]` |
| `params` methods | calls to `params` APIs per frame | Explicit-arity overloads |

## Step 3 — Verify with the Profiler (when Unity is available)

1. Profiler → CPU module → enable **GC Alloc** column, sort descending.
2. Play the specific scenario (combat, scrolling list, etc.); look at a steady-state frame, not a loading frame.
3. Target: **0 B/frame** in steady-state gameplay. Anything recurring > 0 B gets a fix or a written justification.
4. For deep call stacks, use Deep Profile briefly or add `ProfilerMarker` around suspects.

## Step 4 — Fix and report

- Apply fixes per the table, following the repo's allocation-discipline and update-loop-hygiene rules.
- Report per finding: file/line, allocation source, bytes/frame if measured, fix applied.
- Flag any allocation intentionally kept (rare event paths) with a one-line justification.
