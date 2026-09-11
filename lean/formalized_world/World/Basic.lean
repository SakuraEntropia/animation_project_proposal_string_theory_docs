/-
Copyright (c) 2026 STRING THEORY Formalization Project. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Formalized World Reconstruction
-/
module

public import Mathlib

/-!
# World.Basic — Ontology and Fundamental Definitions

This module fixes the *ontological primitives* of the reconstructed world model
(`STRING THEORY`, Formalized World Model, revision 1).

The guiding methodological rule of this project is that every object introduced here
must be labelled as exactly one of:

* **Primitive** — a bare type; nothing is assumed about its internal structure.
* **Derived** — a definition built out of primitives.
* **Real** — the object coincides with its real-physics counterpart.
* **Modified** — the object exists in real physics but its governing law is altered.
* **New** — the object has no real-physics counterpart.

Nothing in this file asserts anything about the world; it only *names* things.
All substantive claims live in `World.Physics` and later modules.
-/

@[expose] public section

namespace World

open Finset Real

/-- **Primitive (Ontology O1).** Time, ordered. We carry only the linear order of `ℝ`
(no metric, no topology); metric time is introduced later in `World.Physics`. -/
abbrev Time : Type := ℝ

/-- **Primitive (Ontology O2).** Space, as a bare type. The world's spatial *geometry*
is a separate structure (`Geometry`), introduced in `World.Physics`; the point set itself
is left abstract so that the model does not presuppose a particular dimension. -/
abbrev Space : Type := ℝ

/-- **Derived (Ontology O6).** A probability weight on a finite microstate set.
This is the *only* representation of a statistical state used in the formal core.
The constraint `sum = 1` is part of the structure, so that every theorem below
can be stated without repeating normalisation hypotheses. -/
structure ProbDist (ι : Type*) [Fintype ι] where
  /-- the weight assigned to each microstate -/
  w : ι → ℝ
  /-- weights are nonnegative -/
  nonneg : ∀ i, 0 ≤ w i
  /-- weights sum to one -/
  sum_eq_one : ∑ i, w i = 1

namespace ProbDist

variable {ι : Type*} [Fintype ι]

/-- Every weight is at most 1. -/
theorem le_one (p : ProbDist ι) (i : ι) : p.w i ≤ 1 := by
  have h' : p.w i ≤ ∑ j, p.w j :=
    Finset.single_le_sum (fun j _ => p.nonneg j) (Finset.mem_univ i)
  linarith [p.sum_eq_one]

/-- A probability distribution on a nonempty type has a positive weight somewhere. -/
theorem exists_pos (p : ProbDist ι) [Nonempty ι] : ∃ i, 0 < p.w i := by
  by_contra h
  push Not at h
  have hz : ∀ i, p.w i = 0 := fun i => le_antisymm (h i) (p.nonneg i)
  have : ∑ i, p.w i = 0 := Finset.sum_eq_zero fun i _ => hz i
  rw [p.sum_eq_one] at this
  exact one_ne_zero this

/-- Each weight is at most the total mass. -/
theorem le_sum (p : ProbDist ι) (i : ι) : p.w i ≤ ∑ j, p.w j :=
  Finset.single_le_sum (fun j _ => p.nonneg j) (Finset.mem_univ i)

/-- If one weight carries the whole mass, all other weights vanish. -/
theorem eq_zero_of_ne_of_sum_eq (p : ProbDist ι) {i j : ι} (hij : i ≠ j)
    (hi : p.w i = 1) : p.w j = 0 := by
  classical
  have hsplit : p.w j + ∑ k ∈ Finset.univ.erase j, p.w k = ∑ k, p.w k :=
    Finset.add_sum_erase _ _ (Finset.mem_univ j)
  have hmem : i ∈ Finset.univ.erase j := Finset.mem_erase.mpr ⟨hij, Finset.mem_univ i⟩
  have hle_total : p.w i ≤ ∑ k ∈ Finset.univ.erase j, p.w k :=
    Finset.single_le_sum (fun k _ => p.nonneg k) hmem
  -- `p.w i ≤ tail` and `p.w i = 1`, so `tail ≥ 1`; and `p.w j + tail = 1`, so `p.w j ≤ 0`.
  rw [hi] at hle_total
  linarith [p.nonneg j, hsplit, hle_total, p.sum_eq_one]

/-- **The uniform distribution.** Real physics: the microcanonical ensemble.
This is the world model's description of the *flattened* state. -/
noncomputable def uniform (ι : Type*) [Fintype ι] [Nonempty ι] : ProbDist ι where
  w := fun _ => (Fintype.card ι : ℝ)⁻¹
  nonneg := fun _ => by positivity
  sum_eq_one := by
    rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul]
    have h : (Fintype.card ι : ℝ) ≠ 0 := by
      exact_mod_cast Fintype.card_ne_zero
    field_simp

@[simp] theorem uniform_w (ι : Type*) [Fintype ι] [Nonempty ι] (i : ι) :
    (uniform ι).w i = (Fintype.card ι : ℝ)⁻¹ := rfl

end ProbDist

/-- **Primitive (Ontology O3).** The total energy of a configuration. Real physics.
Introduced here as a bare real number because the world model treats energy as an
extensive scalar rather than as a component of a stress tensor. This is the first
place where the model is *less* general than real physics; see the README note N1. -/
abbrev Energy : Type := ℝ

/-- **Primitive (Ontology O4).** Temperature. Real physics. -/
abbrev Temperature : Type := ℝ

/-- **Derived.** A *thermodynamic state*: the data needed to evaluate entropy,
free energy, and available work for a finite ensemble. -/
structure ThermoState (ι : Type*) [Fintype ι] where
  /-- the statistical state -/
  p : ProbDist ι
  /-- mean energy of the ensemble -/
  U : ℝ
  /-- absolute temperature of the surrounding bath -/
  T : ℝ
  /-- temperature is positive -/
  T_pos : 0 < T

/-- **Derived (Ontology O8).** An *observer*: a subsystem that carries a record.
In real physics an observer is not a primitive — it is a physical subsystem that
correlates with its environment. The world model *does* make it primitive, because
the attention axiom (A3) refers to it. See `World.Physics` for the consequences. -/
structure Observer where
  /-- the microstate set of the observer's internal degrees of freedom -/
  carrier : Type
  [fintype : Fintype carrier]
  /-- the observer's memory content -/
  memory : ProbDist carrier

attribute [instance] Observer.fintype

end World
