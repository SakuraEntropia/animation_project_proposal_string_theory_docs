# formalized_world — Lean 4 + Mathlib

The machine-verified mathematical core of the *STRING THEORY* Formalized World Model.

**61 theorems · 8 modules · 1767 lines · `lake build` → SUCCESS (8715 jobs)**

See `formalized_world/README.md` for the module map and the five load-bearing theorems.

## Build

```bash
cd formalized_world
lake build
```

Requires Lean `v4.33.1` (pinned in `lean-toolchain`) and Mathlib
`leanprover-community/mathlib4` rev `v4.33.1`. The first build downloads ~7.5 GB of
Mathlib cache.
