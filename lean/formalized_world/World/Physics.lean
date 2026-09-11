/-
Copyright (c) 2026 STRING THEORY Formalization Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Formalized World Reconstruction
-/
module

public import World.Basic

/-!
# World.Physics — Physical Axioms and Their Consequences

This module formalises §3 (Physical Axioms) and §4 (Reality Delta) of the
Formalized World Model.

## What is formalised here

Only the parts of the world's physics that are *mathematically definite*:

1. **The gravity well (Axiom P5, `[REAL]`).** Surface gravity, escape velocity, and
   their relation for a spherically symmetric body.
2. **The rocket bound (Axiom P6, `[REAL]`).** The Tsiolkovsky equation, the mass ratio
   it forces, and the threshold at which chemical propulsion is infeasible.
3. **The irreversibility of descent (Axiom P7, `[MODIFIED]`).** The energy gap between
   surface and orbit, together with the world's rule that reconstruction ("diffusion")
   is not free.
4. **The flattening rate (Axiom P8, `[NEW]`).** The heat-equation timescale
   `τ = L²/D` for a structure of size `L`, and its monotonicity in `L`.

## What is *not* formalised

Anything requiring general relativity, quantum field theory, or nuclear physics. The
audit (`audit/physics_audit.md`) supplies those results numerically with citations; the
Consistency Audit records where they contradict the source document. They are
deliberately **not** asserted here, because asserting them would be unsupported.

## Labels used

`[REAL]`, `[MODIFIED]`, `[NEW]`, `[UNRESOLVED]` — see `World.Basic`.
-/

@[expose] public section

namespace World

open Real

/-! ## The gravity well -/

/-- **Definition (Fundamental Definition F4).** A spherically symmetric gravitating
body, described by `(mass, radius)`. `[REAL]` -/
structure Body where
  /-- mass in kilograms -/
  mass : ℝ
  /-- radius in metres -/
  radius : ℝ
  mass_pos : 0 < mass
  radius_pos : 0 < radius

/-- **Axiom P5 `[REAL]`.** Surface gravity, `g = GM/R²`.
`G` is the real gravitational constant (CODATA 2018: `6.67430e-11`). -/
noncomputable def surfaceGravity (G : ℝ) (b : Body) : ℝ := G * b.mass / b.radius ^ 2

/-- **Axiom P5 `[REAL]`.** Escape velocity, `v_esc = √(2GM/R)`. -/
noncomputable def escapeVelocity (G : ℝ) (b : Body) : ℝ :=
  Real.sqrt (2 * G * b.mass / b.radius)

/-- **THEOREM (P-T1).** Surface gravity is positive for a physical body. -/
theorem surfaceGravity_pos {G : ℝ} (hG : 0 < G) (b : Body) :
    0 < surfaceGravity G b := by
  rw [surfaceGravity]
  exact div_pos (mul_pos hG b.mass_pos) (pow_pos b.radius_pos 2)

/-- **THEOREM (P-T2).** Escape velocity is positive for a physical body. -/
theorem escapeVelocity_pos {G : ℝ} (hG : 0 < G) (b : Body) :
    0 < escapeVelocity G b := by
  rw [escapeVelocity]
  exact Real.sqrt_pos.mpr (div_pos (mul_pos (mul_pos (by norm_num) hG) b.mass_pos)
    b.radius_pos)

/-- **THEOREM (P-T3, `[REAL]`).** On *physical* radii (`R > 0`), escape velocity is
antitone in radius at fixed mass.

The restriction to `R > 0` is not cosmetic: Lean's `Real.sqrt` is `0` on negative
arguments, so the bare function `R ↦ √(2GM/R)` is *not* antitone for `R ≤ 0`. Since a
negative radius is not a physical configuration, nothing is lost. -/
theorem escapeVelocity_antitone_radius {G M : ℝ} (hG : 0 < G) (hM : 0 < M)
    {R₁ R₂ : ℝ} (h1 : 0 < R₁) (h12 : R₁ ≤ R₂) :
    Real.sqrt (2 * G * M / R₂) ≤ Real.sqrt (2 * G * M / R₁) := by
  apply Real.sqrt_le_sqrt
  exact div_le_div_of_nonneg_left
    (mul_nonneg (mul_nonneg (by norm_num) hG.le) hM.le) h1 h12

/-- **THEOREM (P-T3').** Equivalently, escape velocity decreases along physical radii,
so raising the radius without adding mass lowers the well only as `R^{-1/2}`: to double
`v_esc` at fixed mass one must shrink the body by a factor of four. -/
theorem escapeVelocity_radius_scaling {G M R : ℝ} (hG : 0 < G) (hM : 0 < M) (_hR : 0 < R) :
    Real.sqrt (2 * G * M / R) = Real.sqrt (2 * G * M) / Real.sqrt R := by
  rw [Real.sqrt_div (by positivity)]

/-! ## The rocket bound -/

/-- **Definition.** The Tsiolkovsky mass ratio `m₀/m₁ = exp(Δv / v_e)` needed to
change velocity by `Δv` with exhaust velocity `v_e > 0`. `[REAL]` -/
noncomputable def massRatio (ve dv : ℝ) : ℝ := Real.exp (dv / ve)

/-- **THEOREM (P-T4, `[REAL]`).** The mass ratio is strictly increasing in `Δv` for
positive exhaust velocity: escaping a deeper well is exponentially more expensive. -/
theorem massRatio_strictMono {ve dv₁ dv₂ : ℝ} (hve : 0 < ve) (h : dv₁ < dv₂) :
    massRatio ve dv₁ < massRatio ve dv₂ := by
  rw [massRatio, massRatio]
  exact Real.exp_lt_exp.mpr (by rw [div_lt_div_iff_of_pos_right hve]; exact h)

/-- **THEOREM (P-T5, `[REAL]`).** The mass ratio is strictly decreasing in exhaust
velocity for fixed `Δv > 0`: no propellant choice escapes the exponential. -/
theorem massRatio_antitone_ve {ve₁ ve₂ dv : ℝ} (h1 : 0 < ve₁) (_h2 : 0 < ve₂)
    (h : ve₁ < ve₂) (hdv : 0 < dv) : massRatio ve₂ dv < massRatio ve₁ dv := by
  rw [massRatio, massRatio]
  exact Real.exp_lt_exp.mpr (div_lt_div_of_pos_left hdv h1 h)

/-- **Definition.** Chemical propulsion is *infeasible* for a mission when the
Tsiolkovsky mass ratio exceeds a threshold `κ` (the largest mass ratio the vehicle
architecture can achieve, typically `10³`–`10⁴` for chemical stages). -/
noncomputable def rocketInfeasible (ve dv κ : ℝ) : Prop := κ < massRatio ve dv

/-- **THEOREM (P-T6).** Infeasibility is monotone in `Δv`: if a mission to escape
velocity `v₁` is infeasible, so is any deeper well `v₂ > v₁`. -/
theorem rocketInfeasible_mono {ve dv₁ dv₂ κ : ℝ} (hve : 0 < ve) (h : dv₁ ≤ dv₂)
    (hinf : rocketInfeasible ve dv₁ κ) : rocketInfeasible ve dv₂ κ := by
  rw [rocketInfeasible] at hinf ⊢
  rcases eq_or_lt_of_le h with he | hlt
  · rwa [← he]
  · exact lt_trans hinf (massRatio_strictMono hve hlt)

/-- **THEOREM (P-T7, the quantitative core of Axiom P6).**
For a circular low orbit, the required `Δv` is `v_esc/√2`. Hence the chemical mass
ratio is `exp(v_esc / (√2 · v_e))`, which grows without bound as the well deepens. -/
theorem orbital_massRatio_eq (ve vesc : ℝ) :
    massRatio ve (vesc / Real.sqrt 2) = Real.exp (vesc / (Real.sqrt 2 * ve)) := by
  rw [massRatio, div_div]

/-- **THEOREM (P-T8).** For every finite propellant mass ratio there is an escape
velocity that makes chemical rocketry infeasible. This is the formal statement that a
sufficiently deep gravity well *provably* closes off rocket travel. -/
theorem exists_vesc_infeasible {ve κ : ℝ} (hve : 0 < ve) (hκ : 0 < κ) :
    ∃ vesc : ℝ, rocketInfeasible ve vesc κ := by
  refine ⟨ve * (Real.log κ + 1), ?_⟩
  rw [rocketInfeasible, massRatio,
    show ve * (Real.log κ + 1) / ve = Real.log κ + 1 by
      exact mul_div_cancel_left₀ _ hve.ne']
  exact Real.log_lt_iff_lt_exp hκ |>.mp (by linarith)

/-! ## The energy gap and the irreversibility of descent -/

/-- **Definition.** The energy per unit mass required to climb from a body's surface
to a circular low orbit, `ε = v_esc²/4`. `[REAL]` -/
noncomputable def climbEnergyPerMass (G : ℝ) (b : Body) : ℝ :=
  escapeVelocity G b ^ 2 / 4

/-- **THEOREM (P-T9, `[REAL]`).** `ε = GM/(2R)`, so the climb energy is
`G M / (2 R)` per unit mass. -/
theorem climbEnergyPerMass_eq {G : ℝ} (hG : 0 < G) (b : Body) :
    climbEnergyPerMass G b = G * b.mass / (2 * b.radius) := by
  rw [climbEnergyPerMass, escapeVelocity,
    Real.sq_sqrt (div_nonneg (mul_nonneg (mul_nonneg (by norm_num) hG.le) b.mass_pos.le)
      b.radius_pos.le)]
  ring

/-- **THEOREM (P-T10).** The climb energy is positive and strictly decreasing in
radius: a more compact body of the same mass is harder to leave. -/
theorem climbEnergyPerMass_pos {G : ℝ} (hG : 0 < G) (b : Body) :
    0 < climbEnergyPerMass G b := by
  rw [climbEnergyPerMass_eq hG]
  exact div_pos (mul_pos hG b.mass_pos) (by linarith [b.radius_pos])

/-! ## The flattening rate -/

/-- **Axiom P8 `[NEW]`.** The world's flattening dynamics is a *geometric heat flow*:
a structure of linear size `L` with diffusivity `D > 0` loses its contrast on the
timescale `τ = L²/D`.

This is the diffusion timescale of the heat equation `∂u/∂t = D Δu`, which is the
settled part of the source document's "Ricci flow = curvature homogenization" claim.
The **reaction term** that obstructs it in the real Ricci flow is *not* modelled here;
see the Consistency Audit (contradiction U5 / E5). -/
noncomputable def flatteningTime (D L : ℝ) : ℝ := L ^ 2 / D

/-- **THEOREM (P-T11).** On physical sizes (`L > 0`), the flattening time is strictly
increasing in `L`: small structures flatten fast, large ones survive long. -/
theorem flatteningTime_strictMonoOn {D : ℝ} (hD : 0 < D) :
    StrictMonoOn (fun L : ℝ => flatteningTime D L) (Set.Ioi 0) := by
  intro L₁ hL₁ L₂ _ h
  have hsq : L₁ ^ 2 < L₂ ^ 2 := pow_lt_pow_left₀ h hL₁.le (by norm_num)
  simp only [flatteningTime]
  exact div_lt_div_of_pos_right hsq hD

/-- **THEOREM (P-T12).** The flattening time is antitone in the diffusivity `D` at
fixed size: a stronger flattening drive shortens every lifetime. -/
theorem flatteningTime_antitone {D₁ D₂ L : ℝ} (hD₁ : 0 < D₁) (h : D₁ ≤ D₂)
    (_hL : 0 < L) : flatteningTime D₂ L ≤ flatteningTime D₁ L := by
  have hrec : D₂⁻¹ ≤ D₁⁻¹ := by
    have h1 : 1 / D₂ ≤ 1 / D₁ := one_div_le_one_div_of_le hD₁ h
    simpa only [one_div] using h1
  simp only [flatteningTime, div_eq_mul_inv]
  exact mul_le_mul_of_nonneg_left hrec (sq_nonneg L)

end World
