/-
Copyright (c) 2021 . All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import group_theory.group_action.basic
/-!
# Conjugation action of a group on itself
This file defines the conjugation action of a group on itself

## Main definitions
A type alias `conj G` is introduced for a group `G`. The group `conj G` acts on `G` by conjugation.

-/

variables (G : Type*) [group G]

/-- A type alias for a group `G`. `conj G` acts on `G` by conjugation -/
@[derive group] def conj : Type* := G

namespace conj
open mul_action subgroup

variable {G}

def to_conj : G → conj G := id

def of_conj : conj G → G := id

@[simp] lemma to_conj_of_conj (x : conj G) : to_conj (of_conj x) = x := rfl
@[simp] lemma of_conj_to_conj (x : G) : of_conj (to_conj x) = x := rfl
@[simp] lemma of_conj_one : of_conj (1 : conj G) = 1 := rfl
@[simp] lemma to_conj_one : to_conj (1 : G) = 1 := rfl
@[simp] lemma of_conj_inv (x : conj G) : of_conj (x⁻¹) = (of_conj x)⁻¹ := rfl
@[simp] lemma to_conj_inv (x : G) : to_conj (x⁻¹) = (to_conj x)⁻¹ := rfl
@[simp] lemma of_conj_mul (x y : conj G) : of_conj (x * y) = of_conj x * of_conj y := rfl
@[simp] lemma to_conj_mul (x y : G) : to_conj (x * y) = to_conj x * to_conj y := rfl

instance : mul_action (conj G) G :=
{ smul := λ g h, of_conj g * h * (of_conj g)⁻¹,
  one_smul := by simp,
  mul_smul := by simp [mul_assoc] }

lemma smul_def (g : conj G) (h : G) : g • h = of_conj g * h * (of_conj g)⁻¹ := rfl

/-- `G` is isomorphic as a group to `conj G` -/
@[simps] def mul_equiv : conj G ≃* G :=
{ to_fun := of_conj,
  inv_fun := to_conj,
  left_inv := λ _, rfl,
  right_inv := λ _, rfl,
  map_mul' := λ _ _, rfl }

instance : Π [fintype G], fintype (conj G) := id

@[simp] lemma card [fintype G] : fintype.card (conj G) = fintype.card G := rfl

/-- The set of fixed points of the conjugation action of `G` on itself is the center of `G`. -/
lemma fixed_points_eq_center : fixed_points (conj G) G = center G :=
begin
  ext x,
  simp only [mem_center_iff, smul_def, mul_inv_eq_iff_eq_mul, set_like.mem_coe, mem_fixed_points],
  refl
end

end conj
