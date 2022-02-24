/-
Copyright (c) 2022 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jujian Zhang
-/

import topology.sheaves.presheaf
import topology.sheaves.sheaf
import algebra.category.CommRing.basic
import algebra.module.restriction_of_scalars

noncomputable theory

open Top topological_space opposite category_theory change_of_rings
open_locale tensor_product change_of_rings

namespace presheaf_of_module

section defs
variables {X : Top} (𝓞 : presheaf CommRing X)

/--
A presheaf of module over `𝓞 : presheaf CommRing X` is a presheaf of abelian group `𝓕` such that
`𝓕(U)` is an `𝓞(U)`-module for all `U : opens X` and the restriction map is linear.

We split the condition on restriction map to another definition because we want to use the module
instances as early as possible.
-/

@[nolint has_inhabited_instance]
structure core :=
(self : presheaf Ab X)
[is_module : ∀ (U : opens X), module (𝓞.obj (op U)) (self.obj (op U))]

attribute [instance] core.is_module

/--
For presheaf of abelian group `𝓕`, `𝓕(U)` is an `𝓞(V)`-module for all `V ⊆ U : opens X` via
restriction map of ring.
-/
def is_module_UV (𝓜 : presheaf_of_module.core 𝓞) {U V : opens X} (inc : op U ⟶ op V) :
  module (𝓞.obj (op U)) (𝓜.self.obj (op V)) :=
restriction_of_scalars.is_module (𝓞.map inc) ⟨𝓜.self.obj (op V)⟩
local attribute [instance] is_module_UV

/--
For presheaf of abelian group `𝓕`, `𝓕(U)` is an `𝓞(V)`-module for all `V ⊆ U : opens X` via
restriction map of ring. Explicitly, `r • m = ρ(r) • m` where `r : 𝓞(U)`, `m : 𝓕(V)` and `ρ` is
the restriction map `𝓞(U) ⟶ 𝓞(V)`
-/
def has_scalar_UV (𝓜 : presheaf_of_module.core 𝓞) {U V : opens X} (inc : op U ⟶ op V) :
  has_scalar (𝓞.obj (op U)) (𝓜.self.obj (op V)) :=
let m1 := is_module_UV 𝓞 𝓜 inc in by { resetI, apply_instance }
-- @restriction_of_scalars.has_scalar (𝓞.obj (op U)) (𝓞.obj (op V)) ⟨𝓜.self.obj (op V)⟩ (𝓞.map inc)
local attribute [instance] has_scalar_UV

/--
The compatibility of scalar multiplication states that `ρₘ (r • m) = ρᵣ r • ρₘ m` where `ρₘ` is
restriction map of `𝓕` and `ρᵣ` is restriction map of `𝓞`.
-/
@[nolint has_inhabited_instance]
structure _root_.presheaf_of_module extends presheaf_of_module.core 𝓞 :=
(compatible : ∀ {U V : opens X} (inc : op U ⟶ op V) (r : 𝓞.obj (op U)) (m : self.obj (op U)),
  self.map inc (r • m) = 𝓞.map inc r • self.map inc m)

variable {𝓞}
lemma is_linear_map (𝓕 : presheaf_of_module 𝓞) {U V : opens X} (inc : op U ⟶ op V) :
  @@is_linear_map (𝓞.obj (op U)) _ _ _ _ (is_module_UV 𝓞 _ inc) (𝓕.self.map inc) :=
{ map_add := map_add _,
  map_smul := 𝓕.compatible inc }

/--
Since scalar multiplication is compatible with restriction, the restriction map of `𝓕` is actually
a linear map.
-/
def to_linear_map (𝓕 : presheaf_of_module 𝓞) {U V : opens X} (inc : op U ⟶ op V) :
  (⟨𝓕.self.obj (op U)⟩ : Module (𝓞.obj (op U))) ⟶
  ({ carrier := 𝓕.self.obj (op V), is_module := is_module_UV 𝓞 _ inc } : Module (𝓞.obj (op U))) :=
{ to_fun := 𝓕.self.map inc,
  map_add' := by simp,
  map_smul' := 𝓕.compatible inc }

/--
A morhpism `φ` between two presheaf of modules `𝓕1` and `𝓕2` is a morphism between presheaf of
abelian groups such that `φ (r • m) = r • φ m`.
-/
@[nolint has_inhabited_instance, ext] structure morphism (𝓕1 𝓕2 : presheaf_of_module 𝓞) :=
(to_fun : 𝓕1.self ⟶ 𝓕2.self)
(compatible : ∀ {U : opens X} (r : 𝓞.obj (op U)) (m : 𝓕1.self.obj (op U)),
  to_fun.app (op U) (r • m) = r • to_fun.app (op U) m )

lemma morphism.is_linear {𝓕1 𝓕2 : presheaf_of_module 𝓞} (φ : morphism 𝓕1 𝓕2)
  {U} :
  _root_.is_linear_map (𝓞.obj (op U)) (φ.to_fun.app (op U)) :=
{ map_add := map_add _,
  map_smul := morphism.compatible _ }

/--
The composition of two morphisms between presheaf of modules is the composition of two morphisms as
morphisms between presheaf of abelian group.
-/
def morphism.comp {𝓕1 𝓕2 𝓕3 : presheaf_of_module 𝓞}
  (f12 : morphism 𝓕1 𝓕2) (f23 : morphism 𝓕2 𝓕3) : morphism 𝓕1 𝓕3 :=
{ to_fun := f12.to_fun ≫ f23.to_fun,
  compatible := λ U r m, begin
    simp only [nat_trans.comp_app, comp_apply, f12.compatible, f23.compatible],
  end }

lemma morphism.comp_to_fun {𝓕1 𝓕2 𝓕3 : presheaf_of_module 𝓞}
  (f12 : morphism 𝓕1 𝓕2) (f23 : morphism 𝓕2 𝓕3) :
  (morphism.comp f12 f23).to_fun = f12.to_fun ≫ f23.to_fun := rfl

/--
The identity morphism of presheaf of module is identity morphism of presheaf of abelian group.
-/
def morphism.id (𝓕 : presheaf_of_module 𝓞) : morphism 𝓕 𝓕 :=
{ to_fun := 𝟙 _,
  compatible := λ U r m, begin
    simp only [nat_trans.id_app, id_apply],
  end }

instance : category (presheaf_of_module 𝓞) :=
{ hom := morphism,
  id := morphism.id,
  comp := λ _ _ _ f12 f23, morphism.comp f12 f23,
  id_comp' := λ _ _ _, begin
    ext U_op x,
    simpa [morphism.comp_to_fun, comp_app],
  end,
  comp_id' := λ _ _ _, begin
    ext U_op x,
    simpa [morphism.comp_to_fun, comp_app],
  end,
  assoc' := λ _ _ _ _ _ _ _, begin
    ext U_op x,
    simp [morphism.comp_to_fun, comp_app],
  end }.

variable (𝓞)
/--
A sheaf of modules is a presheaf of module such that the underlying presheaf of abelian group is a
sheaf.
-/
@[nolint has_inhabited_instance]
structure _root_.sheaf_of_module extends _root_.presheaf_of_module 𝓞 :=
(is_sheaf : presheaf.is_sheaf self)

instance : category (sheaf_of_module 𝓞) :=
{ hom := λ 𝓕1 𝓕2, morphism 𝓕1.1 𝓕2.1,
  id := λ _, morphism.id _,
  comp := λ _ _ _ f12 f23, morphism.comp f12 f23,
  id_comp' := λ _ _ _, begin
    ext U_op x,
    simpa [morphism.comp_to_fun, comp_app],
  end,
  comp_id' := λ _ _ _, begin
    ext U_op x,
    simpa [morphism.comp_to_fun, comp_app],
  end,
  assoc' := λ _ _ _ _ _ _ _, begin
    ext U_op x,
    simp [morphism.comp_to_fun, comp_app],
  end }

end defs

section restriction

variables {X : Top} {𝓞1 𝓞2 : presheaf CommRing X} (f : 𝓞1 ⟶ 𝓞2)
include f

/--
Given two presheaf of ring `𝓞1` and `𝓞2`, a morphsim `f : 𝓞1 ⟶ 𝓞2` and a presheaf of modules
`𝓕` over `𝓞2`, there is a presheaf of modules over `𝓞1`. This is `𝓕` restricted by `f`, denoted
as `f ^* 𝓕`.
-/
def restriction_by.obj (𝓕 : presheaf_of_module 𝓞2) : presheaf_of_module 𝓞1 :=
{ self := 𝓕.self,
  is_module := λ U, restriction_of_scalars.is_module (f.app (op U)) ⟨𝓕.self.obj (op U)⟩,
  compatible := λ U V inc r m, begin
    erw [𝓕.compatible inc, (ring_hom.congr_fun (f.naturality inc) r).symm],
    refl,
  end }

local notation f `^*` 𝓕 := restriction_by.obj f 𝓕

/--
Restricting presheaf of modules by `f` is functorial.
-/
def restriction_by.map {𝓕1 𝓕2 : presheaf_of_module 𝓞2} (φ : 𝓕1 ⟶ 𝓕2) :
  (f^*𝓕1) ⟶ (f^*𝓕2) :=
{ to_fun := φ.to_fun,
  compatible := λ U r m, begin
    erw [φ.compatible],
    refl,
  end }
local notation f `^*→` φ := restriction_by.map f φ

/--
Restricting presheaf of modules by `f` is functorial.
-/
def restriction_by.functor : presheaf_of_module 𝓞2 ⥤ presheaf_of_module 𝓞1 :=
{ obj := λ 𝓕, f ^* 𝓕,
  map := λ _ _ φ, f ^*→ φ,
  map_id' := λ _, rfl,
  map_comp' := λ _ _ _ _ _, rfl }

end restriction

section extension

variables {X : Top} {𝓞1 𝓞2 : presheaf CommRing X} (f : 𝓞1 ⟶ 𝓞2)
include f

variable (𝓕 : presheaf_of_module 𝓞1)
include 𝓕

private def restrict.to_fun (U V : opens X) (inc : op U ⟶ op V) :
  ((f.app (op U)) _* ⟨(𝓕.self.obj (op U))⟩) →
  ((f.app (op V)) _* ⟨(𝓕.self.obj (op V))⟩) :=
let im1 : module (𝓞1.obj (op U)) (𝓕.self.obj (op U)) := 𝓕.is_module _,
    im2 : module (𝓞1.obj (op U)) (𝓞2.obj (op U)) := restriction_of_scalars.is_module
      (f.app (op U)) ⟨𝓞2.obj (op U)⟩,
    im4 : module (𝓞1.obj (op U)) (𝓕.self.obj (op V)) := is_module_UV _ _ inc,
    im3 := restriction_of_scalars.is_module (f.app (op U) ≫ 𝓞2.map inc)
      (f.app (op V)_* ⟨𝓕.to_core.self.obj (op V)⟩),
    im4 : module (𝓞1.obj (op V)) (𝓞2.obj (op V)) := restriction_of_scalars.is_module
      (f.app (op V)) ⟨𝓞2.obj (op V)⟩,
    im5 : module (𝓞1.obj (op U))
      ((𝓕.self.obj (op V)) ⊗[𝓞1.obj (op V), f.app (op V)] (𝓞2.obj (op V))) :=
      restriction_of_scalars.is_module (𝓞1.map inc)
      { carrier := ((𝓕.self.obj (op V)) ⊗[𝓞1.obj (op V), f.app (op V)] (𝓞2.obj (op V))),
        is_module := extension_of_scalars.is_module' (f.app (op V)) ⟨(𝓕.self.obj (op V))⟩ } in
begin
  resetI,
  refine tensor_product.lift _,
  refine
    { to_fun := λ m, { to_fun := λ s, _, map_add' := _, map_smul' := _ },
      map_add' := _,
      map_smul' := _ },
    { exact (𝓕.self.map inc m) ⊗ₜ[𝓞1.obj (op V), f.app (op V)] (𝓞2.map inc s), },
    { intros s1 s2,
      rw [map_add, tensor_product.tmul_add], },
    { intros r s,
      rw [restriction_of_scalars.smul_def (f.app (op U)) ⟨𝓞2.obj (op U)⟩ r s, ring_hom.id_apply,
        smul_eq_mul, ring_hom.map_mul, ←smul_eq_mul],
      convert extension_of_scalars.smul_pure_tensor (f.app (op V)) _ _ _ _, },
    { intros m1 m2,
        ext z,
        simp only [map_add, tensor_product.add_tmul, linear_map.coe_mk, linear_map.add_apply], },
    { intros r x,
      ext z,
      simp only [𝓕.compatible, ring_hom.id_apply, linear_map.coe_mk, linear_map.smul_apply],
      rw tensor_product.smul_tmul,
      erw extension_of_scalars.smul_pure_tensor,
      congr' 1,
      rwa ← f.naturality,
      refl },
end


/--
For all opens `V ⊆ U`, there is a linear map `𝓕(U) ⊗[𝓞1(U)] 𝓞2(U) ⟶ 𝓕(V) ⊗[𝓞1(V)] 𝓞2(U)`
given by `x ⊗ y ↦ ρₘ x ⊗ ρ₂ y` where `ρₘ` is restriction map of `𝓕` and `ρ₂` is restriction map
of `𝓞2`.
-/
def restrict (U V : opens X) (inc : op U ⟶ op V) :
  linear_map (𝓞2.map inc) (extension_of_scalars.module (f.app (op U)) ⟨(𝓕.self.obj (op U))⟩)
    (extension_of_scalars.module (f.app (op V)) ⟨(𝓕.self.obj (op V))⟩) :=
{ to_fun := restrict.to_fun f 𝓕 U V inc,
  map_add' := by simp [restrict.to_fun],
  map_smul' := λ r m, begin
    induction m using tensor_product.induction_on with m s x y ih1 ih2,
    { simp only [restrict.to_fun, extension_of_scalars.smul_zero,
        map_zero], },
    { simp only [restrict.to_fun, linear_map.coe_mk, tensor_product.lift.tmul,
        extension_of_scalars.smul_pure_tensor, map_mul],
      convert (extension_of_scalars.smul_pure_tensor _ _ _ _ _).symm, },
    { simp only [restrict.to_fun] at ih1 ih2 ⊢,
      rw [smul_add, map_add, map_add, ih1, ih2],
      simp only [smul_add], }
  end, }.

/--
For two presheaves of ring `𝓞1` and `𝓞2`m a morphism of presheaf of ring `f : 𝓞1 ⟶ 𝓞2` and a
presheaf of module `𝓕` over `𝓞1`, there is a presheaf of modules over `𝓞2` given by
`U ↦ 𝓕(U) ⊗[𝓞1(U)] 𝓞2(U)`.
-/
def extension_by.obj_presheaf_Ab : presheaf Ab X :=
{ obj := λ U,
    ⟨(extension_of_scalars.functor (f.app U)).obj
      { carrier := (𝓕.self.obj U), is_module := 𝓕.is_module (unop U) }⟩,
  map := λ U V inc,
    { to_fun := restrict _ _ (unop U) (unop V) inc,
      map_zero' := by simp,
      map_add' := by simp },
  map_id' := λ U, begin
    ext,
    simp only [id_apply, linear_map.coe_mk, restrict, restrict.to_fun],
    induction x using tensor_product.induction_on with x y x y ih1 ih2,
    { simp only [map_zero], },
    { simp only [add_monoid_hom.coe_mk],
      erw [tensor_product.lift.tmul, linear_map.coe_mk],
      congr';
      erw [category_theory.functor.map_id, id_apply], },
    { rw [map_add, ih1, ih2], },
  end,
  map_comp' := λ U V W incUV incVW, begin
    ext m,
    simp only [add_monoid_hom.coe_mk, functor.map_comp, comp_apply, linear_map.coe_mk],
    unfold restrict restrict.to_fun,
    simp only [linear_map.coe_mk],
    induction m using tensor_product.induction_on with x y x y ih1 ih2,
    { simp only [map_zero], },
    { erw [tensor_product.lift.tmul, tensor_product.lift.tmul, linear_map.coe_mk],
      simp only [functor.map_comp, comp_apply, linear_map.coe_mk], },
    { simp only [map_add, ih1, ih2], }
  end }.

lemma extension_by.obj_presheaf_Ab_obj (U : (opens X)ᵒᵖ) :
  (extension_by.obj_presheaf_Ab f 𝓕).obj U =
  ⟨(extension_of_scalars.functor (f.app U)).obj
      { carrier := (𝓕.self.obj U), is_module := 𝓕.is_module (unop U) }⟩ := rfl

/--
For two presheaves of ring `𝓞1` and `𝓞2`m a morphism of presheaf of ring `f : 𝓞1 ⟶ 𝓞2` and a
presheaf of module `𝓕` over `𝓞1`, there is a presheaf of modules over `𝓞2` given by
`U ↦ 𝓕(U) ⊗[𝓞1(U)] 𝓞2(U)`.
-/
def extension_by.obj : presheaf_of_module 𝓞2 :=
{ self := extension_by.obj_presheaf_Ab f 𝓕,
  is_module := λ U, (extension_of_scalars.module (f.app (op U)) ⟨𝓕.self.obj (op U)⟩).is_module,
  compatible := λ U V inc r m, begin
    induction m using tensor_product.induction_on with x y x y ih1 ih2,
    { simp only [map_zero, smul_zero], },
    { rw [extension_of_scalars.smul_pure_tensor],
      erw [tensor_product.lift.tmul],
      change tensor_product.tmul _ _ _ = _,
      erw [tensor_product.lift.tmul],
      change _ = _ • tensor_product.tmul _ _ _,
      erw extension_of_scalars.smul_pure_tensor,
      rw map_mul,
      refl, },
    { rw [smul_add, map_add, ih1, ih2, map_add, smul_add], }
  end }.

local notation f `_*` 𝓕 := extension_by.obj f 𝓕

lemma extension_by.obj_map {U V : opens X} (inc : op U ⟶ op V) (x : (f _* 𝓕).self.obj (op U)) :
  (f _* 𝓕).self.map inc x = restrict _ _ _ _ inc x := rfl

lemma extension_by.obj_map' {U V : (opens X)ᵒᵖ} (inc : U ⟶ V) (x : (f _* 𝓕).self.obj U) :
  (f _* 𝓕).self.map inc x = restrict _ _ (unop U) (unop V) inc x := rfl

omit 𝓕

private def extension_by.map_app.to_fun {𝓕1 𝓕2 : presheaf_of_module 𝓞1} (φ : 𝓕1 ⟶ 𝓕2)
  (U : (opens X)ᵒᵖ) : (f _* 𝓕1).self.obj U → (f _*𝓕2).self.obj U := λ x,
begin
  refine @tensor_product.lift (𝓞1.obj U) _ (𝓕1.self.obj U) (𝓞2.obj U)
    ((f _* 𝓕2).to_core.self.obj U) _ _ _ (𝓕1.is_module (unop U))
    (restriction_of_scalars.is_module (f.app U) ⟨_⟩)
    (restriction_of_scalars.is_module (f.app U) _) _ x,
  fconstructor,
  { intro m,
    fconstructor,
    { intro s,
      exact @tensor_product.tmul (𝓞1.obj U) _ (𝓕2.self.obj U) (𝓞2.obj U) _ _
        (𝓕2.is_module (unop U))
        (restriction_of_scalars.is_module (f.app U) ⟨_⟩) (φ.1.app U m) s },
    { intros x y,
      rw tensor_product.tmul_add, },
    { intros r x,
      rw ring_hom.id_apply,
      rw @restriction_of_scalars.smul_def (𝓞1.obj U) (𝓞2.obj U) _ ⟨𝓞2.obj U⟩,
      rw @restriction_of_scalars.smul_def (𝓞1.obj U) (𝓞2.obj U) (f.app U)
        { carrier := ((f _* 𝓕2).self.obj U), is_module := _ } r,
      erw extension_of_scalars.smul_pure_tensor,
      refl, }, },
  { intros, ext, simp [map_add, tensor_product.add_tmul], },
  { intros r y,
    ext s,
    simp only [ring_hom.id_apply, linear_map.coe_mk, linear_map.smul_apply],
    have eq1 : (φ.1.app U _) = _ • φ.1.app U _ := @morphism.compatible _ _ _ _ φ (unop U) r y,
    rw eq1,
    rw @restriction_of_scalars.smul_def (𝓞1.obj U) (𝓞2.obj U)
      (f.app U)
      { carrier := (f _* 𝓕2).self.obj U, is_module := (f _* 𝓕2).is_module (unop U) },
    erw extension_of_scalars.smul_pure_tensor,
    rw @tensor_product.smul_tmul (𝓞1.obj U) _ (𝓞1.obj U) _ (𝓕2.self.obj U) (𝓞2.obj U)
      _ _ (𝓕2.is_module (unop U)) (restriction_of_scalars.is_module (f.app U) ⟨_⟩) begin
        haveI := 𝓕2.is_module (unop U),
        rw op_unop at _inst,
        resetI,
        apply_instance,
      end begin
        haveI := restriction_of_scalars.is_module (f.app U) ⟨𝓞2.obj U⟩,
        apply_instance,
      end _ r (φ.1.app U y) s,
    refl,
    },
end.

private def extension_by.map_app.to_fun.map_zero' {𝓕1 𝓕2 : presheaf_of_module 𝓞1}
  (φ : 𝓕1 ⟶ 𝓕2)  (U : (opens X)ᵒᵖ) : extension_by.map_app.to_fun f φ U 0 = 0 :=
by simp [extension_by.map_app.to_fun, map_zero]


private def extension_by.map_app.to_fun.map_add' {𝓕1 𝓕2 : presheaf_of_module 𝓞1}
  (φ : 𝓕1 ⟶ 𝓕2)  (U : (opens X)ᵒᵖ) (x y) :
  extension_by.map_app.to_fun f φ U (x + y) =
  extension_by.map_app.to_fun f φ U x + extension_by.map_app.to_fun f φ U y :=
by simp [extension_by.map_app.to_fun, map_add]

private def extension_by.map {𝓕1 𝓕2 : presheaf_of_module 𝓞1} (φ : 𝓕1 ⟶ 𝓕2) :
  ((f _* 𝓕1).self ⟶ (f _* 𝓕2).self) :=
{ app := λ U,
  { to_fun := extension_by.map_app.to_fun f φ U,
    map_zero' :=  extension_by.map_app.to_fun.map_zero' _ _ _,
    map_add' := extension_by.map_app.to_fun.map_add' _ _ _, },
  naturality' := λ U V inc, begin
    unfold extension_by.map_app.to_fun,
    ext,
    simp only [comp_apply, add_monoid_hom.coe_mk],
    induction x using tensor_product.induction_on with x y x y ih1 ih2,
    { simp only [map_zero], },
    { rw [extension_by.obj_map', extension_by.obj_map', restrict, tensor_product.lift.tmul,
        restrict],
      unfold restrict.to_fun,
      simp only [linear_map.coe_mk],
      erw [tensor_product.lift.tmul, tensor_product.lift.tmul],
      dsimp,
      congr' 1,
      convert add_monoid_hom.congr_fun (φ.1.naturality inc) x, },
    { simp only [map_add, ih1, ih2], }
  end }.

/--The extension of presheaf of modules is functorial -/
def extension_by.map {𝓕1 𝓕2 : presheaf_of_module 𝓞1} (φ : 𝓕1 ⟶ 𝓕2) :
  (f _* 𝓕1) ⟶ (f _* 𝓕2) :=
{ to_fun := extension_by.map f φ,
  compatible := λ U r m, begin
    unfold extension_by.map,
    simp only [add_monoid_hom.coe_mk],
    change tensor_product.lift _ _ = r • tensor_product.lift _ _,
    induction m using tensor_product.induction_on with x y x y ih1 ih2,
    { simp only [map_zero, smul_zero], },
    { rw [extension_of_scalars.smul_pure_tensor, tensor_product.lift.tmul,
        tensor_product.lift.tmul],
      simp only [linear_map.coe_mk],
      erw extension_of_scalars.smul_pure_tensor, },
    { simp only [smul_add, ih1, ih2, map_add], }
  end }.

local notation f `_*→` φ := extension_by.map f φ
/--
The extension of presheaf of module is functorial given by
`𝓕 ↦ 𝓕⊗[𝓞1] 𝓞2` and `φ : 𝓕1 ⟶ 𝓕2` to `(m ⊗ s) ↦ φ m ⊗ s`.
-/
def extension_by.functor : presheaf_of_module 𝓞1 ⥤ presheaf_of_module 𝓞2 :=
{ obj := λ 𝓕, f _* 𝓕,
  map := λ _ _ φ, f _*→ φ,
  map_id' := λ 𝓕, begin
    ext U,
    unfold extension_by.map,
    dsimp only,
    change extension_by.map_app.to_fun f _ _ _ = _,
    change tensor_product.lift _ _ = _,
    induction x using tensor_product.induction_on with x y x y ih1 ih2,
    { simp only [map_zero], },
    { rw [tensor_product.lift.tmul],
      simp only [linear_map.coe_mk],
      refl, },
    { simp only [map_add, ih1, ih2], },
  end,
  map_comp' := λ 𝓕1 𝓕2 𝓕3 φ12 φ23, begin
    ext U,
    unfold extension_by.map,
    dsimp only,
    change extension_by.map_app.to_fun f _ _ _ = _,
    change tensor_product.lift _ _ = _,
    induction x using tensor_product.induction_on with x y x y ih1 ih2,
    { simp only [map_zero] },
    { simp only [tensor_product.lift.tmul, linear_map.coe_mk],
      erw [comp_apply, comp_apply, tensor_product.lift.tmul],
      simp only [linear_map.coe_mk], },
    { simp only [map_add, ih1, ih2], },
  end }.

end extension

section

variables {T : Top} {𝓞1 𝓞2 : presheaf CommRing T} (f : 𝓞1 ⟶ 𝓞2)
variables (X : presheaf_of_module 𝓞1) (Y : presheaf_of_module 𝓞2)

def forward.to_fun (g  : ((extension_by.functor f).obj X ⟶ Y)) :
  X.self ⟶ ((restriction_by.functor f).obj Y).self :=
{ app := λ U, { to_fun := λ x, begin
    refine ((change_of_rings.adjunction (f.app U)).hom_equiv
      { carrier := (X.self.obj U),
        is_module := X.is_module (unop U) }
      { carrier := (Y.self.obj U),
        is_module := Y.is_module (unop U) }).to_fun
      { to_fun := λ z, g.1.app U z,
        map_add' := _,
        map_smul' := _, } x,
      { intros x x',
        rw map_add, },
      { intros r2 z,
        induction z using tensor_product.induction_on with x' r2' _ _ ih1 ih2,
        { simp only [smul_zero, map_zero], },
        { simp only [ring_hom.id_apply],
          erw @morphism.compatible _ _ _ _ g (unop U) r2,
          refl, },
        { simp [smul_add, ih1, ih2], }, },
  end,
  map_zero' := by simp only [map_zero],
  map_add' := λ x x', by simp only [map_add], },
  naturality' := λ U V inc, begin
    ext x,
    simp only [equiv.to_fun_as_coe, adjunction.hom_equiv_unit, comp_apply, add_monoid_hom.coe_mk],
    unfold change_of_rings.adjunction,
    dsimp only,
    unfold change_of_rings.unit,
    dsimp only,
    unfold unit.map,
    simp only [linear_map.coe_mk],
    sorry,
  end }.

#exit
def forward (g  :((extension_by.functor f).obj X ⟶ Y)) : (X ⟶ (restriction_by.functor f).obj Y) :=
{ to_fun := _,
  compatible := _ }

-- ((extension_by.functor f).obj X ⟶ Y) ≃ (X ⟶ (restriction_by.functor f).obj Y)
example : adjunction (extension_by.functor f) (restriction_by.functor f) :=
{ hom_equiv := _,
  unit := _,
  counit := _,
  hom_equiv_unit' := _,
  hom_equiv_counit' := _ }

end

end presheaf_of_module
