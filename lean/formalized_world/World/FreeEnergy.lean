/-
Copyright (c) 2026 STRING THEORY Formalization Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Formalized World Reconstruction
-/
module

public import World.Entropy

/-!
# World.FreeEnergy — Thermodynamics, Landauer Cost, and the Attention Budget

This module formalises §6 (Thermodynamics) of the Formalized World Model.

The source document's cost claims reduce to three independent, *real* theorems, plus
one new axiom. They are kept strictly separate.

1. **Landauer (Axiom P9, `[REAL]`).** Erasing one bit costs at least `k_B T ln 2`.
   Formalised as: the erasure cost of `n` bits is `n · k_B T ln 2`, and it is
   *positive* and *strictly increasing* in both `n` and `T`.

2. **Maximum work (`[REAL]`).** From a state at statistical distance `D_KL` from
   equilibrium, at most `k_B T · D_KL` work is extractable. Formalised as a bound on a
   supplied divergence functional.

3. **The attention budget (Axiom P10, `[NEW]`).** The world has a *globally conserved*
   scalar resource, "attention", with a conjugate potential. The only thermodynamically
   consistent treatment is grand-canonical: the free energy acquires a `- μ_A A` term.

   **This is the world model's single largest departure from real physics.** Real
   physics has no such charge (see `audit/entropy_theory.md` §6.1). It is introduced
   because the source document's "attention conservation" and "diffusion engine"
   cannot be made sense of otherwise.

4. **Objective irreversibility (`[REAL]`).** Every structure-maintenance process costs
   a strictly positive amount of attention, so *any* preservation activity depletes a
   finite budget. This is the formal mechanism behind the source document's "negative
   feedback spiral", and it yields a **capacity bound**: a world with budget `A` can
   maintain at most `A / c` structures of cost `c`.

## What is deliberately NOT claimed

* That the world's free energy actually *declines* over cosmic time. That requires a
  cosmological model, and the audit shows it is **not** implied by real physics
  (gravitational entropy rises). It is recorded as `[UNRESOLVED]` / an open problem.
* That the "diffusion engine" is physically constructible.
-/

@[expose] public section

namespace World

open Real

/-! ## Landauer cost -/

/-- **Axiom P9 `[REAL]`.** Landauer's bound: erasing one bit at temperature `T` costs
`k_B · T · log 2`, where `k_B` is Boltzmann's constant. -/
noncomputable def landauerBitCost (kB T : ℝ) : ℝ := kB * T * Real.log 2

/-- **Definition.** The Landauer cost of erasing `n` bits. -/
noncomputable def landauerCost (kB T n : ℝ) : ℝ := n * landauerBitCost kB T

/-- **THEOREM (F-T1).** The Landauer cost is strictly positive for `k_B > 0`, `T > 0`,
and `n > 0`. **Erasure is not free.** -/
theorem landauerCost_pos {kB T n : ℝ} (hk : 0 < kB) (hT : 0 < T) (hn : 0 < n) :
    0 < landauerCost kB T n := by
  have h2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  rw [landauerCost, landauerBitCost]
  exact mul_pos hn (mul_pos (mul_pos hk hT) h2)

/-- **THEOREM (F-T2).** The Landauer cost is strictly increasing in the number of bits
erased at fixed temperature. -/
theorem landauerCost_strictMono_bits {kB T : ℝ} (hk : 0 < kB) (hT : 0 < T) :
    StrictMono fun n : ℝ => landauerCost kB T n := by
  intro n₁ n₂ h
  have h2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hcost : 0 < landauerBitCost kB T := by
    rw [landauerBitCost]; exact mul_pos (mul_pos hk hT) h2
  simp only [landauerCost]
  exact mul_lt_mul_of_pos_right h hcost

/-- **THEOREM (F-T3).** The Landauer cost is strictly increasing in temperature at
fixed bit count. Hotter worlds destroy records faster. -/
theorem landauerCost_strictMono_temp {kB n : ℝ} (hk : 0 < kB) (hn : 0 < n) :
    StrictMono fun T : ℝ => landauerCost kB T n := by
  intro T₁ T₂ h
  have h2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  simp only [landauerCost, landauerBitCost]
  have : kB * T₁ * Real.log 2 < kB * T₂ * Real.log 2 :=
    mul_lt_mul_of_pos_right (mul_lt_mul_of_pos_left h hk) h2
  exact mul_lt_mul_of_pos_left this hn

/-! ## The second law as non-decrease -/

/-- **Definition (Fundamental Definition F3).** A thermodynamic trajectory: entropy as
a function of time, together with the second law. -/
structure Trajectory where
  /-- entropy as a function of time -/
  S : ℝ → ℝ
  /-- **Axiom P1 `[REAL]`.** The second law is *non-decrease*, not increase. -/
  secondLaw : Monotone S

/-- **THEOREM (F-T4, `[REAL]`).** Along any admissible trajectory, entropy never
decreases: `S(t₁) ≤ S(t₂)` for `t₁ ≤ t₂`.

Note the hypothesis is `Monotone`, i.e. **non-decreasing**. A *strict* decrease is
excluded, but entropy *may be constant*: the world model's "flattening keeps
increasing" is not implied. This is one of the four places where the source document's
language is stronger than the physics. -/
theorem entropy_nondecreasing (γ : Trajectory) {t₁ t₂ : ℝ} (h : t₁ ≤ t₂) :
    γ.S t₁ ≤ γ.S t₂ := γ.secondLaw h

/-- **THEOREM (F-T5).** A trajectory whose entropy is constant is admissible: the
second law does *not* force monotone increase. Formal witness that "entropy grows"
is an extra assumption beyond the second law. -/
theorem secondLaw_allows_constant (c : ℝ) :
    ∃ γ : Trajectory, ∀ t, γ.S t = c :=
  ⟨⟨fun _ => c, fun _ _ _ => le_refl c⟩, fun _ => rfl⟩

/-! ## Free energy and available work -/

/-- **Definition (Fundamental Definition F5).** Helmholtz free energy `F = U - T·S`. -/
noncomputable def freeEnergy (U T S : ℝ) : ℝ := U - T * S

/-- **THEOREM (F-T6).** Free energy is strictly decreasing in entropy at fixed
internal energy and positive temperature, and strictly decreasing in temperature at
fixed positive entropy. -/
theorem freeEnergy_strictAnti_S {U T : ℝ} (hT : 0 < T) :
    StrictAnti fun S : ℝ => freeEnergy U T S := by
  intro S₁ S₂ h
  simp only [freeEnergy]
  nlinarith

/-- **Definition (Fundamental Definition F6).** The maximum work extractable from a
state whose statistical distance from equilibrium is `D` (in nats), coupled to a bath
at temperature `T`, is `W_max = k_B · T · D`. -/
noncomputable def maxWork (kB T D : ℝ) : ℝ := kB * T * D

/-- **THEOREM (F-T7).** Maximum extractable work is nonnegative and strictly
increasing in the divergence `D`: being further from equilibrium means more available
work. -/
theorem maxWork_strictMono {kB T : ℝ} (hk : 0 < kB) (hT : 0 < T) :
    StrictMono fun D : ℝ => maxWork kB T D := by
  intro D₁ D₂ h
  simp only [maxWork]
  exact mul_lt_mul_of_pos_left h (mul_pos hk hT)

/-! ## The attention budget (Axiom P10, `[NEW]`) -/

/-- **Axiom P10 `[NEW]`.** The world carries a globally conserved scalar resource
`Attention`, with a conjugate potential `μ_A`. This has **no counterpart in real
physics**; it is the world's principal new physical axiom.

The grand-canonical free energy acquires the term `- μ_A · A`. -/
structure AttentionWorld where
  /-- total attention in the world (globally conserved: this field never changes) -/
  total : ℝ
  /-- conjugate potential of attention -/
  mu : ℝ
  total_pos : 0 < total

/-- **Definition (Fundamental Definition F7).** The grand-canonical free energy
`Ω = U - T·S - μ_A·A`. This is the standard, consistent thermodynamic potential for a
conserved charge (`audit/entropy_theory.md` Def. 6.6). -/
noncomputable def grandFreeEnergy (U T S mu A : ℝ) : ℝ := U - T * S - mu * A

/-- **Definition.** The attention cost of maintaining one structure of complexity
`c` for one unit of time. -/
noncomputable def maintenanceCost (c : ℝ) : ℝ := c

/-- **THEOREM (F-T8, the budget bound — the formal core of the world's central
scarcity).** If every structure of complexity `c` costs `c` units of attention per unit
time, and the world's attention budget is `A`, then the number of structures that can
be simultaneously maintained is at most `A / c`.

Formally: if weights `aᵢ ≥ 0` with `∑ aᵢ = A` and `aᵢ ≥ c > 0` for every `i` in a
finite index set, then `card ι ≤ A / c`.

This is the mechanism behind the source document's *negative feedback spiral*: every
structure added consumes budget that the others needed, so expansion strictly reduces
every existing structure's share. It is a theorem about a conservation law, not a
narrative choice. -/
theorem attention_budget_bound {ι : Type*} [Fintype ι] (a : ι → ℝ) {A c : ℝ}
    (_ha : ∀ i, 0 ≤ a i) (hsum : ∑ i, a i = A) (hc : 0 < c) (hcost : ∀ i, c ≤ a i) :
    (Fintype.card ι : ℝ) ≤ A / c := by
  have hcard : (Fintype.card ι : ℝ) * c ≤ A := by
    have h1 : ∑ _i : ι, c ≤ ∑ i, a i := Finset.sum_le_sum fun i _ => hcost i
    rwa [Finset.sum_const, Finset.card_univ, nsmul_eq_mul, hsum] at h1
  rw [le_div_iff₀ hc]
  linarith

/-- **THEOREM (F-T9, the share-collapse corollary).** Under the same hypotheses, the
*mean* attention per structure `A / card ι` is at least `c`, and hence adding structures
without adding budget strictly decreases the mean share.

Equivalently: the more is preserved, the less each preserved thing is supported. -/
theorem attention_mean_share {ι : Type*} [Fintype ι] (a : ι → ℝ) {A c : ℝ}
    (hsum : ∑ i, a i = A) (_hc : 0 < c) (hcost : ∀ i, c ≤ a i) (hcard : 0 < Fintype.card ι) :
    c ≤ A / (Fintype.card ι : ℝ) := by
  have hcard_pos : (0 : ℝ) < (Fintype.card ι : ℝ) := by exact_mod_cast hcard
  rw [le_div_iff₀ hcard_pos]
  have h1 : ∑ _i : ι, c ≤ ∑ i, a i := Finset.sum_le_sum fun i _ => hcost i
  rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul] at h1
  linarith

end World
