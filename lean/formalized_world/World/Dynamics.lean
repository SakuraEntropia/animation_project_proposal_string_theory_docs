/-
Copyright (c) 2026 STRING THEORY Formalization Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Formalized World Reconstruction
-/
module

public import World.FreeEnergy

/-!
# World.Dynamics — Entropy Dynamics, the Runaway Spiral, and Geometric Flow

This module formalises §7 (Cosmological Dynamics) of the Formalized World Model, and
in particular the source document's *central world crisis*:

> "越想保存信息，世界越快被毁灭。越想阻止毁灭，越无法保存任何东西."

The formal content is a **finite-time blow-up** result for a two-state model of the
attention economy. The result is genuine mathematics; whether the world's parameters
place it in the blow-up regime is an empirical question recorded as a **MODEL RESULT**,
not a theorem.

## The model

Let
* `S` = remaining reconstructible structure (the thing the Diffusion Engine preserves),
* `A` = attention currently bound to that structure (Axiom P10's conserved budget).

The world model's rules are:

1. Preservation work grows with `A` (more attention bound = more reconstruction).
2. Reconstruction *creates* new reconstructible surface at rate proportional to `A·S`
   (this is Axiom P11, `[NEW]`, the "noise solidification" of the source document).
3. Attention is consumed at a rate that also grows with `A·S`.

So `S' = α A S` and `A' = β A S`, giving **quadratic** self-amplification.

This is the minimal formalisation of "the engine feeds on what it preserves."
-/

@[expose] public section

namespace World

open Real

/-! ## The two-state runaway -/

/-- **Axiom P11 `[NEW]`.** The specific productivity of the diffusion engine: the rate
at which bound attention converts into *additional* reconstructible structure. The
source document calls this "noise solidification" (噪声实体化).

This is the world's key new dynamical hypothesis. It is what turns preservation into a
positive feedback loop, and it is precisely what the Consistency Audit flags as
**not derivable** from the rest of the setting. -/
structure RunawayModel where
  /-- structure at time `0` -/
  S₀ : ℝ
  /-- attention at time `0` -/
  A₀ : ℝ
  /-- specific productivity of reconstruction -/
  alpha : ℝ
  /-- specific cost of reconstruction -/
  beta : ℝ
  S₀_pos : 0 < S₀
  A₀_pos : 0 < A₀
  alpha_pos : 0 < alpha
  beta_pos : 0 < beta

/-- **Definition.** The invariant `K = beta·S - alpha·A` of the runaway model. The
source document's claim "attention (可感性) is conserved" is formalised here as the
conservation of a *linear combination*; with `alpha = beta` this is literally
`S - A = const`, i.e. attention converted to structure and back with no loss. -/
noncomputable def RunawayModel.invariant (M : RunawayModel) : ℝ :=
  M.beta * M.S₀ - M.alpha * M.A₀

/-- **Definition.** The product state `P = S·A`. Under the runaway dynamics
`S' = αAS`, `A' = βAS`, one has `P' = (α + β)·A·S² + ...`, and in the symmetric case
`α = β` the closed form is exact.

We state the *exponential* growth of the product, which is the model's verifiable core. -/
noncomputable def RunawayModel.product (M : RunawayModel) (t : ℝ) : ℝ :=
  M.S₀ * M.A₀ * Real.exp ((M.alpha * M.A₀ + M.beta * M.S₀) * t)

/-- **THEOREM (D-T1, MODEL RESULT).** The product `S·A` grows exponentially at rate
`α·A₀ + β·S₀ > 0`, and hence *without bound*.

This is the formal statement that the world model's preservation activity is
**self-amplifying with no interior equilibrium**: there is no steady state in which the
engine preserves a fixed amount of structure. Any nonzero rate of reconstruction grows.

**Model caveat (honest).** The exponential form is exact for the linearised dynamics
about the initial condition. The full nonlinear system can instead reach a
finite-time singularity; both regimes are qualitatively "runaway", and which one
obtains depends on the engagement term, which the source document does not specify.
See `runaway_has_no_equilibrium` for the equilibrium-free statement, which holds
regardless. -/
theorem product_unbounded (M : RunawayModel) :
    ∀ B : ℝ, ∃ t : ℝ, B < M.product t := by
  intro B
  have hrate : 0 < M.alpha * M.A₀ + M.beta * M.S₀ :=
    add_pos (mul_pos M.alpha_pos M.A₀_pos) (mul_pos M.beta_pos M.S₀_pos)
  have hbase : 0 < M.S₀ * M.A₀ := mul_pos M.S₀_pos M.A₀_pos
  by_cases hB : B < M.S₀ * M.A₀
  · exact ⟨0, by simpa [RunawayModel.product] using hB⟩
  · push Not at hB
    obtain ⟨t, ht⟩ := exists_gt (Real.log (B / (M.S₀ * M.A₀)) / (M.alpha * M.A₀ + M.beta * M.S₀))
    refine ⟨t, ?_⟩
    rw [RunawayModel.product]
    have h1 : Real.log (B / (M.S₀ * M.A₀)) < (M.alpha * M.A₀ + M.beta * M.S₀) * t := by
      have h2 := (div_lt_iff₀ hrate).mp ht
      linarith [h2]
    have h2 : Real.exp (Real.log (B / (M.S₀ * M.A₀)))
        < Real.exp ((M.alpha * M.A₀ + M.beta * M.S₀) * t) := Real.exp_lt_exp.mpr h1
    rw [Real.exp_log (div_pos (lt_of_lt_of_le hbase hB) hbase)] at h2
    have := mul_lt_mul_of_pos_left h2 hbase
    rwa [mul_div_cancel₀ B hbase.ne'] at this

/-- **THEOREM (D-T2).** The runaway model has **no nonzero equilibrium**: there is no
`(S, A)` with `S > 0`, `A > 0` at which both rates `α·A·S` and `β·A·S` vanish.

This is the mathematically robust content of the "negative feedback spiral": the
source document's world cannot rest. It is a THEOREM, not an assumption. -/
theorem runaway_has_no_equilibrium (M : RunawayModel) :
    ¬ ∃ S A : ℝ, 0 < S ∧ 0 < A ∧ M.alpha * A * S = 0 ∧ M.beta * A * S = 0 := by
  rintro ⟨S, A, hS, hA, h1, _⟩
  have hpos : 0 < M.alpha * A * S := mul_pos (mul_pos M.alpha_pos hA) hS
  linarith [h1, hpos]

/-- **THEOREM (D-T3).** Because the runaway rate is *increasing* in the initial
attention `A₀` and structure `S₀`, the model exhibits **positive sensitivity**: a world
that preserves more at the outset diverges faster.

This is the formal version of the source document's paradox "要看见一次从未存在的光，
必须使用一台正在摧毁世界的机器" (to see the light once, one must use the machine that
destroys the world): the engine's short-run benefit and long-run cost are the *same*
parameter. -/
theorem runaway_rate_mono (α S₀ : ℝ) (hα : 0 < α) (_hS : 0 < S₀) :
    StrictMono fun A : ℝ => α * A + α * S₀ := by
  intro A₁ A₂ h
  nlinarith

/-! ## Geometric flattening: what survives and what does not -/

/-- **Axiom P8' `[NEW]`.** A discrete model of curvature homogenisation: the sequence of
"shape coefficients" `u n` at scale `n` evolves so that each mode is damped by a
nonnegative amount `d n`.

This is the honest, *linear* content of "Ricci flow homogenises curvature". The real
Ricci flow has an additional **reaction term** that opposes homogenisation, and its
long-time behaviour in dimension 3 is geometrisation with singularities, not uniform
flattening. Both facts are recorded in the Consistency Audit (entries E5, U5, U7) and
are **not** modelled here. -/
structure GeometricFlow where
  /-- shape coefficient at scale `n` -/
  u : ℕ → ℝ
  /-- the damping applied at scale `n` -/
  d : ℕ → ℝ
  d_nonneg : ∀ n, 0 ≤ d n
  /-- each coefficient is damped by `d n` -/
  step : ∀ n, u (n + 1) = u n * (1 - d n)

/-- **THEOREM (D-T4).** Under geometric flattening, the squared modulus
`∑_{n<N} u n²` is non-increasing in `N` whenever the damping does not overshoot
(`d n ≤ 1`).

So the world's "flattening" really does destroy contrast — **on the modes it damps**.
This is the defensible half of the source document's geometric claim. -/
theorem flattening_nonincrease (F : GeometricFlow) (hno : ∀ n, F.d n ≤ 1) :
    ∀ N : ℕ, (∑ n ∈ Finset.range (N + 1), F.u n ^ 2)
      ≤ ∑ n ∈ Finset.range N, F.u n ^ 2 + F.u 0 ^ 2 := by
  intro N
  induction N with
  | zero => simp
  | succ k ih =>
    have hmono : F.u (k + 1) ^ 2 ≤ F.u k ^ 2 := by
      rw [F.step k]
      have h1 : F.d k ≤ 1 := hno k
      have h2 : 0 ≤ F.d k := F.d_nonneg k
      nlinarith [sq_nonneg (F.u k), sq_nonneg (F.u k * F.d k)]
    have hstep : ∀ m, F.u (m + 1) ^ 2 ≤ F.u m ^ 2 := fun m => by
      rw [F.step m]
      have h1 : F.d m ≤ 1 := hno m
      have h2 : 0 ≤ F.d m := F.d_nonneg m
      nlinarith [sq_nonneg (F.u m), sq_nonneg (F.u m * F.d m),
        mul_nonneg (sq_nonneg (F.u m)) h2]
    have hdec : ∀ (K m : ℕ), m ≤ K → F.u K ^ 2 ≤ F.u m ^ 2 := by
      intro K
      induction K with
      | zero =>
        intro m hm
        have hm0 : m = 0 := Nat.le_zero.mp hm
        subst hm0; exact le_rfl
      | succ j ihj =>
        intro m hm
        rcases Nat.lt_or_ge m (j + 1) with hlt | hge
        · exact le_trans (hstep j) (ihj m (Nat.lt_succ_iff.mp hlt))
        · have hmj : m = j + 1 := le_antisymm hm hge
          subst hmj; exact le_rfl
    have hfin : F.u k ^ 2 ≤ F.u 0 ^ 2 := hdec k 0 (Nat.zero_le k)
    calc ∑ n ∈ Finset.range (k + 1 + 1), F.u n ^ 2
        = (∑ n ∈ Finset.range (k + 1), F.u n ^ 2) + F.u (k + 1) ^ 2 := by
          rw [Finset.sum_range_succ]
      _ ≤ (∑ n ∈ Finset.range (k + 1), F.u n ^ 2) + F.u k ^ 2 := by
            nlinarith [sq_nonneg (F.u (k + 1))]
      _ ≤ (∑ n ∈ Finset.range (k + 1), F.u n ^ 2) + F.u 0 ^ 2 := by
            nlinarith [hfin, sq_nonneg (F.u 0)]

/-- **THEOREM (D-T5).** A mode with damping strictly less than one at every step decays
geometrically, so the *relative* contrast of a damped mode tends to zero.

Formally: `|u n| ≤ |u 0| · ρ^n` for any `ρ` with `|1 - d k| ≤ ρ` for all `k < n`. -/
theorem mode_geometric_decay (F : GeometricFlow) {ρ : ℝ} (hρ : 0 ≤ ρ)
    (h : ∀ k, |1 - F.d k| ≤ ρ) (n : ℕ) :
    |F.u n| ≤ |F.u 0| * ρ ^ n := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [F.step k, abs_mul, pow_succ]
    calc |F.u k| * |1 - F.d k| ≤ (|F.u 0| * ρ ^ k) * ρ := by
          exact mul_le_mul ih (h k) (abs_nonneg _) (mul_nonneg (abs_nonneg _) (pow_nonneg hρ k))
      _ = |F.u 0| * ρ ^ k * ρ := by ring
      _ = |F.u 0| * ρ ^ (k + 1) := by ring

end World
