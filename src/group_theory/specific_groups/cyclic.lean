/-
Copyright (c) 2018 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl
-/

import algebra.big_operators.order
import data.nat.totient
import group_theory.order_of_element
import tactic.group
import group_theory.exponent

/-!
# Cyclic groups

A group `G` is called cyclic if there exists an element `g : G` such that every element of `G` is of
the form `g ^ n` for some `n : ℕ`. This file only deals with the predicate on a group to be cyclic.
For the concrete cyclic group of order `n`, see `data.zmod.basic`.

## Main definitions

* `is_cyclic` is a predicate on a group stating that the group is cyclic.

## Main statements

* `is_cyclic_of_prime_card` proves that a finite group of prime order is cyclic.
* `is_simple_group_of_prime_card`, `is_simple_group.is_cyclic`,
  and `is_simple_group.prime_card` classify finite simple abelian groups.
* `is_cyclic.exponent_eq_card`: For a finite cyclic group `G`, the exponent is equal to
  the group's cardinality.
* `is_cyclic.exponent_eq_zero_of_infinite`: Infinite cyclic groups have exponent zero.
* `is_cyclic.iff_exponent_eq_card`: A finite commutative group is cyclic iff its exponent
  is equal to its cardinality.

## Tags

cyclic group
-/

universe u
variables {α : Type u} {a : α}

section cyclic

open_locale big_operators

local attribute [instance] set_fintype

open subgroup

/-- A group is called *cyclic* if it is generated by a single element. -/
class is_add_cyclic (α : Type u) [add_group α] : Prop :=
(exists_generator [] : ∃ g : α, ∀ x, x ∈ add_subgroup.zmultiples g)

/-- A group is called *cyclic* if it is generated by a single element. -/
@[to_additive is_add_cyclic] class is_cyclic (α : Type u) [group α] : Prop :=
(exists_generator [] : ∃ g : α, ∀ x, x ∈ zpowers g)

@[priority 100, to_additive is_add_cyclic_of_subsingleton]
instance is_cyclic_of_subsingleton [group α] [subsingleton α] : is_cyclic α :=
⟨⟨1, λ x, by { rw subsingleton.elim x 1, exact mem_zpowers 1 }⟩⟩

/-- A cyclic group is always commutative. This is not an `instance` because often we have a better
proof of `comm_group`. -/
@[to_additive "A cyclic group is always commutative. This is not an `instance` because often we have
  a better proof of `add_comm_group`."]
def is_cyclic.comm_group [hg : group α] [is_cyclic α] : comm_group α :=
{ mul_comm := λ x y,
    let ⟨g, hg⟩ := is_cyclic.exists_generator α,
        ⟨n, hn⟩ := hg x,
        ⟨m, hm⟩ := hg y in
    hm ▸ hn ▸ zpow_mul_comm _ _ _,
  ..hg }

variables [group α]

@[to_additive monoid_add_hom.map_add_cyclic]
lemma monoid_hom.map_cyclic {G : Type*} [group G] [h : is_cyclic G] (σ : G →* G) :
  ∃ m : ℤ, ∀ g : G, σ g = g ^ m :=
begin
  obtain ⟨h, hG⟩ := is_cyclic.exists_generator G,
  obtain ⟨m, hm⟩ := hG (σ h),
  refine ⟨m, λ g, _⟩,
  obtain ⟨n, rfl⟩ := hG g,
  rw [monoid_hom.map_zpow, ←hm, ←zpow_mul, ←zpow_mul'],
end

@[to_additive is_add_cyclic_of_order_of_eq_card]
lemma is_cyclic_of_order_of_eq_card [fintype α]  (x : α)
   (hx : order_of x = fintype.card α) : is_cyclic α :=
begin
  classical,
  use x,
  simp_rw [← set_like.mem_coe, ← set.eq_univ_iff_forall],
  apply set.eq_of_subset_of_card_le (set.subset_univ _),
  rw [fintype.card_congr (equiv.set.univ α), ← hx, order_eq_card_zpowers],
end

/-- A finite group of prime order is cyclic. -/
@[to_additive is_add_cyclic_of_prime_card]
lemma is_cyclic_of_prime_card {α : Type u} [group α] [fintype α] {p : ℕ} [hp : fact p.prime]
  (h : fintype.card α = p) : is_cyclic α :=
⟨begin
  obtain ⟨g, hg⟩ : ∃ g : α, g ≠ 1 := fintype.exists_ne_of_one_lt_card (h.symm ▸ hp.1.one_lt) 1,
  classical, -- for fintype (subgroup.zpowers g)
  have : fintype.card (subgroup.zpowers g) ∣ p,
  { rw ←h,
    apply card_subgroup_dvd_card },
  rw nat.dvd_prime hp.1 at this,
  cases this,
  { rw fintype.card_eq_one_iff at this,
    cases this with t ht,
    suffices : g = 1,
    { contradiction },
    have hgt := ht ⟨g, by { change g ∈ subgroup.zpowers g, exact subgroup.mem_zpowers g }⟩,
    rw [←ht 1] at hgt,
    change (⟨_, _⟩ : subgroup.zpowers g) = ⟨_, _⟩ at hgt,
    simpa using hgt },
  { use g,
    intro x,
    rw [←h] at this,
    rw subgroup.eq_top_of_card_eq _ this,
    exact subgroup.mem_top _ }
end⟩

@[to_additive add_order_of_eq_card_of_forall_mem_zmultiples]
lemma order_of_eq_card_of_forall_mem_zpowers [fintype α]
  {g : α} (hx : ∀ x, x ∈ zpowers g) : order_of g = fintype.card α :=
begin
  classical,
  simp_rw [order_eq_card_zpowers, set_like.coe_sort_coe],
  apply fintype.card_of_finset',
  simpa using hx
end

@[to_additive infinite.add_order_of_eq_zero_of_forall_mem_zmultiples]
lemma infinite.order_of_eq_zero_of_forall_mem_zpowers [infinite α] {g : α}
  (h : ∀ x, x ∈ zpowers g) : order_of g = 0 :=
begin
  classical,
  rw order_of_eq_zero_iff',
  refine λ n hn hgn, _,
  have ho := order_of_pos' ((is_of_fin_order_iff_pow_eq_one g).mpr ⟨n, hn, hgn⟩),
  obtain ⟨x, hx⟩ := infinite.exists_not_mem_finset
                    (finset.image (pow g) $ finset.range $ order_of g),
  apply hx,
  rw [←mem_powers_iff_mem_range_order_of' g x ho, submonoid.mem_powers_iff],
  obtain ⟨k, hk⟩ := h x,
  obtain ⟨k, rfl | rfl⟩ := k.eq_coe_or_neg,
  { exact ⟨k, by exact_mod_cast hk⟩ },
  let t : ℤ := -k % (order_of g),
  rw zpow_eq_mod_order_of at hk,
  have : 0 ≤ t := int.mod_nonneg (-k) (by exact_mod_cast ho.ne'),
  refine ⟨t.to_nat, _⟩,
  rwa [←zpow_coe_nat, int.to_nat_of_nonneg this]
end

@[to_additive bot.is_add_cyclic]
instance bot.is_cyclic {α : Type u} [group α] : is_cyclic (⊥ : subgroup α) :=
⟨⟨1, λ x, ⟨0, subtype.eq $ eq.symm (subgroup.mem_bot.1 x.2)⟩⟩⟩

@[to_additive add_subgroup.is_add_cyclic]
instance subgroup.is_cyclic {α : Type u} [group α] [is_cyclic α] (H : subgroup α) : is_cyclic H :=
by haveI := classical.prop_decidable; exact
let ⟨g, hg⟩ := is_cyclic.exists_generator α in
if hx : ∃ (x : α), x ∈ H ∧ x ≠ (1 : α) then
  let ⟨x, hx₁, hx₂⟩ := hx in
  let ⟨k, hk⟩ := hg x in
  have hex : ∃ n : ℕ, 0 < n ∧ g ^ n ∈ H,
    from ⟨k.nat_abs, nat.pos_of_ne_zero
      (λ h, hx₂ $ by rw [← hk, int.eq_zero_of_nat_abs_eq_zero h, zpow_zero]),
        match k, hk with
        | (k : ℕ), hk := by rw [int.nat_abs_of_nat, ← zpow_coe_nat, hk]; exact hx₁
        | -[1+ k], hk := by rw [int.nat_abs_of_neg_succ_of_nat,
          ← subgroup.inv_mem_iff H]; simp * at *
        end⟩,
  ⟨⟨⟨g ^ nat.find hex, (nat.find_spec hex).2⟩,
    λ ⟨x, hx⟩, let ⟨k, hk⟩ := hg x in
      have hk₁ : g ^ ((nat.find hex : ℤ) * (k / nat.find hex)) ∈ zpowers (g ^ nat.find hex),
        from ⟨k / nat.find hex, by rw [← zpow_coe_nat, zpow_mul]⟩,
      have hk₂ : g ^ ((nat.find hex : ℤ) * (k / nat.find hex)) ∈ H,
        by { rw zpow_mul, apply H.zpow_mem, exact_mod_cast (nat.find_spec hex).2 },
      have hk₃ : g ^ (k % nat.find hex) ∈ H,
        from (subgroup.mul_mem_cancel_right H hk₂).1 $
          by rw [← zpow_add, int.mod_add_div, hk]; exact hx,
      have hk₄ : k % nat.find hex = (k % nat.find hex).nat_abs,
        by rw int.nat_abs_of_nonneg (int.mod_nonneg _
          (int.coe_nat_ne_zero_iff_pos.2 (nat.find_spec hex).1)),
      have hk₅ : g ^ (k % nat.find hex ).nat_abs ∈ H,
        by rwa [← zpow_coe_nat, ← hk₄],
      have hk₆ : (k % (nat.find hex : ℤ)).nat_abs = 0,
        from by_contradiction (λ h,
          nat.find_min hex (int.coe_nat_lt.1 $ by rw [← hk₄];
            exact int.mod_lt_of_pos _ (int.coe_nat_pos.2 (nat.find_spec hex).1))
          ⟨nat.pos_of_ne_zero h, hk₅⟩),
      ⟨k / (nat.find hex : ℤ), subtype.ext_iff_val.2 begin
        suffices : g ^ ((nat.find hex : ℤ) * (k / nat.find hex)) = x,
        { simpa [zpow_mul] },
        rw [int.mul_div_cancel' (int.dvd_of_mod_eq_zero (int.eq_zero_of_nat_abs_eq_zero hk₆)), hk]
      end⟩⟩⟩
else
  have H = (⊥ : subgroup α), from subgroup.ext $ λ x, ⟨λ h, by simp at *; tauto,
    λ h, by rw [subgroup.mem_bot.1 h]; exact H.one_mem⟩,
  by clear _let_match; substI this; apply_instance

open finset nat

section classical

open_locale classical

@[to_additive is_add_cyclic.card_pow_eq_one_le]
lemma is_cyclic.card_pow_eq_one_le [decidable_eq α] [fintype α] [is_cyclic α] {n : ℕ}
  (hn0 : 0 < n) : (univ.filter (λ a : α, a ^ n = 1)).card ≤ n :=
let ⟨g, hg⟩ := is_cyclic.exists_generator α in
calc (univ.filter (λ a : α, a ^ n = 1)).card
  ≤ ((zpowers (g ^ (fintype.card α / (nat.gcd n (fintype.card α))))) : set α).to_finset.card :
  card_le_of_subset (λ x hx, let ⟨m, hm⟩ := show x ∈ submonoid.powers g,
    from mem_powers_iff_mem_zpowers.2 $ hg x in
    set.mem_to_finset.2 ⟨(m / (fintype.card α / (nat.gcd n (fintype.card α))) : ℕ),
      have hgmn : g ^ (m * nat.gcd n (fintype.card α)) = 1,
        by rw [pow_mul, hm, ← pow_gcd_card_eq_one_iff]; exact (mem_filter.1 hx).2,
      begin
        rw [zpow_coe_nat, ← pow_mul, nat.mul_div_cancel_left', hm],
        refine dvd_of_mul_dvd_mul_right (gcd_pos_of_pos_left (fintype.card α) hn0) _,
        conv_lhs
        { rw [nat.div_mul_cancel (nat.gcd_dvd_right _ _),
              ←order_of_eq_card_of_forall_mem_zpowers hg] },
        exact order_of_dvd_of_pow_eq_one hgmn
      end⟩)
... ≤ n :
  let ⟨m, hm⟩ := nat.gcd_dvd_right n (fintype.card α) in
  have hm0 : 0 < m, from nat.pos_of_ne_zero $
    λ hm0, by { rw [hm0, mul_zero, fintype.card_eq_zero_iff] at hm, exact hm.elim' 1 },
  begin
    rw [← fintype.card_of_finset' _ (λ _, set.mem_to_finset), ← order_eq_card_zpowers,
        order_of_pow g, order_of_eq_card_of_forall_mem_zpowers hg],
    rw [hm] {occs := occurrences.pos [2,3]},
    rw [nat.mul_div_cancel_left _  (gcd_pos_of_pos_left _ hn0), gcd_mul_left_left,
      hm, nat.mul_div_cancel _ hm0],
    exact le_of_dvd hn0 (nat.gcd_dvd_left _ _)
  end

end classical

@[to_additive]
lemma is_cyclic.exists_monoid_generator [fintype α]
[is_cyclic α] : ∃ x : α, ∀ y : α, y ∈ submonoid.powers x :=
by { simp_rw [mem_powers_iff_mem_zpowers], exact is_cyclic.exists_generator α }

section

variables [decidable_eq α] [fintype α]

@[to_additive]
lemma is_cyclic.image_range_order_of (ha : ∀ x : α, x ∈ zpowers a) :
  finset.image (λ i, a ^ i) (range (order_of a)) = univ :=
begin
  simp_rw [←set_like.mem_coe] at ha,
  simp only [image_range_order_of, set.eq_univ_iff_forall.mpr ha],
  convert set.to_finset_univ
end

@[to_additive]
lemma is_cyclic.image_range_card (ha : ∀ x : α, x ∈ zpowers a) :
  finset.image (λ i, a ^ i) (range (fintype.card α)) = univ :=
by rw [← order_of_eq_card_of_forall_mem_zpowers ha, is_cyclic.image_range_order_of ha]

end

section totient

variables [decidable_eq α] [fintype α]
(hn : ∀ n : ℕ, 0 < n → (univ.filter (λ a : α, a ^ n = 1)).card ≤ n)

include hn

private lemma card_pow_eq_one_eq_order_of_aux (a : α) :
  (finset.univ.filter (λ b : α, b ^ order_of a = 1)).card = order_of a :=
le_antisymm
  (hn _ (order_of_pos a))
  (calc order_of a = @fintype.card (zpowers a) (id _) : order_eq_card_zpowers
    ... ≤ @fintype.card (↑(univ.filter (λ b : α, b ^ order_of a = 1)) : set α)
    (fintype.of_finset _ (λ _, iff.rfl)) :
      @fintype.card_le_of_injective (zpowers a)
        (↑(univ.filter (λ b : α, b ^ order_of a = 1)) : set α)
        (id _) (id _) (λ b, ⟨b.1, mem_filter.2 ⟨mem_univ _,
          let ⟨i, hi⟩ := b.2 in
          by rw [← hi, ← zpow_coe_nat, ← zpow_mul, mul_comm, zpow_mul, zpow_coe_nat,
            pow_order_of_eq_one, one_zpow]⟩⟩) (λ _ _ h, subtype.eq (subtype.mk.inj h))
    ... = (univ.filter (λ b : α, b ^ order_of a = 1)).card : fintype.card_of_finset _ _)

open_locale nat -- use φ for nat.totient

private lemma card_order_of_eq_totient_aux₁ :
  ∀ {d : ℕ}, d ∣ fintype.card α → 0 < (univ.filter (λ a : α, order_of a = d)).card →
  (univ.filter (λ a : α, order_of a = d)).card = φ d
| 0     := λ hd hd0,
let ⟨a, ha⟩ := card_pos.1 hd0 in absurd (mem_filter.1 ha).2 $ ne_of_gt $ order_of_pos a
| (d+1) := λ hd hd0,
let ⟨a, ha⟩ := card_pos.1 hd0 in
have ha : order_of a = d.succ, from (mem_filter.1 ha).2,
have h : ∑ m in (range d.succ).filter (∣ d.succ),
    (univ.filter (λ a : α, order_of a = m)).card =
    ∑ m in (range d.succ).filter (∣ d.succ), φ m, from
  finset.sum_congr rfl
    (λ m hm, have hmd : m < d.succ, from mem_range.1 (mem_filter.1 hm).1,
      have hm : m ∣ d.succ, from (mem_filter.1 hm).2,
      card_order_of_eq_totient_aux₁ (hm.trans hd) (finset.card_pos.2
        ⟨a ^ (d.succ / m), mem_filter.2 ⟨mem_univ _,
          by { rw [order_of_pow a, ha, nat.gcd_eq_right (div_dvd_of_dvd hm),
                nat.div_div_self hm (succ_pos _)] }⟩⟩)),
have hinsert : insert d.succ ((range d.succ).filter (∣ d.succ))
    = (range d.succ.succ).filter (∣ d.succ),
  from (finset.ext $ λ x, ⟨λ h, (mem_insert.1 h).elim (λ h, by simp [h, range_succ])
    (by clear _let_match; simp [range_succ]; tauto),
     by clear _let_match; simp [range_succ] {contextual := tt}; tauto⟩),
have hinsert₁ : d.succ ∉ (range d.succ).filter (∣ d.succ),
  by simp [mem_range, zero_le_one, le_succ],
(add_left_inj (∑ m in (range d.succ).filter (∣ d.succ),
  (univ.filter (λ a : α, order_of a = m)).card)).1
  (calc _ = ∑ m in insert d.succ (filter (∣ d.succ) (range d.succ)),
        (univ.filter (λ a : α, order_of a = m)).card :
    eq.symm (finset.sum_insert (by simp [mem_range, zero_le_one, le_succ]))
  ... = ∑ m in (range d.succ.succ).filter (∣ d.succ),
      (univ.filter (λ a : α, order_of a = m)).card :
    sum_congr hinsert (λ _ _, rfl)
  ... = (univ.filter (λ a : α, a ^ d.succ = 1)).card :
    sum_card_order_of_eq_card_pow_eq_one (succ_pos d)
  ... = ∑ m in (range d.succ.succ).filter (∣ d.succ), φ m :
    ha ▸ (card_pow_eq_one_eq_order_of_aux hn a).symm ▸ (sum_totient _).symm
  ... = _ : by rw [h, ← sum_insert hinsert₁];
      exact finset.sum_congr hinsert.symm (λ _ _, rfl))

lemma card_order_of_eq_totient_aux₂ {d : ℕ} (hd : d ∣ fintype.card α) :
  (univ.filter (λ a : α, order_of a = d)).card = φ d :=
by_contradiction $ λ h,
have h0 : (univ.filter (λ a : α , order_of a = d)).card = 0 :=
  not_not.1 (mt pos_iff_ne_zero.2 (mt (card_order_of_eq_totient_aux₁ hn hd) h)),
let c := fintype.card α in
have hc0 : 0 < c, from fintype.card_pos_iff.2 ⟨1⟩,
lt_irrefl c $
  calc c = (univ.filter (λ a : α, a ^ c = 1)).card :
    congr_arg card $ by simp [finset.ext_iff, c]
  ... = ∑ m in (range c.succ).filter (∣ c),
      (univ.filter (λ a : α, order_of a = m)).card :
    (sum_card_order_of_eq_card_pow_eq_one hc0).symm
  ... = ∑ m in ((range c.succ).filter (∣ c)).erase d,
      (univ.filter (λ a : α, order_of a = m)).card :
    eq.symm (sum_subset (erase_subset _ _) (λ m hm₁ hm₂,
      have m = d, by simp at *; cc,
      by simp [*, finset.ext_iff] at *; exact h0))
  ... ≤ ∑ m in ((range c.succ).filter (∣ c)).erase d, φ m :
    sum_le_sum (λ m hm,
      have hmc : m ∣ c, by simp at hm; tauto,
      (imp_iff_not_or.1 (card_order_of_eq_totient_aux₁ hn hmc)).elim
        (λ h, by simp [nat.le_zero_iff.1 (le_of_not_gt h), nat.zero_le])
        (λ h, by rw h))
  ... < φ d + ∑ m in ((range c.succ).filter (∣ c)).erase d, φ m :
    lt_add_of_pos_left _ (totient_pos (nat.pos_of_ne_zero
      (λ h, pos_iff_ne_zero.1 hc0 (eq_zero_of_zero_dvd $ h ▸ hd))))
  ... = ∑ m in insert d (((range c.succ).filter (∣ c)).erase d), φ m :
    eq.symm (sum_insert (by simp))
  ... = ∑ m in (range c.succ).filter (∣ c), φ m : finset.sum_congr
      (finset.insert_erase (mem_filter.2 ⟨mem_range.2 (lt_succ_of_le (le_of_dvd hc0 hd)), hd⟩))
                           (λ _ _, rfl)
  ... = c : sum_totient _

lemma is_cyclic_of_card_pow_eq_one_le : is_cyclic α :=
have (univ.filter (λ a : α, order_of a = fintype.card α)).nonempty,
from (card_pos.1 $
  by rw [card_order_of_eq_totient_aux₂ hn dvd_rfl];
  exact totient_pos (fintype.card_pos_iff.2 ⟨1⟩)),
let ⟨x, hx⟩ := this in
is_cyclic_of_order_of_eq_card x (finset.mem_filter.1 hx).2

lemma is_add_cyclic_of_card_pow_eq_one_le {α} [add_group α] [decidable_eq α] [fintype α]
  (hn : ∀ n : ℕ, 0 < n → (univ.filter (λ a : α, n • a = 0)).card ≤ n) : is_add_cyclic α :=
begin
  obtain ⟨g, hg⟩ := @is_cyclic_of_card_pow_eq_one_le (multiplicative α) _ _ _ hn,
  exact ⟨⟨g, hg⟩⟩
end

attribute [to_additive is_cyclic_of_card_pow_eq_one_le] is_add_cyclic_of_card_pow_eq_one_le

end totient

lemma is_cyclic.card_order_of_eq_totient [is_cyclic α] [fintype α]
  {d : ℕ} (hd : d ∣ fintype.card α) : (univ.filter (λ a : α, order_of a = d)).card = totient d :=
begin
  classical,
  apply card_order_of_eq_totient_aux₂ (λ n, is_cyclic.card_pow_eq_one_le) hd
end

lemma is_add_cyclic.card_order_of_eq_totient {α} [add_group α] [is_add_cyclic α] [fintype α] {d : ℕ}
  (hd : d ∣ fintype.card α) : (univ.filter (λ a : α, add_order_of a = d)).card = totient d :=
begin
  obtain ⟨g, hg⟩ := id ‹is_add_cyclic α›,
  exact @is_cyclic.card_order_of_eq_totient (multiplicative α) _ ⟨⟨g, hg⟩⟩ _ _ hd
end

attribute [to_additive is_cyclic.card_order_of_eq_totient] is_add_cyclic.card_order_of_eq_totient

/-- A finite group of prime order is simple. -/
@[to_additive]
lemma is_simple_group_of_prime_card {α : Type u} [group α] [fintype α] {p : ℕ} [hp : fact p.prime]
  (h : fintype.card α = p) : is_simple_group α :=
⟨begin
  have h' := nat.prime.one_lt (fact.out p.prime),
  rw ← h at h',
  haveI := fintype.one_lt_card_iff_nontrivial.1 h',
  apply exists_pair_ne α,
end, λ H Hn, begin
  classical,
  have hcard := card_subgroup_dvd_card H,
  rw [h, dvd_prime (fact.out p.prime)] at hcard,
  refine hcard.imp (λ h1, _) (λ hp, _),
  { haveI := fintype.card_le_one_iff_subsingleton.1 (le_of_eq h1),
    apply eq_bot_of_subsingleton },
  { exact eq_top_of_card_eq _ (hp.trans h.symm) }
end⟩

end cyclic

section quotient_center

open subgroup

variables {G : Type*} {H : Type*} [group G] [group H]

/-- A group is commutative if the quotient by the center is cyclic.
  Also see `comm_group_of_cycle_center_quotient` for the `comm_group` instance. -/
@[to_additive commutative_of_add_cyclic_center_quotient "A group is commutative if the quotient by
  the center is cyclic. Also see `add_comm_group_of_cycle_center_quotient`
  for the `add_comm_group` instance."]
lemma commutative_of_cyclic_center_quotient [is_cyclic H] (f : G →* H)
  (hf : f.ker ≤ center G) (a b : G) : a * b = b * a :=
let ⟨⟨x, y, (hxy : f y = x)⟩, (hx : ∀ a : f.range, a ∈ zpowers _)⟩ :=
  is_cyclic.exists_generator f.range in
let ⟨m, hm⟩ := hx ⟨f a, a, rfl⟩ in
let ⟨n, hn⟩ := hx ⟨f b, b, rfl⟩ in
have hm : x ^ m = f a, by simpa [subtype.ext_iff] using hm,
have hn : x ^ n = f b, by simpa [subtype.ext_iff] using hn,
have ha : y ^ (-m) * a ∈ center G,
  from hf (by rw [f.mem_ker, f.map_mul, f.map_zpow, hxy, zpow_neg, hm, inv_mul_self]),
have hb : y ^ (-n) * b ∈ center G,
  from hf (by rw [f.mem_ker, f.map_mul, f.map_zpow, hxy, zpow_neg, hn, inv_mul_self]),
calc a * b = y ^ m * ((y ^ (-m) * a) * y ^ n) * (y ^ (-n) * b) : by simp [mul_assoc]
... = y ^ m * (y ^ n * (y ^ (-m) * a)) * (y ^ (-n) * b) : by rw [mem_center_iff.1 ha]
... = y ^ m * y ^ n * y ^ (-m) * (a * (y ^ (-n) * b)) : by simp [mul_assoc]
... = y ^ m * y ^ n * y ^ (-m) * ((y ^ (-n) * b) * a) : by rw [mem_center_iff.1 hb]
... = b * a : by group

/-- A group is commutative if the quotient by the center is cyclic. -/
@[to_additive commutative_of_add_cycle_center_quotient "A group is commutative if the quotient by
  the center is cyclic."]
def comm_group_of_cycle_center_quotient [is_cyclic H] (f : G →* H)
  (hf : f.ker ≤ center G) : comm_group G :=
{ mul_comm := commutative_of_cyclic_center_quotient f hf,
  ..show group G, by apply_instance }

end quotient_center

namespace is_simple_group

section comm_group
variables [comm_group α] [is_simple_group α]

@[priority 100, to_additive is_simple_add_group.is_add_cyclic]
instance : is_cyclic α :=
begin
  cases subsingleton_or_nontrivial α with hi hi; haveI := hi,
  { apply is_cyclic_of_subsingleton },
  { obtain ⟨g, hg⟩ := exists_ne (1 : α),
    refine ⟨⟨g, λ x, _⟩⟩,
    cases is_simple_order.eq_bot_or_eq_top (subgroup.zpowers g) with hb ht,
    { exfalso,
      apply hg,
      rw [← subgroup.mem_bot, ← hb],
      apply subgroup.mem_zpowers },
    { rw ht,
      apply subgroup.mem_top } }
end

@[to_additive]
theorem prime_card [fintype α] : (fintype.card α).prime :=
begin
  have h0 : 0 < fintype.card α := fintype.card_pos_iff.2 (by apply_instance),
  obtain ⟨g, hg⟩ := is_cyclic.exists_generator α,
  refine ⟨fintype.one_lt_card_iff_nontrivial.2 infer_instance, λ n hn, _⟩,
  refine (is_simple_order.eq_bot_or_eq_top (subgroup.zpowers (g ^ n))).symm.imp _ _,
  { intro h,
    have hgo := order_of_pow g,
    rw [order_of_eq_card_of_forall_mem_zpowers hg, nat.gcd_eq_right_iff_dvd.1 hn,
      order_of_eq_card_of_forall_mem_zpowers, eq_comm,
      nat.div_eq_iff_eq_mul_left (nat.pos_of_dvd_of_pos hn h0) hn] at hgo,
    { exact (mul_left_cancel₀ (ne_of_gt h0) ((mul_one (fintype.card α)).trans hgo)).symm },
    { intro x,
      rw h,
      exact subgroup.mem_top _ } },
  { intro h,
    apply le_antisymm (nat.le_of_dvd h0 hn),
    rw ← order_of_eq_card_of_forall_mem_zpowers hg,
    apply order_of_le_of_pow_eq_one (nat.pos_of_dvd_of_pos hn h0),
    rw [← subgroup.mem_bot, ← h],
    exact subgroup.mem_zpowers _ }
end

end comm_group

end is_simple_group

@[to_additive add_comm_group.is_simple_iff_is_add_cyclic_and_prime_card]
theorem comm_group.is_simple_iff_is_cyclic_and_prime_card [fintype α] [comm_group α] :
  is_simple_group α ↔ is_cyclic α ∧ (fintype.card α).prime :=
begin
  split,
  { introI h,
    exact ⟨is_simple_group.is_cyclic, is_simple_group.prime_card⟩ },
  { rintro ⟨hc, hp⟩,
    haveI : fact (fintype.card α).prime := ⟨hp⟩,
    exact is_simple_group_of_prime_card rfl }
end

section exponent

open monoid

@[to_additive] lemma is_cyclic.exponent_eq_card [group α] [is_cyclic α] [fintype α] :
  exponent α = fintype.card α :=
begin
  obtain ⟨g, hg⟩ := is_cyclic.exists_generator α,
  apply nat.dvd_antisymm,
  { rw [←lcm_order_eq_exponent, finset.lcm_dvd_iff],
    exact λ b _, order_of_dvd_card_univ },
  rw ←order_of_eq_card_of_forall_mem_zpowers hg,
  exact order_dvd_exponent _
end

@[to_additive] lemma is_cyclic.of_exponent_eq_card [comm_group α] [fintype α]
  (h : exponent α = fintype.card α) : is_cyclic α :=
let ⟨g, _, hg⟩ := finset.mem_image.mp (finset.max'_mem _ _) in
is_cyclic_of_order_of_eq_card g $ hg.trans $ exponent_eq_max'_order_of.symm.trans h

@[to_additive] lemma is_cyclic.iff_exponent_eq_card [comm_group α] [fintype α] :
  is_cyclic α ↔ exponent α = fintype.card α :=
⟨λ h, by exactI is_cyclic.exponent_eq_card, is_cyclic.of_exponent_eq_card⟩

@[to_additive] lemma is_cyclic.exponent_eq_zero_of_infinite [group α] [is_cyclic α] [infinite α] :
  exponent α = 0 :=
let ⟨g, hg⟩ := is_cyclic.exists_generator α in
exponent_eq_zero_of_order_zero $ infinite.order_of_eq_zero_of_forall_mem_zpowers hg

end exponent
