/-
Copyright (c) 2026 STRING THEORY Formalization Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Formalized World Reconstruction
-/
module

public import World.Dynamics

/-!
# World.Civilization — Technology Selection, Population, and Institutional Dynamics

This module formalises §11–§16 of the Formalized World Model.

## The central methodological demand

The task specification requires that **technology be a derived quantity, not an
authorial choice**:

> Do not specify "the people of this era use technology `X`". Instead, ask: under the
> current constraint `X = (E, S, R, T, …)`, what is the cost/benefit of technology
> `Tᵢ`, and let `arg maxᵢ U(Tᵢ)` be the *emergent* selection.

This module implements exactly that. `bestTechnology` is an `argmax` of a utility
functional, and every theorem below is about how that `argmax` moves when the world's
constraints move. No technology is ever named.

## What this buys

The world's signature technologies — the Diffusion Engine, the "diffusion launch", the
ritual destruction of goods — are *not* postulated here. They are the computed
consequences of moving the constraints:

* `selection_shifts_from_preservation`: as attention gets scarce, the optimal
  technology stops being a preservation technology.
* `ritual_is_optimal_under_scarcity`: under a sufficiently tight attention budget, an
  action that *releases* structure strictly beats every action that holds it.
* `population_capacity_bound`: population is bounded by resource inflow, not chosen.
-/

@[expose] public section

namespace World

open Real

/-! ## Technology selection as an argmax -/

/-- **Definition (Fundamental Definition F8).** A technology, described only by its
observable parameters: the structure it can preserve per unit time, and the attention
it costs per unit time.

Nothing about *what* the technology is enters the model. This is the point. -/
structure Tech where
  /-- structure preserved per unit time -/
  preserves : ℝ
  /-- attention consumed per unit time -/
  cost : ℝ
  preserves_nonneg : 0 ≤ preserves
  cost_nonneg : 0 ≤ cost

/-- **Definition (Fundamental Definition F9).** The utility of a technology given the
shadow price of attention, `λ ≥ 0`, and of preserved structure, `β ≥ 0`:

`U(T) = β · preserves(T) - λ · cost(T)`.

This is the world's technology-selection criterion. `λ` is the scarcity of attention
(Axiom P10); `β` is how much the civilization values persistence. -/
noncomputable def techUtility (β lam : ℝ) (T : Tech) : ℝ :=
  β * T.preserves - lam * T.cost

/-- **Definition (Fundamental Definition F10).** The technologies that maximise utility.
A technology is *selected* in this world exactly when it lies in this set. -/
def bestTechnology (β lam : ℝ) (S : Set Tech) : Set Tech :=
  {T ∈ S | ∀ T' ∈ S, techUtility β lam T' ≤ techUtility β lam T}

/-- **THEOREM (C-T1).** Every selected technology maximises utility, so a selected
technology is at least as good as any feasible alternative. This is what "emergent
technology" means formally: the selection is *defined* by the constraint, not chosen. -/
theorem bestTechnology_maximal {β lam : ℝ} {S : Set Tech} {T : Tech}
    (h : T ∈ bestTechnology β lam S) : ∀ T' ∈ S, techUtility β lam T' ≤ techUtility β lam T :=
  h.2

/-- **THEOREM (C-T2, the Diffusion Engine is selected only while structure is cheap to
attend to).** Fix two technologies `T₁` (a preservation technology) and `T₂` (a
replacement technology), with `T₂` preserving strictly less than `T₁` but costing
strictly less attention.

Then there is a *finite* threshold shadow price `λ*` of attention such that:
* for `λ < λ*` the preservation technology `T₁` has strictly higher utility;
* for `λ > λ*` the replacement technology `T₂` does.

This is the formal statement that **the world's technology mix flips as attention
becomes scarce** — no authorial intervention required. It is the model-theoretic content
of the source document's transition from "扩散派" (preservation) to "祭祀者"
(release). -/
theorem selection_shifts_from_preservation {T₁ T₂ : Tech} (β : ℝ)
    (hβ : 0 < β) (hpres : T₂.preserves < T₁.preserves) (hcost : T₂.cost < T₁.cost) :
    ∃ lamStar : ℝ, 0 < lamStar ∧
      (∀ lam : ℝ, lam < lamStar → techUtility β lam T₂ < techUtility β lam T₁) ∧
      (∀ lam : ℝ, lamStar < lam → techUtility β lam T₁ < techUtility β lam T₂) := by
  have hden : 0 < T₁.cost - T₂.cost := by linarith [hcost]
  have hnum : 0 < β * (T₁.preserves - T₂.preserves) :=
    mul_pos hβ (by linarith [hpres])
  refine ⟨β * (T₁.preserves - T₂.preserves) / (T₁.cost - T₂.cost), div_pos hnum hden, ?_, ?_⟩
  · intro lam hlam
    have h1 : lam * (T₁.cost - T₂.cost)
        < β * (T₁.preserves - T₂.preserves) := by
      have h2 : lam * (T₁.cost - T₂.cost)
          < β * (T₁.preserves - T₂.preserves) / (T₁.cost - T₂.cost)
            * (T₁.cost - T₂.cost) := mul_lt_mul_of_pos_right hlam hden
      rwa [div_mul_cancel₀ _ hden.ne'] at h2
    simp only [techUtility]
    nlinarith [h1]
  · intro lam hlam
    have h1 : β * (T₁.preserves - T₂.preserves)
        < lam * (T₁.cost - T₂.cost) := by
      have h2 : β * (T₁.preserves - T₂.preserves) / (T₁.cost - T₂.cost)
            * (T₁.cost - T₂.cost) < lam * (T₁.cost - T₂.cost) :=
        mul_lt_mul_of_pos_right hlam hden
      rwa [div_mul_cancel₀ _ hden.ne'] at h2
    simp only [techUtility]
    nlinarith [h1]

/-- **THEOREM (C-T3, the formal core of the Ritual of Fracture).** Suppose a "holding"
technology `T_hold` preserves a positive amount at positive attention cost, and a
"releasing" technology `T_release` preserves nothing at zero cost.

Then beyond a finite shadow price `λ* = β · T_hold.preserves / T_hold.cost`, releasing
strictly dominates holding.

**This is why the source document's 祭祀者 exist.** Ritual destruction is not a cultural
taste; it is the *utility-maximising* technology of a civilization whose attention
budget has fallen below the cost of holding. The cultural institution is an emergent
consequence of `λ`, exactly as §9 of the task specification requires. -/
theorem ritual_is_optimal_under_scarcity {T_hold : Tech} (β : ℝ) (hβ : 0 < β)
    (hpres : 0 < T_hold.preserves) (hcost : 0 < T_hold.cost) :
    let T_release : Tech := ⟨0, 0, le_refl 0, le_refl 0⟩
    ∃ lamStar : ℝ, 0 < lamStar ∧
      ∀ lam : ℝ, lamStar < lam → techUtility β lam T_hold < techUtility β lam T_release := by
  intro T_release
  refine ⟨β * T_hold.preserves / T_hold.cost, div_pos (mul_pos hβ hpres) hcost, ?_⟩
  intro lam hlam
  have h1 : β * T_hold.preserves < lam * T_hold.cost := by
    have h2 : β * T_hold.preserves / T_hold.cost * T_hold.cost < lam * T_hold.cost :=
      mul_lt_mul_of_pos_right hlam hcost
    rwa [div_mul_cancel₀ _ hcost.ne'] at h2
  simp only [techUtility, T_release]
  nlinarith [h1]

/-! ## Population dynamics -/

/-- **Definition (Fundamental Definition F11).** A civilization's resource base:
resource inflow `R ≥ 0`, and resource consumed per capita `c > 0`. -/
structure ResourceBase where
  /-- resource inflow per unit time -/
  inflow : ℝ
  /-- resource consumed per capita per unit time -/
  perCapita : ℝ
  inflow_nonneg : 0 ≤ inflow
  perCapita_pos : 0 < perCapita

/-- **Definition (Fundamental Definition F12).** The carrying capacity: the largest
population sustainable by a resource base. -/
noncomputable def carryingCapacity (B : ResourceBase) : ℝ := B.inflow / B.perCapita

/-- **THEOREM (C-T4).** Population is bounded by carrying capacity. Formally: if every
individual consumes at least `c > 0`, then `P · c ≤ R`.

Population is therefore *derived*, not chosen: it is an output of the resource base. -/
theorem population_capacity_bound (B : ResourceBase) {P : ℝ} (_hP : 0 ≤ P)
    (h : P * B.perCapita ≤ B.inflow) : P ≤ carryingCapacity B := by
  rw [carryingCapacity, le_div_iff₀ B.perCapita_pos]
  linarith

/-- **THEOREM (C-T5).** Carrying capacity is strictly increasing in resource inflow and
strictly decreasing in per-capita consumption.

**Consequence for the world model.** In a high-gravity world (§2.2 of the source
document) the per-capita resource cost of any activity involving *lifting mass* is
`ε = v_esc²/4` per kilogram (`World.Physics`, `climbEnergyPerMass`), and `v_esc` is
large. Hence `perCapita` is inflated and carrying capacity is *depressed* — a physical
constraint propagating directly into demography. This is one link in the required
`Physics → … → Population` chain. -/
theorem carryingCapacity_strictMono_inflow {c : ℝ} (hc : 0 < c) :
    StrictMono fun R : ℝ => R / c := by
  intro R₁ R₂ h
  exact div_lt_div_of_pos_right h hc

/-- **THEOREM (C-T6).** The same statement for per-capita cost: a larger per-capita
requirement strictly lowers carrying capacity. -/
theorem carryingCapacity_antitone_perCapita {R : ℝ} (hR : 0 < R) {c₁ c₂ : ℝ}
    (h1 : 0 < c₁) (h : c₁ < c₂) : R / c₂ < R / c₁ :=
  div_lt_div_of_pos_left hR h1 h

/-! ## Institutional equilibrium -/

/-- **Definition (Fundamental Definition F13).** An institution is a feasible set of
behaviours together with the payoff they earn. Institutions *constrain*; they do not
determine culture (that is `World.Culture`'s job). -/
structure Institution where
  /-- the feasible behaviour set -/
  feasible : Set ℝ
  /-- payoff of a behaviour -/
  payoff : ℝ → ℝ

/-- **Definition (Fundamental Definition F14).** The *institutional equilibrium*: the
best payoff attainable within the institution's feasible set. -/
noncomputable def institutionalEquilibrium (I : Institution) (b : ℝ) : Prop :=
  b ∈ I.feasible ∧ ∀ b' ∈ I.feasible, I.payoff b' ≤ I.payoff b

/-- **THEOREM (C-T7, institutions bind).** If the feasible set shrinks *while the payoff
function is unchanged*, the attainable payoff cannot increase.

Formally, for `I₂.feasible ⊆ I₁.feasible` and `I₂.payoff = I₁.payoff`, any equilibrium
`b₂` of the smaller institution earns at most any equilibrium `b₁` of the larger one.

**Consequence, and a warning the source document needs.** Institutions constrain, but
they do not by themselves determine behaviour: the theorem needs the payoff function to
be *equal*. If an institutional change also changes payoffs (which is what a change in
attention scarcity `λ` does, via `techUtility`), the attainable payoff can move in
either direction. This is precisely why `World.Culture` must derive norms from
*incentives* rather than from institutions alone, and why the task specification's
chain `Institution → Behavioral Incentives → Cultural Norm` needs the incentive step. -/
theorem institution_restriction_bounds_payoff {I₁ I₂ : Institution}
    (hsub : I₂.feasible ⊆ I₁.feasible) (hpay : I₂.payoff = I₁.payoff) {b₁ b₂ : ℝ}
    (h₁ : institutionalEquilibrium I₁ b₁) (h₂ : institutionalEquilibrium I₂ b₂) :
    I₂.payoff b₂ ≤ I₁.payoff b₁ := by
  rw [hpay]
  exact h₁.2 b₂ (hsub h₂.1)

end World
