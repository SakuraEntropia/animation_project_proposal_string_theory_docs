# formalized_world

A **Formalized World Model** reconstructed from the *STRING THEORY* world setting.
The source document is treated as a non-formal specification; this project rebuilds it
as a generative model: axioms and definitions from which the world's physics,
technology, population, institutions and culture are *derived*, with every step
labelled and the mathematical core machine-verified.

## Build

```bash
lake build
```

Requires Lean `v4.33.1` (pinned in `lean-toolchain`) and Mathlib at
`leanprover-community/mathlib4` rev `v4.33.1`. The first build downloads ~7.5 GB of
Mathlib cache.

**Status: `Build completed successfully (8715 jobs)` — 61 theorems, all verified.**

## Layout

```
World/
├── Basic.lean         # ontology O1–O8: Time, Space, Energy, ProbDist, Observer
├── Entropy.lean       # S_W, Bregman divergence D, Gibbs' inequality, unique maximiser
├── Physics.lean       # gravity well, Tsiolkovsky bound, climb energy, flattening rate
├── FreeEnergy.lean    # Landauer, second law (non-decrease), attention budget bound
├── Dynamics.lean      # runaway ODE (no equilibrium), discrete geometric flattening
├── Civilization.lean  # technology as argmax, carrying capacity, institutions
├── Culture.lean       # norms as constrained optima; culture is emergent
└── TimeGeometry.lean  # the Time Wall: rate × budget ≤ 2 d² D_max
```

## The load-bearing theorems

| Theorem | Content |
|---|---|
| `flattening_max_entropy` | `S_W(p) ≤ log n`, equality **iff** `p` is uniform |
| `attention_budget_bound` | a conserved budget `A` supports at most `A/c` structures |
| `runaway_has_no_equilibrium` | the world cannot rest |
| `ritual_is_optimal_under_scarcity` | release dominates preservation past a finite `λ*` |
| `norm_is_emergent` | cultural norms are determined by constraints, not character |
| `geometric_budget_transfer` | accelerating one region is paid for by another |

## What Lean proves, and what it does not

Lean proves: *under the stated formal hypotheses, these propositions hold.*

Lean does **not** prove that the axioms describe our universe. `lake build` succeeding is
a statement about a derivation inside a formal system, not about reality. The full
consistency audit records 24 contradictions between the setting and settled physics —
see the worldbuilding documents in this repository.
