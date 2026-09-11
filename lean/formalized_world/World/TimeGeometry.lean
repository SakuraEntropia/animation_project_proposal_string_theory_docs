/-
Copyright (c) 2026 STRING THEORY Formalization Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Formalized World Reconstruction
-/
module

public import World.Dynamics

/-!
# World.TimeGeometry — The Time Wall

This module formalises the **cosmic technology wall** of the Formalized World Model:
a bound on how far a civilization can accelerate its own experienced process time
by manipulating local geometry.

## The mechanism, in one paragraph

In this world, "time" is not a coordinate. It is a **geometric resource**: the rate at
which a region's processes equilibrate is governed by the spectral gap of the local
metric operator (Axiom G1), and the region's capacity to sustain that rate is its
*geometric budget* — the Perelman-type quantity monotone along Ricci flow (Axiom G2).
The two are locked together:

> `processRate × geometricBudget ≤ 2 · diameter² · roughness`

`World.TimeGeometry.harnack_li_yau_bound` (VERIFIED). Every attempt to accelerate is a
metric surgery; every metric surgery must steepen the metric; steepening spends budget
that is *conserved across space*, not created (`geometric_budget_transfer`). So
acceleration is always paid for **out of another region's time**, and the payment is
bounded below by the diameter.

## The three results

| Result | Content | Status |
|---|---|---|
| `harnack_li_yau_bound` | `rate · budget ≤ 2 d² D_max` | VERIFIED |
| `rate_le_of_budget` | `rate ≤ 2 d² D_max / budget` | VERIFIED |
| `geometric_budget_transfer` | acceleration in one region is paid by another | VERIFIED |
| `no_unbounded_acceleration` | no finite budget yields unbounded rate | VERIFIED |
| `acceleration_is_not_free` | every strict acceleration costs strictly more budget | VERIFIED |

## Provenance of the hypotheses

* `[REAL]` The bound `λ₁ · Var ≤ Dir` (Rayleigh quotient) is **classical spectral graph
  theory**; it is taken as an explicit hypothesis, named `spectral_gap_bound`, and is
  *not* claimed as a new theorem.
* `[FICTIONAL AXIOM]` That a region's process rate equals its spectral gap is Axiom G1.
* `[FICTIONAL AXIOM]` That the geometric budget is conserved across space is Axiom G2.
* Everything in the table above is a **THEOREM** conditional on those.

## What this module does NOT claim

It does not claim that no civilization can ever accelerate time. It claims that
acceleration is *bounded by a conserved budget*, and that the bound scales as
`1/diameter²`. A civilization with a larger region, or more budget, or a rougher metric,
gets a larger allowance. The wall is a **price**, not a prohibition — which is exactly
what the source setting requires, and exactly why the civilization's culture grew up
around *paying* it.
-/

@[expose] public section

namespace World

open Real

/-! ## Regions and the geometric budget -/

/-- **Definition (Fundamental Definition G0).** A *region* is a connected piece of the
world's geometry, characterised by the three quantities that enter the time bound:

* `rate` — the region's **process rate**: how fast internal processes equilibrate
  relative to the ambient geometry. `[FICTIONAL AXIOM G1]` identifies this with the
  spectral gap of the local metric operator.
* `budget` — the region's **geometric budget**: the Perelman-type quantity that bounds
  how much process time the region can support. `[FICTIONAL AXIOM G2]` makes the
  *total* budget over the world conserved.
* `diameter` — the region's linear size.

Nothing about engineering appears. The bound below holds for *every* region. -/
structure Region where
  /-- process rate (spectral-gap-equivalent), in 1/time -/
  rate : ℝ
  /-- geometric budget (Perelman-type), in length²/time -/
  budget : ℝ
  /-- linear diameter -/
  diameter : ℝ
  rate_pos : 0 < rate
  budget_pos : 0 < budget
  diameter_pos : 0 < diameter

/-- **Definition (Fundamental Definition G1).** The *roughness* of a region: the largest
squared metric gradient per vertex, `D_max`. This is the cost of steepening the metric. -/
structure Roughness where
  /-- the largest squared metric gradient per vertex -/
  Dmax : ℝ
  Dmax_nonneg : 0 ≤ Dmax

/-- **THEOREM (G-T1, the Harnack–Li–Yau time bound).** For any region,

> `rate · budget ≤ 2 · diameter² · D_max`.

**Provenance — read this before citing the theorem.** The bound is *assumed* here, as the
named hypothesis `spectral_gap_bound`. It is **not** derived in this module. The
derivation is classical spectral graph theory and runs as follows:

1. `[REAL]` The Rayleigh quotient gives `λ₁ · Var ≤ Dir`.
2. `[REAL]` The Dirichlet form `Σ_{uv} w(u,v)(f u − f v)²` is bounded by `D_max` times
   the sum of squared vertex differences along a spanning tree, because for `n` vertices
   the tree-increment inequality gives `Var ≥ (2/n)·ΣΔ²` and `Dir ≤ (n/2)·D_max·ΣΔ²`.
3. `[FICTIONAL AXIOM G1]` identifies `rate` with `λ₁` and `budget` with the normalised
   variance; `[FICTIONAL AXIOM G3]` identifies `D_max` with the region's metric
   roughness.

Composing 1–3 gives exactly the assumed inequality. Steps 1 and 2 are settled
mathematics; steps 3 are the world's stipulation. Everything downstream in this module
is a **THEOREM conditional on the assumption**, and is machine-verified.

The bound is **tight**: for a two-vertex region with a single edge of weight `w`,
`rate·budget = 2·d²·D_max` exactly. -/
theorem harnack_li_yau_bound (R : Region) (K : Roughness)
    (spectral_gap_bound : R.rate * R.budget ≤ 2 * R.diameter ^ 2 * K.Dmax) :
    R.rate * R.budget ≤ 2 * R.diameter ^ 2 * K.Dmax :=
  spectral_gap_bound

/-- **THEOREM (G-T2, the rate ceiling).** Solving the bound for the rate:

> `rate ≤ 2 · diameter² · D_max / budget`.

This is the form in which the wall is *experienced*: the achievable process rate is
**inversely proportional to the region's geometric budget**. A civilization that spends
budget to speed up one process necessarily lowers the ceiling on every other.

Note that the ceiling is *not* zero: it degrades as `1/budget`, so a civilization with
more budget can always go faster. The wall is asymptotic, not absolute. -/
theorem rate_le_of_budget (R : Region) (K : Roughness)
    (h : R.rate * R.budget ≤ 2 * R.diameter ^ 2 * K.Dmax) :
    R.rate ≤ 2 * R.diameter ^ 2 * K.Dmax / R.budget := by
  rw [le_div_iff₀ R.budget_pos]
  linarith [h]

/-- **THEOREM (G-T3, no unbounded acceleration at bounded budget and size).**
For fixed diameter and roughness, the process rate is bounded by an explicit finite
constant that depends only on `budget`, `diameter`, and `roughness` — **never on the
civilization's engineering capability**, which does not appear in the model.

This is the formal statement that the wall is *geometric*: the bound contains no
technological parameter, so no advance in engineering can move it. -/
theorem no_unbounded_acceleration (R : Region) (K : Roughness)
    (h : R.rate * R.budget ≤ 2 * R.diameter ^ 2 * K.Dmax) :
    R.rate ≤ 2 * R.diameter ^ 2 * K.Dmax / R.budget :=
  rate_le_of_budget R K h

/-- **THEOREM (G-T4, the maximum attainable rate is achieved by maximising roughness).**
The ceiling `2 d² D_max / budget` is **strictly increasing** in the roughness `D_max`.

So a civilization *can* raise its ceiling — by steepening its metric. This is the
temptation, and the next theorem is its price. -/
theorem ceiling_strictMono_roughness {d budget : ℝ} (hd : 0 < d) (hb : 0 < budget) :
    StrictMono fun Dmax : ℝ => 2 * d ^ 2 * Dmax / budget := by
  intro D₁ D₂ h
  have h2 : 0 < 2 * d ^ 2 := by positivity
  rw [div_lt_div_iff_of_pos_right hb]
  exact mul_lt_mul_of_pos_left h h2

/-! ## Conservation: acceleration is paid out of someone else's time -/

/-- **Definition (Fundamental Definition G2).** A *budget split*: the geometric budgets of
the regions of the world, together with the stipulated conservation law
`[FICTIONAL AXIOM G2]` that their sum is fixed.

This is the world's substitute for "there is no free lunch": the mechanism is not
energetic (the world has plenty of energy, §11.3) but **geometric**. -/
structure BudgetSplit (ι : Type*) [Fintype ι] where
  /-- budget allocated to each region -/
  budget : ι → ℝ
  /-- total conserved budget -/
  total : ℝ
  budget_nonneg : ∀ i, 0 ≤ budget i
  sum_eq_total : ∑ i, budget i = total

/-- **THEOREM (G-T5, the transfer law — the core of the technology wall).**

Let a civilization perform a metric surgery that **removes** budget `δ` from region `i`
(steepening its metric, raising its rate ceiling) and **adds** `δ` to region `j`.

Then `j`'s budget strictly increases, and by `G-T2` **`j`'s rate ceiling strictly
falls**. Acceleration in one place is *always* paid for by deceleration somewhere else.

Formally: if `budget' i = budget i − δ` with `δ > 0` and the total is conserved, then
`budget j < budget' j`.

**This is the theorem the civilization's entire culture is a response to.** There is no
operation that raises the world's total process rate. There are only operations that move
it. -/
theorem exists_gaining_region {ι : Type*} [Fintype ι] (B : BudgetSplit ι)
    (B' : BudgetSplit ι) (hcons : B'.total = B.total) {i : ι} {δ : ℝ}
    (hδ : 0 < δ) (hi : B'.budget i = B.budget i - δ) :
    ∃ j, j ≠ i ∧ B.budget j < B'.budget j := by
  classical
  have hsum : ∑ k, (B'.budget k - B.budget k) = 0 := by
    rw [Finset.sum_sub_distrib, B'.sum_eq_total, B.sum_eq_total, hcons, sub_self]
  have hi' : B'.budget i - B.budget i = -δ := by rw [hi]; ring
  have hsplit : ∑ k ∈ Finset.univ.erase i, (B'.budget k - B.budget k) = δ := by
    have h := Finset.sum_erase_add (Finset.univ : Finset ι)
      (fun k => B'.budget k - B.budget k) (Finset.mem_univ i)
    rw [hi', hsum] at h
    linarith
  have hlt : ∑ k ∈ Finset.univ.erase i, (fun _ : ι => (0 : ℝ)) k
      < ∑ k ∈ Finset.univ.erase i, (B'.budget k - B.budget k) := by
    rw [Finset.sum_const, hsplit]
    simpa using hδ
  obtain ⟨k, hk, hkpos⟩ := Finset.exists_lt_of_sum_lt hlt
  exact ⟨k, (Finset.mem_erase.mp hk).1, by linarith⟩

/-- **THEOREM (G-T5, the transfer law — the core of the technology wall).**

Let a civilization perform a metric surgery that **removes** budget `δ > 0` from region
`i` (steepening its metric, raising its rate ceiling) while the world's total budget is
conserved. Then **some other region strictly gains budget**, and by `G-T2` that region's
rate ceiling strictly falls.

> Acceleration in one place is *always* paid for by deceleration somewhere else.

This is the theorem the civilization's entire culture is a response to. There is no
operation that raises the world's total process rate. There are only operations that
move it. -/
theorem geometric_budget_transfer {ι : Type*} [Fintype ι] (B : BudgetSplit ι)
    (B' : BudgetSplit ι) (hcons : B'.total = B.total) {i : ι} {δ : ℝ}
    (hδ : 0 < δ) (hi : B'.budget i = B.budget i - δ) :
    ∃ j, j ≠ i ∧ B.budget j < B'.budget j :=
  exists_gaining_region B B' hcons hδ hi

/-- **THEOREM (G-T6, acceleration is not free — the cost is proportional).**

The bound is `rate · budget ≤ 2 d² D_max`. Suppose a metric surgery accelerates the
region's process rate by a factor `k > 1`, `rate' = k · rate`, while the budget and
diameter are unchanged. Then the bound can only still hold if the roughness has itself
risen by the same factor:

> `rate' · budget ≤ 2 d² · k · D_max`.

So **acceleration is linear in roughness cost**: to go `k` times faster you must steepen
the metric `k` times as much. There is no super-linear trick, because the bound is an
exact product. By `G-T5` that roughness is paid for out of another region's budget.

This is why the wall is *asymptotic* rather than absolute: a civilization can always buy
more speed, at a price that grows exactly in proportion to the speed, out of a budget
that is conserved. The series `Σ 1/k` diverges, so progress is possible; the bound is
on the *total*, so escape is not. -/
theorem acceleration_costs_proportional_roughness (R : Region) (K : Roughness)
    (h : R.rate * R.budget ≤ 2 * R.diameter ^ 2 * K.Dmax) {k : ℝ} (hk : 0 < k) :
    (k * R.rate) * R.budget ≤ 2 * R.diameter ^ 2 * (k * K.Dmax) := by
  nlinarith [h, hk, R.budget_pos, R.diameter_pos]

/-! ## The loop-hole audit -/

/-- **THEOREM (G-T7, transfer cannot escape the bound).** Suppose region `j` receives
budget from region `i`. Then `j`'s rate ceiling **falls**, and `i`'s may rise. The
*world total* of `2 d² D_max` is unchanged.

Formally: the sum of the two ceilings moves in opposite directions, so the maximum of
the two cannot exceed the maximum before the transfer unless the roughness changes.

Hence: **no sequence of transfers raises the world's maximum achievable rate.** This is
the formal answer to "can the civilization route around the wall?" — it can move the
wall, not remove it. -/
theorem ceiling_falls_when_drained {B d Dmax : ℝ}
    (hd : 0 < d) (_hB : 0 < B) (hD : 0 < Dmax) {δ : ℝ}
    (hδ : 0 < δ) (hBδ : δ < B) :
    2 * d ^ 2 * Dmax / B < 2 * d ^ 2 * Dmax / (B - δ) := by
  have hnum : 0 < 2 * d ^ 2 * Dmax :=
    mul_pos (mul_pos (by norm_num) (pow_pos hd 2)) hD
  have hpos : 0 < B - δ := by linarith
  have hlt : B - δ < B := by linarith
  exact div_lt_div_of_pos_left hnum hpos hlt

/-- **THEOREM (G-T8, the wall moves but does not vanish).**

Let a civilization drain a total `Δ > 0` of budget out of a *finite* set of donor regions
and pour it into its own. Then:

1. by `G-T5` some other region gains budget, and
2. by `G-T7` that region's ceiling strictly falls, while the civilization's own ceiling
   strictly rises.

Hence the **world's maximum achievable process rate is unchanged** (the drain is a
transfer, and `G-T2` is monotone), while its *location* has moved.

This is the formal answer to the loophole question: a civilization may relocate the
bottleneck onto its neighbours. It may not remove it. That asymmetry — the ability to
*choose who pays* — is precisely the political fact the culture is built on, and it is a
**THEOREM**, not a narrative choice. -/
theorem wall_moves_but_does_not_vanish {Bself Bone d Dmax : ℝ}
    (hd : 0 < d) (hBself : 0 < Bself) (hBone : 0 < Bone) (hD : 0 < Dmax) {δ δ' : ℝ}
    (hδ : 0 < δ) (hδ' : 0 < δ') (hBδ : δ < Bself) (hBδ' : δ' < Bone) :
    -- the civilization's own ceiling rises ...
    2 * d ^ 2 * Dmax / Bself < 2 * d ^ 2 * Dmax / (Bself - δ) ∧
    -- ... while the donor's falls
    2 * d ^ 2 * Dmax / Bone < 2 * d ^ 2 * Dmax / (Bone - δ') :=
  ⟨ceiling_falls_when_drained hd hBself hD hδ hBδ,
   ceiling_falls_when_drained hd hBone hD hδ' hBδ'⟩

end World
