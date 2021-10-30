/-
Copyright (c) 2021 Yaël Dillies, Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Bhavik Mehta
-/
import .triangle

/-!
# The corners theorem

This file defines combinatorial corners and proves the two dimensional corners theorem.
-/

open finset function
open_locale big_operators

variables {α ι ι' : Type*} [add_comm_monoid α] [decidable_eq ι] [fintype ι] [decidable_eq ι']
  [fintype ι'] {ε : ℝ}

lemma sum_indicator_singleton {ι M : Type*} [add_comm_monoid M] {s : finset ι} {i : ι}
  (hi : i ∈ s)(f : ι → ι  → M) (g : ι → ι) :
  ∑ (j : ι) in s, ({i} : set ι).indicator (f j) (g j) = f i (g i) :=
begin
  sorry,
end

lemma finset.disjoint_iff [decidable_eq α] (s t : finset α) : disjoint s t ↔ ∀ ⦃x⦄, x ∈ s → x ∉ t :=
begin
  sorry
end

/-! ### Simplex domain -/

section simplex_domain

/-- The `ι`-th combinatorial simplex domain of size `n + 1`. -/
def simplex_domain (ι : Type*) [fintype ι] (n : ℕ) : Type* := {f : ι → ℕ // ∑ i, f i = n}

namespace simplex_domain
variables {n : ℕ} {s : set (simplex_domain ι n)} {x : simplex_domain ι n} {f : ι → ℕ} {i : ι}

/-- The `i`-th coordinate of `x : simplex_domain ι n` as an element of `f (n + 1)`. -/
protected def apply (x : simplex_domain ι n) (i : ι) : fin (n + 1) :=
⟨x.val i, begin
  simp_rw [nat.lt_succ_iff, ←x.2],
  exact single_le_sum (λ i _, nat.zero_le _) (mem_univ _),
end⟩

@[simp] lemma coe_apply : (x.apply i : ℕ) = x.val i := rfl

@[ext] lemma ext {x y : simplex_domain ι n} (h : ∀ i, x.apply i = y.apply i) : x = y :=
begin
  ext i,
  exact (fin.ext_iff _ _).1 (h i),
end

-- /-- Projects any point onto the simplex domain in one direction. -/
-- def proj (f : ι → ℕ) (i : ι) (hf : ∑ j in univ.erase i, f j ≤ n) : simplex_domain ι n :=
-- begin
--   refine ⟨finset.piecewise {i} (n - ∑ j in univ.erase i, f j) f,
--     (sum_piecewise _ _ _ _).trans _⟩,
--   rw [univ_inter, sum_singleton, sdiff_singleton_eq_erase, pi.sub_apply, sum_apply],
--   simp only [nat.cast_id, pi.coe_nat],
--   exact tsub_add_cancel_of_le hf,
-- end

/-- Projects a point in a simplex domain onto a smaller simplex domain in one direction. -/
def proj (x : simplex_domain ι' n) (f : ι ↪ ι') (i : ι) : simplex_domain ι n :=
begin
  refine ⟨finset.piecewise {i} (n - ∑ j in univ.erase i, x.val (f j)) (x.val ∘ f),
    (sum_piecewise _ _ _ _).trans _⟩,
  rw [univ_inter, sum_singleton, sdiff_singleton_eq_erase, pi.sub_apply, sum_apply],
  simp only [nat.cast_id, pi.coe_nat],
  refine tsub_add_cancel_of_le ((sum_le_sum_of_subset $ erase_subset _ _).trans _),
  simp_rw [←finset.sum_map, ←x.2],
  exact sum_le_sum_of_subset (subset_univ _),
end

-- /-- A corner in `s : set (simplex_domain ι n)` is a point whose projections all are within `s` -/
-- def corners (s : set (simplex_domain ι n)) : set (ι → ℕ) :=
-- {f | if h : ∑ i, f i ≤ n
--   then (∀ i, simplex_domain.proj f i ((sum_mono_set f $ erase_subset _ _).trans h) ∈ s)
--   else false }

/-- A corner in `s : set (simplex_domain ι n)` is a point `x : simplex_domain (option ι) n` whose
projections all are within `s` -/
def corners (s : set (simplex_domain ι n)) : set (simplex_domain (option ι) n) :=
{x | ∀ i, x.proj embedding.some i ∈ s}

/-- The set of elements of `simplex_domain ι n` whose `i`-th coordinate is `a`. -/
def line (n : ℕ) (i : ι) (a : ℕ) : set (simplex_domain ι n) := {x | x.val i = a}

/-- The set of elements of `simplex_domain ι n` whose coordinates are the same as `a` except the `i`-th and `j`-th ones. -/
def line' (n : ℕ) (i j : ι) (a : ι → ℕ) : set (simplex_domain ι n) :=
{x | ∀ k, k ≠ i → k ≠ j → x.val k = a k}

/-- The set of elements of `simplex_domain ι n` whose coordinates are the same as `a` on `s : set \io `except the `i`-th and `j`-th ones. -/
def line'' (n : ℕ) (s : set ι) (a : ι → ℕ) : set (simplex_domain ι n) :=
{x | ∀ ⦃i⦄, i ∈ s → x.val i = a i}

instance (n : ℕ) (i : ι) (a : ℕ) (x : simplex_domain ι n) : decidable (x ∈ line n i a) :=
by { unfold line, apply_instance }

/-- Projects any point onto the simplex domain in one direction. -/
def mem_line_self (x : simplex_domain ι n) (i : ι) : x ∈ line n i (x.val i) := rfl

/-- The graph appearing in the simplex corners theorem. -/
def corners_graph (s : set (simplex_domain ι n)) : simple_graph (ι × fin (n + 1)) :=
{ adj := λ a b, a ≠ b ∧ ∃ x, x ∈ s ∧ x ∈ line n a.1 a.2 ∧ x ∈ line n b.1 b.2,
  symm := begin
      rintro a b ⟨h, x, hx, hax, hbx⟩,
      exact ⟨h.symm, x, hx, hbx, hax⟩,
    end,
  loopless := λ a h, h.1 rfl }

instance [decidable_pred (∈ s)] : decidable_rel (corners_graph s).adj :=
begin
  rw corners_graph,
  sorry
end

/-- The trivial `n`-clique in the corners graph. -/
def trivial_n_clique (x : simplex_domain ι n) : finset (ι × fin (n + 1)) :=
(univ.filter $ λ i, x ∈ line n i (x.val i)).image $ λ i, (i, x.apply i)

lemma card_trivial_n_clique (x : simplex_domain ι n) : x.trivial_n_clique.card = fintype.card ι :=
begin
  rw [trivial_n_clique, card_image_of_injective, filter_true_of_mem, card_univ],
  { exact λ i _, x.mem_line_self i },
  { exact λ a b h, (prod.mk.inj h).1 }
end

lemma mem_trivial_n_clique {i : ι} {a : fin (n + 1)} :
  (i, a) ∈ x.trivial_n_clique ↔ x.apply i = a :=
begin
  simp_rw [trivial_n_clique, mem_image, exists_prop, mem_filter, prod.mk.inj_iff],
  split,
  { rintro ⟨i, ⟨_, hx⟩, rfl, ha⟩,
    exact ha },
  { rintro h,
    exact ⟨i, ⟨mem_univ i, x.mem_line_self i⟩, rfl, h⟩ }
end

lemma trivial_n_clique_is_n_clique (hx : x ∈ s) :
  (corners_graph s).is_n_clique (fintype.card ι) x.trivial_n_clique :=
begin
  refine ⟨x.card_trivial_n_clique, _⟩,
  rintro ⟨i, a⟩ ha ⟨j, b⟩ hb hab,
  refine ⟨hab, x, hx, _⟩,
  rw [mem_coe, mem_trivial_n_clique] at ha hb,
  rw [←ha, ←hb],
  exact ⟨x.mem_line_self i, x.mem_line_self j⟩,
end

lemma trivial_n_clique_injective : injective (@trivial_n_clique ι _ _ n) :=
λ a b h, ext $ λ i, by rw [←mem_trivial_n_clique, h, mem_trivial_n_clique]

end simplex_domain

open simplex_domain

/-! ### Simplex corners theorem -/

section simplex_corner

variables {n : ℕ} {s : finset (simplex_domain (fin 3) n)} {x : simplex_domain (fin 3) n}
  {f : fin 3 → ℕ}

--  s.pairwise_disjoint (@trivial_n_clique ι _ _ n)
-- lemma trivial_n_clique_pairwise_disjoint :
--   (s.image trivial_n_clique : set (finset (fin 3 × fin (n + 1)))).pairwise_disjoint :=
-- begin
--   rintro x hx y hy h,
--   rw [mem_coe, mem_image] at hx hy,
--   obtain ⟨x, hx, rfl⟩ := hx,
--   obtain ⟨y, hy, rfl⟩ := hy,
--   rw trivial_n_clique_injective.ne_iff at h,
--   rw finset.disjoint_iff,
--   rintro ⟨i, a⟩ hax hay,
--   rw mem_trivial_n_clique at hax hay,
--   sorry -- wrong
-- end

lemma mem_corners_iff_is_n_clique {s : set (simplex_domain (fin 3) n)}
  {x : simplex_domain (option (fin 3)) n} :
  x ∈ corners s ↔ (corners_graph s).is_n_clique 3
    (univ.map ⟨λ i, (i, x.apply i), λ a b hab, (prod.mk.inj hab).1⟩) :=
begin
  split,
  { refine λ hx, ⟨card_map _, _⟩,
    refine λ a ha b hb hab, ⟨hab, _⟩,
    rw [mem_coe, mem_map] at ha hb,
    obtain ⟨i, _, rfl⟩ := ha,
    obtain ⟨j, _, rfl⟩ := hb,
    rw (embedding.injective _).ne_iff at hab,
    refine ⟨x.proj embedding.some i, hx i, _, _⟩; rw [line, proj]; dsimp,
    { rw piecewise_eq_of_mem _ _ _ (mem_singleton_self i),
      simp_rw ←x.2,
      rw sum_erase,
      sorry },
    { exact piecewise_eq_of_not_mem _ _ _ (not_mem_singleton.2 hab.symm) } }
end

lemma card_le_card_triangle_finset_corners_graph :
  s.card ≤ (corners_graph (s : set (simplex_domain (fin 3) n))).triangle_finset.card :=
begin
  rw ←card_image_of_injective s trivial_n_clique_injective,
  refine card_le_of_subset (λ v hv, _),
  rw mem_image at hv,
  obtain ⟨x, hx, rfl⟩ := hv,
  rw ←mem_coe at hx,
  rw [simple_graph.mem_triangle_finset'],
  have := trivial_n_clique_is_n_clique hx,
  rwa fintype.card_fin at this,
end

lemma corners_graph_triangle_free_far :
  (corners_graph (s : set (simplex_domain (fin 3) n))).triangle_free_far ε :=
begin

end

lemma corners_theorem {ε : ℝ} (hε : 0 < ε) :
  ∃ n : ℕ, ∀ A : finset (simplex_domain (fin 3) n),  ε * n^2 ≤ A.card →
    ∃ x : simplex_domain (option (fin 3)) n, 0 < x.val none ∧ corners ↑A x :=
begin
  sorry
end

end simplex_corner

/-! ### Usual corners -/

/-- Combinatorial corners. -/
def higher_corners (A : set (ι → α)) : set ((ι → α) × α) :=
{x | x.1 ∈ A ∧ ∀ i, x.1 + set.indicator {i} (λ _, x.2) ∈ A}

/-- Two-dimensional combinatorial corner. -/
def is_corner (A : set (α × α)) : α → α → α → Prop :=
λ x y h, (x, y) ∈ A ∧ (x + h, y) ∈ A ∧ (x, y + h) ∈ A

/-! ### Half Corners theorem -/

/-- The graph appearing in the corners theorem. -/
def half_corners_graph (A : set (ℕ × ℕ)) (n : ℕ) : simple_graph (fin 3 × fin n) :=
simple_graph.from_rel (λ a b, begin
  exact a.1 = 0 ∧ b.1 = 1 ∧ (↑a.2, ↑b.2) ∈ A
      ∨ a.1 = 1 ∧ b.1 = 2 ∧ a.2 ≤ b.2 ∧ (↑b.2 - ↑a.2, ↑a.2) ∈ A
      ∨ a.1 = 2 ∧ b.1 = 0 ∧ b.2 ≤ a.2 ∧ (↑b.2, ↑a.2 - ↑b.2) ∈ A,
end)

-- lemma trivial_triangle_mem_half_corners_graph (hx : x ∈ A) {a b : fin n} :
--   half_corners_graph.adj n A (a, k) (b, k)

lemma corners_graph_triangle_free_far : (half_corners_graph A n).triangle_free_far ε := sorry

lemma half_corners_theorem {ε : ℝ} (hε : 0 < ε) :
  ∃ n : ℕ, ∀ A : finset (ℕ × ℕ), (∀ x y, (x, y) ∈ A → x + y ≤ n) →  ε * n^2 ≤ A.card →
    ∃ x y h, h ≠ 0 ∧ is_corner ↑A x y h :=
begin
  sorry
end

/-! ### Corners theorem-/

/-- The graph appearing in the corners theorem. -/
def corners_graph (A : set (ℕ × ℕ)) : simple_graph (fin 3 × ℕ) := sorry

-- lemma corners_graph_triangle_free_far : (corners_graph A).triangle_free_far ε

lemma corners_theorem {ε : ℝ} (hε : 0 < ε) :
  ∃ n : ℕ, ∀ A ⊆ (Iio n).product (Iio n), ε * n^2 ≤ A.card → ∃ x y h, h ≠ 0 ∧ is_corner ↑A x y h :=
begin
  sorry
end
