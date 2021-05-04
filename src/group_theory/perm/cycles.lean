/-
Copyright (c) 2019 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes
-/
import data.nat.parity
import data.equiv.fintype
import group_theory.perm.sign
/-!
# Cyclic permutations

## Main definitions

In the following, `f : equiv.perm β`.

* `equiv.perm.is_cycle`: `f.is_cycle` when two nonfixed points of `β`
  are related by repeated application of `f`.
* `equiv.perm.same_cycle`: `f.same_cycle x y` when `x` and `y` are in the same cycle of `f`.

The following two definitions require that `β` is a `fintype`:

* `equiv.perm.cycle_of`: `f.cycle_of x` is the cycle of `f` that `x` belongs to.
* `equiv.perm.cycle_factors`: `f.cycle_factors` is a list of disjoint cyclic permutations that
  multiply to `f`.

## Main results

* This file contains several closure results:
  - `closure_is_cycle` : The symmetric group is generated by cycles
  - `closure_cycle_adjacent_swap` : The symmetric group is generated by
    a cycle and an adjacent transposition
  - `closure_cycle_coprime_swap` : The symmetric group is generated by
    a cycle and a coprime transposition
  - `closure_prime_cycle_swap` : The symmetric group is generated by
    a prime cycle and a transposition

-/
namespace equiv.perm
open equiv function finset

variables {α : Type*} {β : Type*} [decidable_eq α]

section sign_cycle

/-!
### `is_cycle`
-/

/-- A permutation is a cycle when any two nonfixed points of the permutation are related by repeated
  application of the permutation. -/
def is_cycle (f : perm β) : Prop := ∃ x, f x ≠ x ∧ ∀ y, f y ≠ y → ∃ i : ℤ, (f ^ i) x = y

lemma is_cycle.ne_one {f : perm β} (h : is_cycle f) : f ≠ 1 :=
λ hf, by simpa [hf, is_cycle] using h

lemma is_cycle.two_le_card_support {f : perm β} (h : is_cycle f) (hf : f.support.finite) :
  2 ≤ hf.to_finset.card :=
two_le_card_support_of_ne_one hf h.ne_one

lemma is_cycle_swap {α : Type*} [decidable_eq α] {x y : α} (hxy : x ≠ y) : is_cycle (swap x y) :=
⟨y, by rwa swap_apply_right,
  λ a (ha : ite (a = x) y (ite (a = y) x a) ≠ a),
    if hya : y = a then ⟨0, hya⟩
    else ⟨1, by { rw [gpow_one, swap_apply_def], split_ifs at *; cc }⟩⟩

lemma is_swap.is_cycle {α : Type*} [decidable_eq α] {f : perm α} (hf : is_swap f) : is_cycle f :=
begin
  obtain ⟨x, y, hxy, rfl⟩ := hf,
  exact is_cycle_swap hxy,
end

lemma is_cycle.inv {f : perm β} (hf : is_cycle f) : is_cycle (f⁻¹) :=
let ⟨x, hx⟩ := hf in
⟨x, by { simp only [inv_eq_iff_eq, *, forall_prop_of_true, ne.def] at *, cc },
  λ y hy, let ⟨i, hi⟩ := hx.2 y (by { simp only [inv_eq_iff_eq, *, forall_prop_of_true,
      ne.def] at *, cc }) in
    ⟨-i, by rwa [gpow_neg, inv_gpow, inv_inv]⟩⟩

lemma is_cycle.is_cycle_conj {f g : perm β} (hf : is_cycle f) : is_cycle (g * f * g⁻¹) :=
begin
  obtain ⟨a, ha1, ha2⟩ := hf,
  refine ⟨g a, by simp [ha1], λ b hb, _⟩,
  obtain ⟨i, hi⟩ := ha2 (g⁻¹ b) _,
  { refine ⟨i, _⟩,
    rw conj_gpow,
    simp [hi] },
  { contrapose! hb,
    rw [perm.mul_apply, perm.mul_apply, hb, apply_inv_self] }
end

lemma is_cycle.exists_gpow_eq {f : perm β} (hf : is_cycle f) {x y : β}
  (hx : f x ≠ x) (hy : f y ≠ y) : ∃ i : ℤ, (f ^ i) x = y :=
let ⟨g, hg⟩ := hf in
let ⟨a, ha⟩ := hg.2 x hx in
let ⟨b, hb⟩ := hg.2 y hy in
⟨b - a, by rw [← ha, ← mul_apply, ← gpow_add, sub_add_cancel, hb]⟩

lemma is_cycle.exists_pow_eq [fintype β] {f : perm β} (hf : is_cycle f) {x y : β}
  (hx : f x ≠ x) (hy : f y ≠ y) : ∃ i : ℕ, (f ^ i) x = y :=
let ⟨n, hn⟩ := hf.exists_gpow_eq hx hy in
by classical; exact ⟨(n % order_of f).to_nat, by {
  have := n.mod_nonneg (int.coe_nat_ne_zero.mpr (ne_of_gt (order_of_pos f))),
  rwa [← gpow_coe_nat, int.to_nat_of_nonneg this, ← gpow_eq_mod_order_of] }⟩

/-- The subgroup generated by a cycle is in bijection with its support -/
noncomputable def is_cycle.gpowers_equiv_support {σ : perm α} (hσ : is_cycle σ) :
  (↑(subgroup.gpowers σ) : set (perm α)) ≃ (σ.support) :=
equiv.of_bijective (λ τ, ⟨τ (classical.some hσ),
begin
  obtain ⟨τ, n, rfl⟩ := τ,
  rw [mem_support],
  refine λ h, (classical.some_spec hσ).1 ((σ ^ n).injective _),
  rwa [←mul_apply, mul_gpow_self, ←mul_self_gpow],
end⟩)
begin
  split,
  { rintros ⟨a, m, rfl⟩ ⟨b, n, rfl⟩ h,
    ext y,
    by_cases hy : σ y = y,
    { simp_rw [subtype.coe_mk, gpow_apply_eq_self_of_apply_eq_self hy] },
    { obtain ⟨i, rfl⟩ := (classical.some_spec hσ).2 y hy,
      rw [subtype.coe_mk, subtype.coe_mk, gpow_apply_comm σ m i, gpow_apply_comm σ n i],
      exact congr_arg _ (subtype.ext_iff.mp h) } }, by
  { rintros ⟨y, hy⟩,
    rw [mem_support] at hy,
    obtain ⟨n, rfl⟩ := (classical.some_spec hσ).2 y hy,
    exact ⟨⟨σ ^ n, n, rfl⟩, rfl⟩ },
end

@[simp] lemma is_cycle.gpowers_equiv_support_apply {σ : perm α} (hσ : is_cycle σ) {n : ℕ} :
  hσ.gpowers_equiv_support ⟨σ ^ n, n, rfl⟩ = ⟨(σ ^ n) (classical.some hσ),
    pow_apply_mem_support.2 (mem_support.2 (classical.some_spec hσ).1)⟩ :=
rfl

@[simp] lemma is_cycle.gpowers_equiv_support_symm_apply {σ : perm α} (hσ : is_cycle σ) (n : ℕ) :
  hσ.gpowers_equiv_support.symm ⟨(σ ^ n) (classical.some hσ),
    pow_apply_mem_support.2 (mem_support.2 (classical.some_spec hσ).1)⟩ =
    ⟨σ ^ n, n, rfl⟩ :=
(equiv.symm_apply_eq _).2 hσ.gpowers_equiv_support_apply

lemma order_of_is_cycle [fintype β] {σ : perm β} (hσ : is_cycle σ) (hf : σ.support.finite) :
  order_of σ = hf.to_finset.card :=
begin
  classical,
  rw [order_eq_card_gpowers, ←fintype.card_coe],
  letI := hf.fintype,
  convert fintype.card_congr (is_cycle.gpowers_equiv_support hσ) using 3,
  simp
end

lemma is_cycle_swap_mul_aux₁ {α : Type*} [decidable_eq α] : ∀ (n : ℕ) {b x : α} {f : perm α}
  (hb : (swap x (f x) * f) b ≠ b) (h : (f ^ n) (f x) = b),
  ∃ i : ℤ, ((swap x (f x) * f) ^ i) (f x) = b
| 0         := λ b x f hb h, ⟨0, h⟩
| (n+1 : ℕ) := λ b x f hb h,
  if hfbx : f x = b then ⟨0, hfbx⟩
  else
    have f b ≠ b ∧ b ≠ x, from ne_and_ne_of_swap_mul_apply_ne_self hb,
    have hb' : (swap x (f x) * f) (f⁻¹ b) ≠ f⁻¹ b,
      by { rw [mul_apply, apply_inv_self, swap_apply_of_ne_of_ne this.2 (ne.symm hfbx),
          ne.def, ← f.injective.eq_iff, apply_inv_self],
        exact this.1 },
    let ⟨i, hi⟩ := is_cycle_swap_mul_aux₁ n hb'
      (f.injective $ by { rw [apply_inv_self], rwa [pow_succ, mul_apply] at h }) in
    ⟨i + 1, by rw [add_comm, gpow_add, mul_apply, hi, gpow_one, mul_apply, apply_inv_self,
        swap_apply_of_ne_of_ne (ne_and_ne_of_swap_mul_apply_ne_self hb).2 (ne.symm hfbx)]⟩

lemma is_cycle_swap_mul_aux₂ {α : Type*} [decidable_eq α] :
  ∀ (n : ℤ) {b x : α} {f : perm α} (hb : (swap x (f x) * f) b ≠ b) (h : (f ^ n) (f x) = b),
  ∃ i : ℤ, ((swap x (f x) * f) ^ i) (f x) = b
| (n : ℕ) := λ b x f, is_cycle_swap_mul_aux₁ n
| -[1+ n] := λ b x f hb h,
  if hfbx : f⁻¹ x = b then
    ⟨-1, by rwa [gpow_neg, gpow_one, mul_inv_rev, mul_apply, swap_inv, swap_apply_right]⟩
  else if hfbx' : f x = b then ⟨0, hfbx'⟩
  else
  have f b ≠ b ∧ b ≠ x := ne_and_ne_of_swap_mul_apply_ne_self hb,
  have hb : (swap x (f⁻¹ x) * f⁻¹) (f⁻¹ b) ≠ f⁻¹ b,
    by { rw [mul_apply, swap_apply_def],
      split_ifs;
      simp only [inv_eq_iff_eq, perm.mul_apply, gpow_neg_succ_of_nat, ne.def,
        perm.apply_inv_self] at *;
      cc },
  let ⟨i, hi⟩ := is_cycle_swap_mul_aux₁ n hb
    (show (f⁻¹ ^ n) (f⁻¹ x) = f⁻¹ b, by
      rw [← gpow_coe_nat, ← h, ← mul_apply, ← mul_apply, ← mul_apply, gpow_neg_succ_of_nat,
        ← inv_pow, pow_succ', mul_assoc, mul_assoc, inv_mul_self, mul_one, gpow_coe_nat,
        ← pow_succ', ← pow_succ]) in
  have h : (swap x (f⁻¹ x) * f⁻¹) (f x) = f⁻¹ x, by rw [mul_apply, inv_apply_self, swap_apply_left],
  ⟨-i, by rw [← add_sub_cancel i 1, neg_sub, sub_eq_add_neg, gpow_add, gpow_one, gpow_neg,
      ← inv_gpow, mul_inv_rev, swap_inv, mul_swap_eq_swap_mul, inv_apply_self, swap_comm _ x,
      gpow_add, gpow_one, mul_apply, mul_apply (_ ^ i), h, hi, mul_apply, apply_inv_self,
      swap_apply_of_ne_of_ne this.2 (ne.symm hfbx')]⟩

lemma is_cycle.eq_swap_of_apply_apply_eq_self {α : Type*} [decidable_eq α]
  {f : perm α} (hf : is_cycle f) {x : α}
  (hfx : f x ≠ x) (hffx : f (f x) = x) : f = swap x (f x) :=
equiv.ext $ λ y,
let ⟨z, hz⟩ := hf in
let ⟨i, hi⟩ := hz.2 x hfx in
if hyx : y = x then by simp [hyx]
else if hfyx : y = f x then by simp [hfyx, hffx]
else begin
  rw [swap_apply_of_ne_of_ne hyx hfyx],
  refine by_contradiction (λ hy, _),
  cases hz.2 y hy with j hj,
  rw [← sub_add_cancel j i, gpow_add, mul_apply, hi] at hj,
  cases gpow_apply_eq_of_apply_apply_eq_self hffx (j - i) with hji hji,
  { rw [← hj, hji] at hyx, cc },
  { rw [← hj, hji] at hfyx, cc }
end

lemma is_cycle.swap_mul {α : Type*} [decidable_eq α] {f : perm α} (hf : is_cycle f) {x : α}
  (hx : f x ≠ x) (hffx : f (f x) ≠ x) : is_cycle (swap x (f x) * f) :=
⟨f x, by { simp only [swap_apply_def, mul_apply],
        split_ifs; simp [f.injective.eq_iff] at *; cc },
  λ y hy,
  let ⟨i, hi⟩ := hf.exists_gpow_eq hx (ne_and_ne_of_swap_mul_apply_ne_self hy).1 in
  have hi : (f ^ (i - 1)) (f x) = y, from
    calc (f ^ (i - 1)) (f x) = (f ^ (i - 1) * f ^ (1 : ℤ)) x : by rw [gpow_one, mul_apply]
    ... = y : by rwa [← gpow_add, sub_add_cancel],
  is_cycle_swap_mul_aux₂ (i - 1) hy hi⟩

lemma is_cycle.sign [fintype α] : Π {f : perm α} (hf : is_cycle f) (hs : f.support.finite),
  sign f = -(-1) ^ hs.to_finset.card
| f := λ hf hs,
let ⟨x, hx⟩ := hf in
calc sign f = sign (swap x (f x) * (swap x (f x) * f)) :
  by rw [← mul_assoc, mul_def, mul_def, swap_swap, trans_refl]
... = -(-1) ^ hs.to_finset.card :
  if h1 : f (f x) = x
  then
    have h : swap x (f x) * f = 1,
      begin
        rw hf.eq_swap_of_apply_apply_eq_self hx.1 h1,
        simp only [perm.mul_def, perm.one_def, swap_apply_left, swap_swap]
      end,
    by {
      rw [←inv_mul_self f, mul_right_cancel_iff, ←inv_inj, swap_inv, inv_inv] at h,
      have : hs.to_finset.card = 2,
        { convert card_support_swap hx.left.symm,
          exact h.symm },
      rw [this, ←h],
      simp [hx.left.symm, pow_two] }
  else
    have hm : (support (swap x (f x) * f)).finite :=
      ((support_swap_finite x (f x)).union hs).subset (support_mul_le _ _),
    have h : card hm.to_finset + 1 = card hs.to_finset,
      { rw [←card_singleton x, ←card_disjoint_union],
        { congr,
          ext z,
          simp_rw [mem_union, set.finite.mem_to_finset, support_swap_mul_eq _ _ h1],
          split,
          { rintro (hz | hz),
            { exact set.diff_subset _ _ hz },
            { rw ←mem_support at hx,
              rw mem_singleton at hz,
              exact hz.symm ▸ hx.left } },
          { by_cases hxz : z = x;
            simp [hxz] } },
        { simp } },
    have wf : card hm.to_finset < card hs.to_finset := card_support_swap_mul _ _ hx.left,
    by { rw [sign_mul, sign_swap hx.1.symm, (hf.swap_mul hx.1 h1).sign hm, ← h],
      simp only [pow_add, mul_one, units.neg_neg, one_mul, units.mul_neg, eq_self_iff_true,
        pow_one, units.neg_mul_neg] }
using_well_founded {rel_tac := λ _ _, `[exact ⟨_, measure_wf (λ f, (show f.support.finite,
  from set.finite.of_fintype (perm.support f)).to_finset.card)⟩]}

-- The lemma `support_pow_le` is relevant. It means that `h2` is equivalent to
-- `σ.support = (σ ^ n).support`, as well as to `σ.support.card ≤ (σ ^ n).support.card`.
lemma is_cycle_of_is_cycle_pow {σ : perm β} {n : ℤ}
  (h1 : is_cycle (σ ^ n)) (h2 : σ.support ≤ (σ ^ n).support) : is_cycle σ :=
begin
  have key : ∀ x : β, (σ ^ n) x ≠ x ↔ σ x ≠ x,
  { simp_rw [←mem_support],
    exact set.ext_iff.mp (le_antisymm (support_gpow_le σ n) h2) },
  obtain ⟨x, hx1, hx2⟩ := h1,
  refine ⟨x, (key x).mp hx1, λ y hy, _⟩,
  cases (hx2 y ((key y).mpr hy)) with i _,
  exact ⟨n * i, by rwa gpow_mul⟩,
end

lemma is_cycle.extend_domain {α : Type*} {p : β → Prop} [decidable_pred p]
  (f : α ≃ subtype p) {g : perm α} (h : is_cycle g) :
  is_cycle (g.extend_domain f) :=
begin
  obtain ⟨a, ha, ha'⟩ := h,
  refine ⟨f a, _, λ b hb, _⟩,
  { rw extend_domain_apply_image,
    exact λ con, ha (f.injective (subtype.coe_injective con)) },
  by_cases pb : p b,
  { obtain ⟨i, hi⟩ := ha' (f.symm ⟨b, pb⟩) (λ con, hb _),
    { refine ⟨i, _⟩,
      have hnat : ∀ (k : ℕ) (a : α), (g.extend_domain f ^ k) ↑(f a) = f ((g ^ k) a),
      { intros k a,
        induction k with k ih, { refl },
        rw [pow_succ, perm.mul_apply, ih, extend_domain_apply_image, pow_succ, perm.mul_apply] },
      have hint : ∀ (k : ℤ) (a : α), (g.extend_domain f ^ k) ↑(f a) = f ((g ^ k) a),
      { intros k a,
        induction k with k k,
        { rw [gpow_of_nat, gpow_of_nat, hnat] },
        rw [gpow_neg_succ_of_nat, gpow_neg_succ_of_nat, inv_eq_iff_eq, hnat, apply_inv_self] },
      rw [hint, hi, apply_symm_apply, subtype.coe_mk] },
    { rw [extend_domain_apply_subtype _ _ pb, con, apply_symm_apply, subtype.coe_mk] } },
  { exact (hb (extend_domain_apply_not_subtype _ _ pb)).elim }
end

end sign_cycle

/-!
### `same_cycle`
-/

/-- The equivalence relation indicating that two points are in the same cycle of a permutation. -/
def same_cycle (f : perm β) (x y : β) : Prop := ∃ i : ℤ, (f ^ i) x = y

@[refl] lemma same_cycle.refl (f : perm β) (x : β) : same_cycle f x x := ⟨0, rfl⟩

@[symm] lemma same_cycle.symm (f : perm β) {x y : β} : same_cycle f x y → same_cycle f y x :=
λ ⟨i, hi⟩, ⟨-i, by rw [gpow_neg, ← hi, inv_apply_self]⟩

@[trans] lemma same_cycle.trans (f : perm β) {x y z : β} :
  same_cycle f x y → same_cycle f y z → same_cycle f x z :=
λ ⟨i, hi⟩ ⟨j, hj⟩, ⟨j + i, by rw [gpow_add, mul_apply, hi, hj]⟩

lemma same_cycle.apply_eq_self_iff {f : perm β} {x y : β} :
  same_cycle f x y → (f x = x ↔ f y = y) :=
λ ⟨i, hi⟩, by rw [← hi, ← mul_apply, ← gpow_one_add, add_comm, gpow_add_one, mul_apply,
    (f ^ i).injective.eq_iff]

lemma is_cycle.same_cycle {f : perm β} (hf : is_cycle f) {x y : β}
  (hx : f x ≠ x) (hy : f y ≠ y) : same_cycle f x y :=
hf.exists_gpow_eq hx hy

instance [fintype α] (f : perm α) : decidable_rel (same_cycle f) :=
λ x y, decidable_of_iff (∃ n ∈ list.range (fintype.card (perm α)), (f ^ n) x = y)
⟨λ ⟨n, _, hn⟩, ⟨n, hn⟩, λ ⟨i, hi⟩, ⟨(i % order_of f).nat_abs, list.mem_range.2
  (int.coe_nat_lt.1 $
    by { rw int.nat_abs_of_nonneg (int.mod_nonneg _
        (int.coe_nat_ne_zero_iff_pos.2 (order_of_pos _))),
      { apply lt_of_lt_of_le (int.mod_lt _ (int.coe_nat_ne_zero_iff_pos.2 (order_of_pos _))),
        { simp [order_of_le_card_univ] },
        exact fintype_perm },
      exact fintype_perm, }),
  by { rw [← gpow_coe_nat, int.nat_abs_of_nonneg (int.mod_nonneg _
      (int.coe_nat_ne_zero_iff_pos.2 (order_of_pos _))), ← gpow_eq_mod_order_of, hi],
    exact fintype_perm }⟩⟩

lemma same_cycle_apply {f : perm β} {x y : β} : same_cycle f x (f y) ↔ same_cycle f x y :=
⟨λ ⟨i, hi⟩, ⟨-1 + i, by rw [gpow_add, mul_apply, hi, gpow_neg_one, inv_apply_self]⟩,
 λ ⟨i, hi⟩, ⟨1 + i, by rw [gpow_add, mul_apply, hi, gpow_one]⟩⟩

lemma same_cycle_cycle {f : perm β} {x : β} (hx : f x ≠ x) : is_cycle f ↔
  (∀ {y}, same_cycle f x y ↔ f y ≠ y) :=
⟨λ hf y, ⟨λ ⟨i, hi⟩ hy, hx $
    by { rw [← gpow_apply_eq_self_of_apply_eq_self hy i, (f ^ i).injective.eq_iff] at hi,
      rw [hi, hy] },
  hf.exists_gpow_eq hx⟩,
  λ h, ⟨x, hx, λ y hy, h.2 hy⟩⟩

lemma same_cycle_inv (f : perm β) {x y : β} : same_cycle f⁻¹ x y ↔ same_cycle f x y :=
⟨λ ⟨i, hi⟩, ⟨-i, by rw [gpow_neg, ← inv_gpow, hi]⟩,
 λ ⟨i, hi⟩, ⟨-i, by rw [gpow_neg, ← inv_gpow, inv_inv, hi]⟩ ⟩

lemma same_cycle_inv_apply {f : perm β} {x y : β} : same_cycle f x (f⁻¹ y) ↔ same_cycle f x y :=
by rw [← same_cycle_inv, same_cycle_apply, same_cycle_inv]

/-!
### `cycle_of`
-/

/-- `f.cycle_of x` is the cycle of the permutation `f` to which `x` belongs. -/
def cycle_of [fintype α] (f : perm α) (x : α) : perm α :=
of_subtype (@subtype_perm _ f (same_cycle f x) (λ _, same_cycle_apply.symm))

lemma cycle_of_apply [fintype α] (f : perm α) (x y : α) :
  cycle_of f x y = if same_cycle f x y then f y else y := rfl

lemma cycle_of_inv [fintype α] (f : perm α) (x : α) :
  (cycle_of f x)⁻¹ = cycle_of f⁻¹ x :=
equiv.ext $ λ y, begin
  rw [inv_eq_iff_eq, cycle_of_apply, cycle_of_apply],
  split_ifs; simp [*, same_cycle_inv, same_cycle_inv_apply] at *
end

@[simp] lemma cycle_of_pow_apply_self [fintype α] (f : perm α) (x : α) :
  ∀ n : ℕ, (cycle_of f x ^ n) x = (f ^ n) x
| 0     := rfl
| (n+1) := by { rw [pow_succ, mul_apply, cycle_of_apply,
    cycle_of_pow_apply_self, if_pos, pow_succ, mul_apply],
  exact ⟨n, rfl⟩ }

@[simp] lemma cycle_of_gpow_apply_self [fintype α] (f : perm α) (x : α) :
  ∀ n : ℤ, (cycle_of f x ^ n) x = (f ^ n) x
| (n : ℕ) := cycle_of_pow_apply_self f x n
| -[1+ n] := by rw [gpow_neg_succ_of_nat, ← inv_pow, cycle_of_inv,
  gpow_neg_succ_of_nat, ← inv_pow, cycle_of_pow_apply_self]

lemma same_cycle.cycle_of_apply [fintype α] {f : perm α} {x y : α} (h : same_cycle f x y) :
  cycle_of f x y = f y := dif_pos h

lemma cycle_of_apply_of_not_same_cycle [fintype α] {f : perm α} {x y : α} (h : ¬same_cycle f x y) :
  cycle_of f x y = y := dif_neg h

@[simp] lemma cycle_of_apply_self [fintype α] (f : perm α) (x : α) :
  cycle_of f x x = f x := (same_cycle.refl _ _).cycle_of_apply

lemma is_cycle.cycle_of_eq [fintype α] {f : perm α} (hf : is_cycle f) {x : α} (hx : f x ≠ x) :
  cycle_of f x = f :=
equiv.ext $ λ y,
  if h : same_cycle f x y then by rw [h.cycle_of_apply]
  else by rw [cycle_of_apply_of_not_same_cycle h, not_not.1 (mt ((same_cycle_cycle hx).1 hf).2 h)]

@[simp] lemma cycle_of_eq_one_iff [fintype α] (f : perm α) {x : α} : cycle_of f x = 1 ↔ f x = x :=
begin
  simp_rw [ext_iff, cycle_of_apply, one_apply],
  refine ⟨λ h, (if_pos (same_cycle.refl f x)).symm.trans (h x), λ h y, _⟩,
  by_cases hy : f y = y,
  { rw [hy, if_t_t] },
  { exact if_neg (mt same_cycle.apply_eq_self_iff (by tauto)) },
end

lemma is_cycle.cycle_of [fintype α] {f : perm α} (hf : is_cycle f) {x : α} :
  cycle_of f x = if f x = x then 1 else f :=
begin
  by_cases hx : f x = x,
  { rwa [if_pos hx, cycle_of_eq_one_iff] },
  { rwa [if_neg hx, hf.cycle_of_eq] },
end

lemma cycle_of_one [fintype α] (x : α) : cycle_of 1 x = 1 :=
(cycle_of_eq_one_iff 1).mpr rfl

lemma is_cycle_cycle_of [fintype α] (f : perm α) {x : α} (hx : f x ≠ x) : is_cycle (cycle_of f x) :=
have cycle_of f x x ≠ x, by rwa [(same_cycle.refl _ _).cycle_of_apply],
(same_cycle_cycle this).2 $ λ y,
⟨λ h, mt h.apply_eq_self_iff.2 this,
  λ h, if hxy : same_cycle f x y then
  let ⟨i, hi⟩ := hxy in
  ⟨i, by rw [cycle_of_gpow_apply_self, hi]⟩
  else by { rw [cycle_of_apply_of_not_same_cycle hxy] at h, exact (h rfl).elim }⟩

/-!
### `cycle_factors`
-/

/-- Given a list `l : list α` and a permutation `f : perm α` whose nonfixed points are all in `l`,
  recursively factors `f` into cycles. -/
def cycle_factors_aux [fintype α] : Π (l : list α) (f : perm α),
  (∀ {x}, f x ≠ x → x ∈ l) →
  {l : list (perm α) // l.prod = f ∧ (∀ g ∈ l, is_cycle g) ∧ l.pairwise disjoint}
| []     f h := ⟨[], by { simp only [imp_false, list.pairwise.nil, list.not_mem_nil, forall_const,
    and_true, forall_prop_of_false, not_not, not_false_iff, list.prod_nil] at *,
  ext, simp * }⟩
| (x::l) f h :=
if hx : f x = x then
  cycle_factors_aux l f (λ y hy, list.mem_of_ne_of_mem (λ h, hy (by rwa h)) (h hy))
else let ⟨m, hm₁, hm₂, hm₃⟩ := cycle_factors_aux l ((cycle_of f x)⁻¹ * f)
  (λ y hy, list.mem_of_ne_of_mem
    (λ h : y = x,
      by { rw [h, mul_apply, ne.def, inv_eq_iff_eq, cycle_of_apply_self] at hy, exact hy rfl })
    (h (λ h : f y = y, by { rw [mul_apply, h, ne.def, inv_eq_iff_eq, cycle_of_apply] at hy,
        split_ifs at hy; cc }))) in
    ⟨(cycle_of f x) :: m, by { rw [list.prod_cons, hm₁], simp },
      λ g hg, ((list.mem_cons_iff _ _ _).1 hg).elim (λ hg, hg.symm ▸ is_cycle_cycle_of _ hx)
        (hm₂ g),
      list.pairwise_cons.2 ⟨λ g hg, disjoint_iff_eq_or_eq.mpr $ λ y,
        or_iff_not_imp_left.2 (λ hfy,
          have hxy : same_cycle f x y := not_not.1 (mt cycle_of_apply_of_not_same_cycle hfy),
          have hgm : g :: m.erase g ~ m := list.cons_perm_iff_perm_erase.2 ⟨hg, list.perm.refl _⟩,
          have ∀ h ∈ m.erase g, disjoint g h, from
            (list.pairwise_cons.1 ((hgm.pairwise_iff (λ a b (h : disjoint a b), h.symm)).2 hm₃)).1,
          classical.by_cases id $ λ hgy : g y ≠ y,
            ((disjoint_prod_right _ this).def y).resolve_right $
            have hsc : same_cycle f⁻¹ x (f y), by rwa [same_cycle_inv, same_cycle_apply],
            by { rw [disjoint_prod_perm hm₃ hgm.symm, list.prod_cons,
                ← eq_inv_mul_iff_mul_eq] at hm₁,
              rwa [hm₁, mul_apply, mul_apply, cycle_of_inv, hsc.cycle_of_apply,
                inv_apply_self, inv_eq_iff_eq, eq_comm] }),
        hm₃⟩⟩

/-- Factors a permutation `f` into a list of disjoint cyclic permutations that multiply to `f`. -/
def cycle_factors [fintype α] [linear_order α] (f : perm α) :
  {l : list (perm α) // l.prod = f ∧ (∀ g ∈ l, is_cycle g) ∧ l.pairwise disjoint} :=
cycle_factors_aux (univ.sort (≤)) f (λ _ _, (mem_sort _).2 (mem_univ _))

/-- Factors a permutation `f` into a list of disjoint cyclic permutations that multiply to `f`,
  without a linear order. -/
def trunc_cycle_factors [fintype α] (f : perm α) :
  trunc {l : list (perm α) // l.prod = f ∧ (∀ g ∈ l, is_cycle g) ∧ l.pairwise disjoint} :=
quotient.rec_on_subsingleton (@univ α _).1
  (λ l h, trunc.mk (cycle_factors_aux l f h))
  (show ∀ x, f x ≠ x → x ∈ (@univ α _).1, from λ _ _, mem_univ _)

@[elab_as_eliminator] lemma cycle_induction_on [fintype β] (P : perm β → Prop) (σ : perm β)
  (base_one : P 1) (base_cycles : ∀ σ : perm β, σ.is_cycle → P σ)
  (induction_disjoint : ∀ σ τ : perm β, disjoint σ τ → is_cycle σ → P σ → P τ → P (σ * τ)) :
  P σ :=
begin
  suffices :
    ∀ l : list (perm β), (∀ τ : perm β, τ ∈ l → τ.is_cycle) → l.pairwise disjoint → P l.prod,
  { classical,
    let x := σ.trunc_cycle_factors.out,
    exact (congr_arg P x.2.1).mp (this x.1 x.2.2.1 x.2.2.2) },
  intro l,
  induction l with σ l ih,
  { exact λ _ _, base_one },
  { intros h1 h2,
    rw list.prod_cons,
    exact induction_disjoint σ l.prod
      (disjoint_prod_right _ (list.pairwise_cons.mp h2).1)
      (base_cycles σ (h1 σ (l.mem_cons_self σ)))
      (ih (λ τ hτ, h1 τ (list.mem_cons_of_mem σ hτ)) (list.pairwise_of_pairwise_cons h2)) },
end

section generation

variables [fintype α] [fintype β]

open subgroup

lemma closure_is_cycle : closure {σ : perm β | is_cycle σ} = ⊤ :=
begin
  classical,
  exact top_le_iff.mp (le_trans (ge_of_eq closure_is_swap) (closure_mono (λ _, is_swap.is_cycle))),
end

lemma closure_cycle_adjacent_swap {σ : perm α} (h1 : is_cycle σ) (h2 : σ.support = ⊤) (x : α) :
  closure ({σ, swap x (σ x)} : set (perm α)) = ⊤ :=
begin
  let H := closure ({σ, swap x (σ x)} : set (perm α)),
  have h3 : σ ∈ H := subset_closure (set.mem_insert σ _),
  have h4 : swap x (σ x) ∈ H := subset_closure (set.mem_insert_of_mem _ (set.mem_singleton _)),
  have step1 : ∀ (n : ℕ), swap ((σ ^ n) x) ((σ^(n+1)) x) ∈ H,
  { intro n,
    induction n with n ih,
    { exact subset_closure (set.mem_insert_of_mem _ (set.mem_singleton _)) },
    { convert H.mul_mem (H.mul_mem h3 ih) (H.inv_mem h3),
      rw [mul_swap_eq_swap_mul, mul_inv_cancel_right], refl } },
  have step2 : ∀ (n : ℕ), swap x ((σ ^ n) x) ∈ H,
  { intro n,
    induction n with n ih,
    { convert H.one_mem,
      exact swap_self x },
    { by_cases h5 : x = (σ ^ n) x,
      { rw [pow_succ, mul_apply, ←h5], exact h4 },
      by_cases h6 : x = (σ^(n+1)) x,
      { rw [←h6, swap_self], exact H.one_mem },
      rw [swap_comm, ←swap_mul_swap_mul_swap h5 h6],
      exact H.mul_mem (H.mul_mem (step1 n) ih) (step1 n) } },
  have step3 : ∀ (y : α), swap x y ∈ H,
  { intro y,
    have hx : x ∈ (⊤ : set α) := set.mem_univ x,
    rw [←h2, mem_support] at hx,
    have hy : y ∈ (⊤ : set α) := set.mem_univ y,
    rw [←h2, mem_support] at hy,
    cases is_cycle.exists_pow_eq h1 hx hy with n hn,
    rw ← hn,
    exact step2 n },
  have step4 : ∀ (y z : α), swap y z ∈ H,
  { intros y z,
    by_cases h5 : z = x,
    { rw [h5, swap_comm], exact step3 y },
    by_cases h6 : z = y,
    { rw [h6, swap_self], exact H.one_mem },
    rw [←swap_mul_swap_mul_swap h5 h6, swap_comm z x],
    exact H.mul_mem (H.mul_mem (step3 y) (step3 z)) (step3 y) },
  rw [eq_top_iff, ←closure_is_swap, closure_le],
  rintros τ ⟨y, z, h5, h6⟩,
  rw h6,
  exact step4 y z,
end

lemma closure_cycle_coprime_swap {n : ℕ} {σ : perm α} (h0 : nat.coprime n (fintype.card α))
  (h1 : is_cycle σ) (h2 : σ.support = set.univ) (x : α) :
  closure ({σ, swap x ((σ ^ n) x)} : set (perm α)) = ⊤ :=
begin
  have hσ : σ.support.finite := set.finite.of_fintype (perm.support σ),
  have : fintype.card α = fintype.card σ.support,
    { refine fintype.card_congr (subtype_univ_equiv _).symm,
      simp [h2] },
  rw [this, ←set.finite.card_to_finset, ←order_of_is_cycle h1 hσ] at h0,
  cases exists_pow_eq_self_of_coprime h0 with m hm,
  have h2' : (σ ^ n).support = ⊤ := eq.trans (support_pow_coprime h0) h2,
  have h1' : is_cycle ((σ ^ n) ^ (m : ℤ)) := by rwa ← hm at h1,
  replace h1' : is_cycle (σ ^ n) := is_cycle_of_is_cycle_pow h1'
    (le_trans (support_pow_le σ n) (ge_of_eq (congr_arg support hm))),
  rw [eq_top_iff, ←closure_cycle_adjacent_swap h1' h2' x, closure_le, set.insert_subset],
  exact ⟨subgroup.pow_mem (closure _) (subset_closure (set.mem_insert σ _)) n,
    set.singleton_subset_iff.mpr (subset_closure (set.mem_insert_of_mem _ (set.mem_singleton _)))⟩,
end

lemma closure_prime_cycle_swap {σ τ : perm α} (h0 : (fintype.card α).prime) (h1 : is_cycle σ)
  (h2 : σ.support = set.univ) (h3 : is_swap τ) : closure ({σ, τ} : set (perm α)) = ⊤ :=
begin
  obtain ⟨x, y, h4, h5⟩ := h3,
  obtain ⟨i, hi⟩ := h1.exists_pow_eq (mem_support.mp
  ((set.ext_iff.mp h2 x).mpr (set.mem_univ x)))
    (mem_support.mp ((set.ext_iff.mp h2 y).mpr (set.mem_univ y))),
  have hσ : σ.support.finite := set.finite.of_fintype (perm.support σ),
  have : fintype.card α = fintype.card σ.support,
    { refine fintype.card_congr (subtype_univ_equiv _).symm,
      simp [h2] },
  rw [h5, ←hi],
  refine closure_cycle_coprime_swap (nat.coprime.symm
    (h0.coprime_iff_not_dvd.mpr (λ h, h4 _))) h1 h2 x,
  cases h with m hm,
  rwa [hm, pow_mul, this, ←set.finite.card_to_finset, ←order_of_is_cycle h1 hσ,
    pow_order_of_eq_one, one_pow, one_apply] at hi,
end

end generation

section
variables [fintype α] {σ τ : perm α}

noncomputable theory

lemma is_conj_of_support_equiv {α : Type*} [fintype α] {σ τ : perm α}
  (f : {x // x ∈ (σ.support : set α)} ≃ {x // x ∈ (τ.support : set α)})
  (hf : ∀ (x : α) (hx : x ∈ (σ.support : set α)), (f ⟨σ x, apply_mem_support.2 hx⟩ : α) =
    τ (f ⟨x, hx⟩)) :
  is_conj σ τ :=
begin
  classical,
  refine is_conj_iff.2 ⟨equiv.extend_subtype f, _⟩,
  rw mul_inv_eq_iff_eq_mul,
  ext,
  simp only [perm.mul_apply],
  by_cases hx : x ∈ σ.support,
  { rw [equiv.extend_subtype_apply_of_mem, equiv.extend_subtype_apply_of_mem],
    { exact hf x hx } },
  { rwa [not_not.1 ((not_congr mem_support).1 (equiv.extend_subtype_not_mem f _ _)),
      not_not.1 ((not_congr mem_support).mp hx)] }
end

theorem is_cycle.is_conj (hσ : is_cycle σ) (hτ : is_cycle τ)
  (h : fintype.card σ.support = fintype.card τ.support) :
  is_conj σ τ :=
begin
  refine is_conj_of_support_equiv (hσ.gpowers_equiv_support.symm.trans
    ((gpowers_equiv_gpowers _).trans hτ.gpowers_equiv_support)) _,
  { rwa [order_of_is_cycle hσ, set.finite.card_to_finset,
         order_of_is_cycle hτ, set.finite.card_to_finset];
    simpa using set.finite.of_fintype _ },
  intros x hx,
  simp only [perm.mul_apply, equiv.trans_apply, equiv.sum_congr_apply],
  obtain ⟨n, rfl⟩ := hσ.exists_pow_eq (classical.some_spec hσ).1 (mem_support.1 hx),
  apply eq.trans _ (congr rfl (congr rfl (congr rfl
    (congr rfl (hσ.gpowers_equiv_support_symm_apply n).symm)))),
  apply (congr rfl (congr rfl (congr rfl (hσ.gpowers_equiv_support_symm_apply (n + 1))))).trans _,
  simp only [ne.def, is_cycle.gpowers_equiv_support_apply,
    subtype.coe_mk, gpowers_equiv_gpowers_apply],
  rw [pow_succ, perm.mul_apply],
end

theorem is_cycle.is_conj_iff (hσ : is_cycle σ) (hτ : is_cycle τ) :
  is_conj σ τ ↔ fintype.card σ.support = fintype.card τ.support :=
⟨begin
  intro h,
  obtain ⟨π, rfl⟩ := is_conj_iff.1 h,
  refine fintype.card_congr _,
  refine (subtype_equiv π⁻¹ _).symm,
  intro,
  simp [eq_inv_iff_eq]
end, hσ.is_conj hτ⟩

@[simp]
lemma support_conj : (σ * τ * σ⁻¹).support = τ.support.map σ.to_embedding :=
begin
  ext,
  simp only [mem_map_equiv, perm.coe_mul, comp_app, ne.def, perm.mem_support, equiv.eq_symm_apply],
  refl,
end

lemma card_support_conj : (σ * τ * σ⁻¹).support.card = τ.support.card :=
by simp

end

theorem disjoint.is_conj_mul {α : Type*} [fintype α] {σ τ π ρ : perm α}
  (hc1 : is_conj σ π) (hc2 : is_conj τ ρ)
  (hd1 : disjoint σ τ) (hd2 : disjoint π ρ) :
  is_conj (σ * τ) (π * ρ) :=
begin
  classical,
  obtain ⟨f, rfl⟩ := is_conj_iff.1 hc1,
  obtain ⟨g, rfl⟩ := is_conj_iff.1 hc2,
  have hd1' := coe_inj.2 hd1.support_mul,
  have hd2' := coe_inj.2 hd2.support_mul,
  rw [coe_union] at *,
  have hd1'' := disjoint_iff_disjoint_coe.1 (disjoint_iff_disjoint_support.1 hd1),
  have hd2'' := disjoint_iff_disjoint_coe.1 (disjoint_iff_disjoint_support.1 hd2),
  refine is_conj_of_support_equiv _ _,
  { refine ((equiv.set.of_eq hd1').trans (equiv.set.union hd1'')).trans
      ((equiv.sum_congr (subtype_equiv f (λ a, _)) (subtype_equiv g (λ a, _))).trans
      ((equiv.set.of_eq hd2').trans (equiv.set.union hd2'')).symm);
    { simp only [set.mem_image, to_embedding_apply, exists_eq_right,
        support_conj, coe_map, apply_eq_iff_eq] } },
  { intros x hx,
    simp only [trans_apply, symm_trans_apply, set.of_eq_apply,
      set.of_eq_symm_apply, equiv.sum_congr_apply],
    rw [hd1', set.mem_union] at hx,
    cases hx with hxσ hxτ,
    { rw [mem_coe, mem_support] at hxσ,
      rw [set.union_apply_left hd1'' _, set.union_apply_left hd1'' _],
      simp only [subtype_equiv_apply, perm.coe_mul, sum.map_inl, comp_app,
        set.union_symm_apply_left, subtype.coe_mk, apply_eq_iff_eq],
      { have h := (hd2 (f x)).resolve_left _,
        { rw [mul_apply, mul_apply] at h,
          rw [h, inv_apply_self, (hd1 x).resolve_left hxσ] },
        { rwa [mul_apply, mul_apply, inv_apply_self, apply_eq_iff_eq] } },
      { rwa [subtype.coe_mk, subtype.coe_mk, mem_coe, mem_support] },
      { rwa [subtype.coe_mk, subtype.coe_mk, perm.mul_apply,
          (hd1 x).resolve_left hxσ, mem_coe, apply_mem_support, mem_support] } },
    { rw [mem_coe, ← apply_mem_support, mem_support] at hxτ,
      rw [set.union_apply_right hd1'' _, set.union_apply_right hd1'' _],
      simp only [subtype_equiv_apply, perm.coe_mul, sum.map_inr, comp_app,
        set.union_symm_apply_right, subtype.coe_mk, apply_eq_iff_eq],
      { have h := (hd2 (g (τ x))).resolve_right _,
        { rw [mul_apply, mul_apply] at h,
          rw [inv_apply_self, h, (hd1 (τ x)).resolve_right hxτ] },
        { rwa [mul_apply, mul_apply, inv_apply_self, apply_eq_iff_eq] } },
      { rwa [subtype.coe_mk, subtype.coe_mk, mem_coe, ← apply_mem_support, mem_support] },
      { rwa [subtype.coe_mk, subtype.coe_mk, perm.mul_apply,
          (hd1 (τ x)).resolve_right hxτ, mem_coe, mem_support] } } }
end

section fixed_points

/-!
### Fixed points
-/

lemma fixed_point_card_lt_of_ne_one [fintype α] {σ : perm α} (h : σ ≠ 1) :
  (filter (λ x, σ x = x) univ).card < fintype.card α - 1 :=
begin
  rw [nat.lt_sub_left_iff_add_lt, ← nat.lt_sub_right_iff_add_lt, ← finset.card_compl,
      finset.compl_filter],
  have hf : σ.support.finite := set.finite.of_fintype (perm.support σ),
  have : (filter (λ x, σ x ≠ x) univ) = hf.to_finset,
    { simp [finset.ext_iff] },
  rw this,
  exact one_lt_card_support_of_ne_one hf h
end

end fixed_points

end equiv.perm
