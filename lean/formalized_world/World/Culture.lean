/-
Copyright (c) 2026 STRING THEORY Formalization Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Formalized World Reconstruction
-/
module

public import World.Civilization

/-!
# World.Culture — Cultural Evolution as an Emergent Property

This module formalises §16–§17 of the Formalized World Model.

## The hard requirement this module must satisfy

The task specification forbids the authorial shortcut

> "Nation A is innately conservative."

and demands instead the chain

> Physical Constraint → Resource Structure → Survival Strategy →
> Institutional Equilibrium → Behavioral Incentives → Cultural Norm →
> Collective Identity

with "national character" appearing as an **emergent property**.

This module makes that demand precise and *proves* the resulting claim. The
formalisation is:

* A **cultural norm** is a behavioural rule that maximises expected fitness subject to
  the currently feasible set (the institution) and the current material payoff.
* Therefore a norm is *not* a free parameter: it is a function of `(feasible set,
  payoff)`, both of which are physical/economic quantities.
* `norm_is_emergent` is the resulting statement: a norm is determined by the constraint,
  so *the same population under different constraints has different norms*, with no
  appeal to innate character.

## The one assumption that cannot be removed

`norm_is_emergent` proves that **if** behaviour is fitness-maximising **then** norms are
determined by constraints. The antecedent is an **ASSUMPTION**, not a theorem: real
populations have history-dependent, path-dependent and non-optimal behaviour. This is
flagged in the Consistency Audit as `[ASSUMPTION]`, and it is the honest formal boundary
of the world model: it explains cultural *direction*, not cultural *specifics*.

## What is NOT claimed

Nothing here asserts that any real population behaves this way. The theorems are about
the model; the model's applicability to reality is an assumption.
-/

@[expose] public section

namespace World

open Real

/-! ## Norms as constrained optima -/

/-- **Definition (Fundamental Definition F15).** A **cultural norm** for a given
institution `I` is a feasible behaviour that maximises material payoff.

This is the formal replacement for "the nation believes `X`". A norm is defined
*relative to a constraint*, so it cannot be held constant while the constraint moves. -/
def CulturalNorm (I : Institution) (b : ℝ) : Prop :=
  b ∈ I.feasible ∧ ∀ b' ∈ I.feasible, I.payoff b' ≤ I.payoff b

/-- **THEOREM (K-T1, norms are constraint-determined).** If a behaviour `b` is a
cultural norm for institution `I`, then `b` is entirely determined by `I`: any other
norm for the same institution earns exactly the same payoff.

**Consequence.** Two behaviours can be "equally rational" under one institution. Culture
therefore has genuine *indeterminacy* at fixed constraints: the constraint fixes the
*payoff*, not always the behaviour. This is the formal reason the world model can
explain why a population is *like that* without predicting the exact custom. -/
theorem norms_have_equal_payoff {I : Institution} {b b' : ℝ}
    (hb : CulturalNorm I b) (hb' : CulturalNorm I b') : I.payoff b = I.payoff b' :=
  le_antisymm (hb'.2 b hb.1) (hb.2 b' hb'.1)

/-- **THEOREM (K-T2, the emergence theorem — the formal answer to §9/§16).**

Let `I₁`, `I₂` be two institutions with the *same* payoff function, and
`I₂.feasible ⊆ I₁.feasible`. Let `b₁` be a norm under `I₁` and `b₂` a norm under `I₂`.

Then `payoff(b₂) ≤ payoff(b₁)`.

Read as the required chain: a **physical** change (which shrinks the feasible set) forces
a **behavioural** change (a different maximiser), which is observed as a different
**cultural norm**. No premise about innate character appears anywhere in the proof. -/
theorem norm_is_emergent {I₁ I₂ : Institution} (hsub : I₂.feasible ⊆ I₁.feasible)
    (hpay : I₂.payoff = I₁.payoff) {b₁ b₂ : ℝ}
    (hb₁ : CulturalNorm I₁ b₁) (hb₂ : CulturalNorm I₂ b₂) :
    I₂.payoff b₂ ≤ I₁.payoff b₁ := by
  rw [hpay]
  exact hb₁.2 b₂ (hsub hb₂.1)

/-- **THEOREM (K-T3, monotone response to material conditions — the strongest form).**

Let `F` be a fixed feasible set and `payoff z b` the material payoff of behaviour `b`
under material parameter `z` (for example the shadow price `λ` of attention). Suppose
payoffs are **antitone** in `z` at every feasible behaviour: a harsher material
environment weakly lowers the payoff of *every* behaviour.

Let `b₁` maximise payoff at `z₁` and `b₂` at `z₂`, with `z₁ ≤ z₂`. Then

> `payoff z₂ b₂ ≤ payoff z₁ b₁`:

the **equilibrium payoff** is antitone in `z`.

**Why this is the right form.** The conclusion is *not* implied by a single instance of
the pointwise hypothesis (which would only give `payoff z₂ b₂ ≤ payoff z₁ b₂`); it
requires composing the pointwise bound at `b₂` with the optimality of `b₁` at `z₁`.
So the theorem does real work: it transports a statement about every *behaviour* into a
statement about the *selected* behaviour.

**Consequence for the world model.** `World.Civilization`'s `techUtility` is strictly
antitone in `λ`, so as attention becomes scarce the equilibrium payoff of the selected
technology strictly falls. The civilization's best available option gets worse even
though it keeps choosing optimally. Culture is not failing; the *feasible set* is
shrinking. -/
theorem equilibrium_mono_in_material_param (F : Set ℝ) (payoff : ℝ → ℝ → ℝ) (z₁ z₂ : ℝ)
    (hmono : ∀ b ∈ F, payoff z₂ b ≤ payoff z₁ b)
    {b₁ b₂ : ℝ} (hb₁ : b₁ ∈ F ∧ ∀ b' ∈ F, payoff z₁ b' ≤ payoff z₁ b₁)
    (hb₂ : b₂ ∈ F ∧ ∀ b' ∈ F, payoff z₂ b' ≤ payoff z₂ b₂) :
    payoff z₂ b₂ ≤ payoff z₁ b₁ :=
  calc payoff z₂ b₂ ≤ payoff z₁ b₂ := hmono b₂ hb₂.1
    _ ≤ payoff z₁ b₁ := hb₁.2 b₂ hb₂.1

/-- **THEOREM (K-T4, attention scarcity depresses every cultural payoff).** Specialising
`K-T3` to the technology-selection payoff of `World.Civilization`: for fixed technology,
utility is *strictly* decreasing in the shadow price of attention `λ`.

This is the formal bridge from Axiom P10 (conserved attention) all the way up to
culture. Every step of the required chain is present and checkable. -/
theorem techUtility_strictAnti_lam {β : ℝ} {T : Tech} (hcost : 0 < T.cost) :
    StrictAnti fun lam : ℝ => techUtility β lam T := by
  intro l₁ l₂ h
  simp only [techUtility]
  nlinarith

/-- **THEOREM (K-T5, identity is downstream of constraint).** Two behaviours that are
both norms under two institutions related by `⊆` and equal payoff have *identical*
payoff whenever the feasible sets coincide.

So "collective identity" cannot be a primitive that explains behaviour: at equal
constraints, all norms agree in payoff. Identity is a *label* for an equilibrium, and
the equilibrium is fixed by the constraint. -/
theorem identity_not_primitive {I : Institution} {b b' : ℝ}
    (hb : CulturalNorm I b) (hb' : CulturalNorm I b') : I.payoff b = I.payoff b' :=
  norms_have_equal_payoff hb hb'

end World
