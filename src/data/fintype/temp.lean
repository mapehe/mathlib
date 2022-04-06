import data.finset.sort
import data.fintype.basic
import data.fintype.sort
import order.monovary
import group_theory.perm.support
import data.list.sort


section

#eval list.argmax (λ x, (x - 1) * (x - 2)) [1, 2, 1, 2]

section preorder

variables {α : Type*} {β : Type*} [preorder β] [@decidable_rel β (≤)] {l : list α}

open list

private theorem foldl_argmax₂_mem (f : α → β) (l) : Π (a m : α),
  m ∈ foldl (argmax₂ f) (some a) l → m ∈ a :: l :=
list.reverse_rec_on l (by simp [eq_comm])
  begin
    assume tl hd ih a m,
    simp only [foldl_append, foldl_cons, foldl_nil, argmax₂],
    cases hf : foldl (argmax₂ f) (some a) tl,
    { simp {contextual := tt} },
    { dsimp only, split_ifs,
      { simp {contextual := tt} },
      { -- `finish [ih _ _ hf]` closes this goal
        rcases ih _ _ hf with rfl | H,
        { simp only [mem_cons_iff, mem_append, mem_singleton, option.mem_def], tauto },
        { apply λ hm, or.inr (list.mem_append.mpr $ or.inl _),
          exact (option.mem_some_iff.mp hm ▸ H)} }}
  end

end preorder

section linear_order

variables {α : Type*} {β : Type*} [linear_order β] {l : list α}

open list

theorem index_of_argmax [decidable_eq α] {f : α → β} : Π {l : list α} {m : α}, m ∈ argmax f l →
  ∀ {a}, a ∈ l → f m ≤ f a → l.index_of a ≤ l.index_of m
| []       m _  _ _  _   := by simp
| (hd::tl) m hm a ha ham := begin
  simp only [index_of_cons, argmax_cons, option.mem_def] at ⊢ hm,
  cases h : argmax f tl,
  { rw h at hm,
    simp * at * },
  { rw h at hm,
    dsimp only at hm,
    cases ha with hahd hatl,
    { clear index_of_argmax,
      subst hahd,
      split_ifs at hm,
      { subst hm, simp },
      { subst hm } },
    { have := index_of_argmax h hatl, clear index_of_argmax,
      split_ifs,
      simp * at *,
      simp * at *,
      exfalso,
      split_ifs at hm,
      subst hm, subst h_2,

      -- refl <|> exact nat.zero_le _ <|> simp [*, nat.succ_le_succ_iff, -not_le] at *,
       }}
end

end linear_order


--def nondecreasing (l : list α) := sorted (λ x y, ¬ (y < x)) l
--
--@[simp] theorem nondecreasing_nil :  nondecreasing ([] : list α) := pairwise.nil
--
--lemma nondecreasing.of_cons : nondecreasing (a :: l) → nondecreasing l := pairwise.of_cons
--
--theorem nondecreasing.tail {l : list α} (h : nondecreasing l) : nondecreasing l.tail :=
--h.tail
--
--theorem rel_of_nondecreasing_cons {a : α} {l : list α} : nondecreasing (a :: l) →
--  ∀ b ∈ l, ¬ (b < a) :=
--rel_of_pairwise_cons
--
--@[simp] theorem nondecreasing_cons {a : α} {l : list α} :
--  nondecreasing (a :: l) ↔ (∀ b ∈ l, ¬ (b < a)) ∧ nondecreasing l :=
--pairwise_cons
--
--theorem nondecreasing.merge : ∀ {l l' : list α}, nondecreasing l → nondecreasing l' →
--  nondecreasing (merge (≤) l l')
--| []       []        h₁ h₂ := by simp [merge]
--| []       (b :: l') h₁ h₂ := by simpa [merge] using h₂
--| (a :: l) []        h₁ h₂ := by simpa [merge] using h₁
--| (a :: l) (b :: l') h₁ h₂ := begin
--  by_cases a ≤ b,
--  { simp only [merge, h, if_true, nondecreasing_cons, not_false_iff],
--    refine ⟨λ c hc, _, h₁.of_cons.merge h₂⟩,
--    { rcases (show c = b ∨ c ∈ l ∨ c ∈ l', by simpa [or.left_comm] using
--      (perm_merge _ _ _).subset hc) with rfl | hcl | hcl',
--      { exact not_lt_of_le h},
--      { exact rel_of_nondecreasing_cons h₁ _ hcl },
--      { replace hcl' := rel_of_nondecreasing_cons h₂ _ hcl',
--        contrapose! hcl',
--        exact lt_of_lt_of_le hcl' h  }}},
--  { simp only [merge, h, if_false, nondecreasing_cons],
--    refine ⟨λ c hc, _, h₁.merge h₂.of_cons⟩,
--    { rcases (show c = a ∨ c ∈ l ∨ c ∈ l', by simpa [or.left_comm] using
--      (perm_merge _ _ _).subset hc) with rfl | hcl | hcl',
--      { contrapose! h,
--        exact le_of_lt h },
--      { replace hcl := rel_of_nondecreasing_cons h₁ _ hcl,
--        -- hypotheses `h : ¬a ≤ b` and `hcl : ¬c < a` with goal : `⊢ ¬c < b`, which is impossible
--        -- to deduce
--        sorry },
--      { exact rel_of_nondecreasing_cons h₂ _ hcl' }}}
--end

end

open finset


-- noncomputable lemma order_embedding.trans (α β γ : Type*) [has_le α] [has_le β] [has_le γ]
--   (e : α ↪o β) (e' : β ↪o γ) : α ↪o γ := e.trans e'--

-- namespace finset--

-- variables {α : Type*} [preorder α]
-- def order_emb_of_fin (s : finset α) {k : ℕ} (h : s.card = k) : s ↪o fin k := sorry
-- order_embedding.trans (fin.cast ((length_sort (≤)).trans h)) $ _--
--

-- order_iso.trans (fin.cast ((length_sort (≤)).trans h).symm) $
--   (s.sort_sorted_lt.nth_le_iso _).trans $ order_iso.set_congr _ _ $
--     set.ext $ λ x, mem_sort _--

-- end finset
-- def to_name (α : Type*) [fintype α] [preorder α] {k : ℕ}
--   (h : fintype.card α = k) : α ↪o fin k := sorry
--   (univ.order_iso_of_fin h).trans $ (order_iso.set_congr _ _ coe_univ).trans order_iso.set.univ

/-
namespace fintype

variables {α β : Type*} [linear_order β] (f : α → β)

@[simps] def lex.fst {α β} [preorder α] [preorder β] : lex (α × β) →o α :=
{ to_fun := prod.fst,
  monotone' := λ i j h, by { cases h, { apply le_of_lt, assumption }, { refl } } }

variables {m : ℕ} [fintype α]  (h : fintype.card α = m)
include h

/-- Sorting a function. Informally, given an indexed collection of ordered values, we order the
indices to match the values. -/
lemma exists_monotone_replacement : ∃ (e : fin m ≃ α), monotone (f ∘ e) :=
begin
  have e0 : α ≃ fin m := fintype.equiv_fin_of_card_eq h,
  let f' : α → lex (β × fin m) := λ a, (f a, e0 a),
  letI : linear_order α := linear_order.lift f' _,
  swap, { intros a b ab, apply e0.injective, convert congr_arg prod.snd ab },
  have eo : fin m ≃o α := mono_equiv_of_fin _ h,
  refine ⟨eo.to_equiv, monotone.comp _ eo.monotone⟩,
  change monotone (lex.fst ∘ f'),
  exact monotone.comp lex.fst.monotone (λ a b h, h),
end

lemma test [preorder α] : ∃ (σ : equiv.perm α), monotone (f ∘ σ) :=
begin
  have e0 : α ≃ fin m := fintype.equiv_fin_of_card_eq h,
  let f' : α → lex (β × fin m) := λ a, (f a, e0 a),
  letI : linear_order α := linear_order.lift f' _,
  swap, { intros a b ab, apply e0.injective, convert congr_arg prod.snd ab },
  sorry,
  -- have eo : fin m ≃o α := mono_equiv_of_fin _ h,
  -- refine ⟨eo.to_equiv, monotone.comp _ eo.monotone⟩,
  -- change monotone (lex.fst ∘ f'),
  -- exact monotone.comp lex.fst.monotone (λ a b h, h),
end

/-- Sorting a function. We permute the values of the domain of the function `α` -/
lemma exists_monotone_perm [linear_order α] : ∃ (σ : equiv.perm α), monotone (f ∘ σ) :=
begin
  cases exists_monotone_replacement f h with e he,
  set γ : fin m ≃o α := mono_equiv_of_fin _ h with hγ,
  set σ : equiv.perm α :=
  begin
    refine ⟨e ∘ γ.symm, γ ∘ e.symm, λ x, _, λ x, _⟩;
    simp
  end with hσ,
  refine ⟨σ, λ x y hxy, _⟩,
  simp only [function.comp_app, equiv.coe_fn_mk],
  exact he ((order_iso.symm γ).monotone hxy)
end

end fintype

namespace finset

variables {α β : Type*} [linear_order β] (f : α → β) {m : ℕ} (s : finset α)

lemma exists_monotone_replacement (hs : s.card = m) : ∃ (e : fin m → α), monotone (f ∘ e) :=
begin
  replace hs : fintype.card s = m := by simpa,
  cases fintype.exists_monotone_replacement (f ∘ (coe : s → α)) hs with e he,
  refine ⟨(coe ∘ e), he⟩
end

lemma exists_monotone_perm [linear_order α] : ∃ (σ : equiv.perm α), {x | σ x ≠ x} ⊆ s ∧
  monotone_on (f ∘ σ) s :=
begin
  cases (show ∃ m, s.card = m, by exact exists_eq') with m hs,
  replace hs : fintype.card s = m := by simpa,
  cases fintype.exists_monotone_perm (f ∘ (coe : s → α)) hs with σ hσ,
  refine ⟨equiv.perm.subtype_congr σ (equiv.refl _), _, _⟩,
  { intros x hx,
    contrapose hx,
    simp only [set.mem_set_of_eq, not_not],
    rw mem_coe at hx,
    rw equiv.perm.subtype_congr.right_apply,
    { simp only [equiv.coe_refl, id.def, subtype.coe_mk]},
    exact hx },
  { intros x hx y hy hxy,
    replace hxy : (⟨x, hx⟩ : s) ≤ ⟨y, hy⟩, by simpa,
    convert hσ hxy using 1,
    { simp only [function.comp_app],
      congr,
      rw equiv.perm.subtype_congr.left_apply },
    { simp only [function.comp_app],
      congr,
      rw equiv.perm.subtype_congr.left_apply }}
end


end finset

namespace monovary

variables {ι α β : Type*} {f : ι → α} {g : ι → β}

lemma comp [preorder α] [preorder β] (σ : ι → ι) : monovary f g → monovary (f ∘ σ) (g ∘ σ) :=
λ h x y hxy, h hxy

lemma perm_iff [preorder α] [preorder β] (σ : equiv.perm ι) :
  monovary f g ↔ monovary (f ∘ σ) (g ∘ σ) :=
begin
  refine ⟨comp σ, λ h x y hxy, _⟩,
  { replace hxy : g (σ (σ⁻¹ x)) < g (σ (σ⁻¹ y)) := by simpa using hxy,
    simpa using (h hxy) }
end

lemma exists_perm_monovary' [linear_order α] [linear_order β] [fintype ι] :
  ∃ (σ : equiv.perm ι), monovary (f ∘ σ) g :=
begin
  cases (show ∃ m, fintype.card ι = m, by exact exists_eq') with m hι,
  have e0 : ι ≃ fin m := fintype.equiv_fin_of_card_eq hι,
  let f' : ι → lex (α × fin m) := λ a, (f a, e0 a),
  letI : linear_order ι := linear_order.lift f' _,
  swap, { intros a b ab, apply e0.injective, convert congr_arg prod.snd ab },
  have eo : fin m ≃o ι := mono_equiv_of_fin _ hι,
  sorry
end

lemma exists_perm_monovary [linear_order ι] [linear_order α] [linear_order β] [fintype ι] :
  ∃ σ : equiv.perm ι, monovary (f ∘ σ) g :=
begin
  cases (show ∃ m, fintype.card ι = m, by exact exists_eq') with m hι,
  cases fintype.exists_monotone_perm f hι with τ hτ,
  cases fintype.exists_monotone_perm g hι with π hπ,
  set σ : equiv.perm ι :=
  begin
    refine ⟨τ ∘ π.symm, π ∘ τ.symm,λ x, _ ,λ x, _⟩;
    simp
  end with hσ,
  refine ⟨σ, _⟩,
  rw [perm_iff π, hσ],
  convert (hτ.monovary hπ) using 1,
  ext; simp
end

end monovary

namespace equiv.perm

lemma image_set_eq {ι : Type*} {σ : equiv.perm ι} {s : set ι} (hσ : {x | σ x ≠ x} ⊆ s) :
  σ '' s = s :=
begin
  ext,
  split,
  { rintro ⟨y, hys, hy⟩,
    obtain rfl | hxy := eq_or_ne y x,
    { exact hys },
    { apply hσ,
      simp only [← hy, ne.def, set.mem_set_of_eq, embedding_like.apply_eq_iff_eq],
      simpa [hy] using (ne.symm hxy) }},
  { intro h,
    obtain hx | hx := eq_or_ne (σ x) x,
    { rw ← hx,
      exact set.mem_image_of_mem σ h },
    { refine ⟨σ⁻¹ x, _, apply_inv_self σ x⟩,
      { apply hσ,
        simp only [ne.def, set.mem_set_of_eq, apply_inv_self, eq_inv_iff_eq, hx, not_false_iff] }}}
end

lemma set_subset_of_subset {ι : Type*} {τ π : equiv.perm ι} {s : set ι} (hτ : {x | τ x ≠ x} ⊆ s)
  (hπ : {x | π x ≠ x} ⊆ s) : {x | (τ ∘ π) x ≠ x} ⊆ s :=
begin
  intros x hx,
  contrapose hx,
  replace hπ : π x = x,
  { contrapose hx,
    push_neg,
    convert hπ hx },
  replace hτ : (τ ∘ π) x = x,
  { simp only [hπ, function.comp_app],
    contrapose hx,
    push_neg,
    convert hτ hx },
  simpa using hτ
end

end equiv.perm

namespace monovary_on

variables {ι α β : Type*} {f : ι → α} {g : ι → β} {s : set ι}

lemma comp [preorder α] [preorder β] (σ : ι → ι) :
  monovary_on f g (σ '' s) → monovary_on (f ∘ σ) (g ∘ σ) s :=
λ h x hx y hy hxy, h (set.mem_image_of_mem σ hx) (set.mem_image_of_mem σ hy) hxy

lemma perm_iff [preorder α] [preorder β] (σ : equiv.perm ι) :
  monovary_on f g (σ '' s) ↔ monovary_on (f ∘ σ) (g ∘ σ) s :=
begin
  refine ⟨comp σ, λ h x hx y hy hxy, _⟩,
  { replace hxy : g (σ (σ⁻¹ x)) < g (σ (σ⁻¹ y)) := by simpa using hxy,
    replace hx : σ⁻¹ x ∈ s,
    { cases hx with z hz,
      simp only [← hz.2, equiv.perm.inv_apply_self, hz.1] },
    replace hy : σ⁻¹ y ∈ s,
    { cases hy with z hz,
      simp only [← hz.2, equiv.perm.inv_apply_self, hz.1] },
    simpa using (h hx hy hxy) }
end

lemma perm_iff_of_support_subset [preorder α] [preorder β] {σ : equiv.perm ι}
  (hσ : {x | σ x ≠ x} ⊆ s) : monovary_on f g s ↔ monovary_on (f ∘ σ) (g ∘ σ) s :=
begin
  convert perm_iff σ,
  rw equiv.perm.image_set_eq hσ
end

lemma exists_perm_monovary_on [linear_order ι] [linear_order α] [linear_order β] (s : finset ι) :
  ∃ σ : equiv.perm ι, {x | σ x ≠ x} ⊆ s ∧ monovary_on (f ∘ σ) g s :=
begin
  rcases s.exists_monotone_perm g with ⟨τ, hτs, hτ⟩,
  rcases s.exists_monotone_perm f with ⟨π, hπs, hπ⟩,
  set σ : equiv.perm ι :=
  begin
    refine ⟨π ∘ τ.symm, τ ∘ π.symm,λ x, _ ,λ x, _⟩;
    simp
  end with hσ,
  have hσs : {x | σ x ≠ x} ⊆ s := equiv.perm.set_subset_of_subset hπs _,
  refine ⟨σ, hσs, _⟩,
  rw [perm_iff_of_support_subset hτs, hσ],
  convert (hπ.monovary_on hτ) using 1,
  { ext; simp },
  { convert hτs using 1,
    rw ← equiv.perm.set_support_inv_eq τ,
    congr }
end

end monovary_on
-/
