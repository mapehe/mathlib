/-
Copyright (c) 2020 David Wärn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: David Wärn
-/
import logic.encodable.basic
import order.atoms

/-!
# Order ideals, cofinal sets, and the Rasiowa–Sikorski lemma

## Main definitions

Throughout this file, `P` is at least a preorder, but some sections require more
structure, such as a bottom element, a top element, or a join-semilattice structure.
- `order.ideal P`: the type of nonempty, upward directed, and downward closed subsets of `P`.
  Dual to the notion of a filter on a preorder.
- `order.is_ideal P`: a predicate for when a `set P` is an ideal.
- `order.ideal.principal p`: the principal ideal generated by `p : P`.
- `order.ideal.is_proper P`: a predicate for proper ideals.
  Dual to the notion of a proper filter.
- `order.ideal.is_maximal`: a predicate for maximal ideals.
  Dual to the notion of an ultrafilter.
- `ideal_Inter_nonempty P`: a predicate for when the intersection of all ideals of
  `P` is nonempty.
- `order.cofinal P`: the type of subsets of `P` containing arbitrarily large elements.
  Dual to the notion of 'dense set' used in forcing.
- `order.ideal_of_cofinals p 𝒟`, where `p : P`, and `𝒟` is a countable family of cofinal
  subsets of P: an ideal in `P` which contains `p` and intersects every set in `𝒟`. (This a form
  of the Rasiowa–Sikorski lemma.)

## References

- <https://en.wikipedia.org/wiki/Ideal_(order_theory)>
- <https://en.wikipedia.org/wiki/Cofinal_(mathematics)>
- <https://en.wikipedia.org/wiki/Rasiowa%E2%80%93Sikorski_lemma>

Note that for the Rasiowa–Sikorski lemma, Wikipedia uses the opposite ordering on `P`,
in line with most presentations of forcing.

## TODO

`order.ideal.ideal_Inter_nonempty` is a complicated way to say that `P` has a bottom element. It
should be replaced by this clearer condition, which could be called strong directedness and which
is a Prop version of `order_bot`.

## Tags

ideal, cofinal, dense, countable, generic

-/

open function

namespace order

variables {P : Type*}

/-- An ideal on an order `P` is a subset of `P` that is
  - nonempty
  - upward directed (any pair of elements in the ideal has an upper bound in the ideal)
  - downward closed (any element less than an element of the ideal is in the ideal). -/
structure ideal (P) [has_le P] :=
(carrier   : set P)
(nonempty  : carrier.nonempty)
(directed  : directed_on (≤) carrier)
(mem_of_le : ∀ {x y : P}, x ≤ y → y ∈ carrier → x ∈ carrier)

/-- A subset of a preorder `P` is an ideal if it is
  - nonempty
  - upward directed (any pair of elements in the ideal has an upper bound in the ideal)
  - downward closed (any element less than an element of the ideal is in the ideal). -/
@[mk_iff] structure is_ideal {P} [has_le P] (I : set P) : Prop :=
(nonempty : I.nonempty)
(directed : directed_on (≤) I)
(mem_of_le : ∀ {x y : P}, x ≤ y → y ∈ I → x ∈ I)

attribute [protected] ideal.nonempty ideal.directed is_ideal.nonempty is_ideal.directed

/-- Create an element of type `order.ideal` from a set satisfying the predicate
`order.is_ideal`. -/
def is_ideal.to_ideal [has_le P] {I : set P} (h : is_ideal I) : ideal P :=
⟨I, h.1, h.2, h.3⟩

namespace ideal
section has_le
variables [has_le P] {I J : ideal P} {x y : P}

/-- An ideal of `P` can be viewed as a subset of `P`. -/
instance : has_coe (ideal P) (set P) := ⟨carrier⟩

/-- For the notation `x ∈ I`. -/
instance : has_mem P (ideal P) := ⟨λ x I, x ∈ (I : set P)⟩

@[simp] lemma mem_coe : x ∈ (I : set P) ↔ x ∈ I := iff_of_eq rfl

/-- Two ideals are equal when their underlying sets are equal. -/
@[ext] lemma ext : ∀ {I J : ideal P}, (I : set P) = J → I = J
| ⟨_, _, _, _⟩ ⟨_, _, _, _⟩ rfl := rfl

lemma coe_injective : injective (coe : ideal P → set P) := λ _ _, ext

@[simp, norm_cast] lemma coe_inj : (I : set P) = J ↔ I = J := ⟨by ext, congr_arg _⟩

lemma ext_iff : I = J ↔ (I : set P) = J := coe_inj.symm

protected lemma is_ideal (I : ideal P) : is_ideal (I : set P) := ⟨I.2, I.3, I.4⟩

/-- The partial ordering by subset inclusion, inherited from `set P`. -/
instance : partial_order (ideal P) := partial_order.lift coe coe_injective

@[trans] lemma mem_of_mem_of_le {x : P} {I J : ideal P} : x ∈ I → I ≤ J → x ∈ J :=
@set.mem_of_mem_of_subset P x I J

/-- A proper ideal is one that is not the whole set.
    Note that the whole set might not be an ideal. -/
@[mk_iff] class is_proper (I : ideal P) : Prop := (ne_univ : (I : set P) ≠ set.univ)

lemma is_proper_of_not_mem {I : ideal P} {p : P} (nmem : p ∉ I) : is_proper I :=
⟨λ hp, begin
  change p ∉ ↑I at nmem,
  rw hp at nmem,
  exact nmem (set.mem_univ p),
end⟩

/-- An ideal is maximal if it is maximal in the collection of proper ideals.

Note that `is_coatom` is less general because ideals only have a top element when `P` is directed
and nonempty. -/
@[mk_iff] class is_maximal (I : ideal P) extends is_proper I : Prop :=
(maximal_proper : ∀ ⦃J : ideal P⦄, I < J → (J : set P) = set.univ)

variable (P)

/-- An order `P` has the `ideal_Inter_nonempty` property if the intersection of all ideals is
nonempty. Most importantly, the ideals of a `semilattice_sup` with this property form a complete
lattice.

TODO: This is equivalent to the existence of a bottom element and shouldn't be specialized to
ideals. -/
class ideal_Inter_nonempty : Prop :=
(Inter_nonempty : (⋂ (I : ideal P), (I : set P)).nonempty)

variable {P}

lemma Inter_nonempty [ideal_Inter_nonempty P] :
  (⋂ (I : ideal P), (I : set P)).nonempty :=
ideal_Inter_nonempty.Inter_nonempty

lemma ideal_Inter_nonempty.exists_all_mem [ideal_Inter_nonempty P] :
  ∃ a : P, ∀ I : ideal P, a ∈ I :=
begin
  change ∃ (a : P), ∀ (I : ideal P), a ∈ (I : set P),
  rw ← set.nonempty_Inter,
  exact Inter_nonempty,
end

lemma ideal_Inter_nonempty_of_exists_all_mem (h : ∃ a : P, ∀ I : ideal P, a ∈ I) :
  ideal_Inter_nonempty P :=
{ Inter_nonempty := by rwa set.nonempty_Inter }

lemma ideal_Inter_nonempty_iff :
  ideal_Inter_nonempty P ↔ ∃ a : P, ∀ I : ideal P, a ∈ I :=
⟨λ _, by exactI ideal_Inter_nonempty.exists_all_mem, ideal_Inter_nonempty_of_exists_all_mem⟩

lemma inter_nonempty [is_directed P (swap (≤))] (I J : ideal P) : (I ∩ J : set P).nonempty :=
begin
  obtain ⟨a, ha⟩ := I.nonempty,
  obtain ⟨b, hb⟩ := J.nonempty,
  obtain ⟨c, hac, hbc⟩ := directed_of (swap (≤)) a b,
  exact ⟨c, I.mem_of_le hac ha, J.mem_of_le hbc hb⟩,
end

end has_le

section preorder
variables [preorder P] {I J : ideal P} {x y : P}

/-- The smallest ideal containing a given element. -/
def principal (p : P) : ideal P :=
{ carrier   := { x | x ≤ p },
  nonempty  := ⟨p, le_rfl⟩,
  directed  := λ x hx y hy, ⟨p, le_rfl, hx, hy⟩,
  mem_of_le := λ x y hxy hy, le_trans hxy hy, }

instance [inhabited P] : inhabited (ideal P) := ⟨ideal.principal default⟩

@[simp] lemma principal_le_iff : principal x ≤ I ↔ x ∈ I :=
⟨λ (h : ∀ {y}, y ≤ x → y ∈ I), h (le_refl x),
 λ h_mem y (h_le : y ≤ x), I.mem_of_le h_le h_mem⟩

@[simp] lemma mem_principal : x ∈ principal y ↔ x ≤ y := iff.rfl

lemma mem_compl_of_ge {x y : P} : x ≤ y → x ∈ (I : set P)ᶜ → y ∈ (I : set P)ᶜ :=
λ h, mt (I.mem_of_le h)

end preorder

section order_bot

/-- A specific witness of `I.nonempty` when `P` has a bottom element. -/
@[simp] lemma bot_mem [has_le P] [order_bot P] {I : ideal P} : ⊥ ∈ I :=
I.mem_of_le bot_le I.nonempty.some_mem

variables [preorder P] [order_bot P] {I : ideal P}

/-- There is a bottom ideal when `P` has a bottom element. -/
instance : order_bot (ideal P) :=
{ bot := principal ⊥,
  bot_le := by simp }

@[priority 100]
instance order_bot.ideal_Inter_nonempty : ideal_Inter_nonempty P :=
by { rw ideal_Inter_nonempty_iff, exact ⟨⊥, λ I, bot_mem⟩ }

end order_bot

section directed
variables [has_le P] [is_directed P (≤)] [nonempty P] {I : ideal P}

/-- In a directed and nonempty order, the top ideal of a is `set.univ`. -/
instance : order_top (ideal P) :=
{ top := { carrier := set.univ,
           nonempty := set.univ_nonempty,
           directed := directed_on_univ,
           mem_of_le := λ _ _ _ _, trivial },
  le_top := λ I, le_top }

@[simp] lemma coe_top : ((⊤ : ideal P) : set P) = set.univ := rfl

lemma is_proper_of_ne_top (ne_top : I ≠ ⊤) : is_proper I := ⟨λ h, ne_top $ ext h⟩

lemma is_proper.ne_top (hI : is_proper I) : I ≠ ⊤ :=
begin
  intro h,
  rw [ext_iff, coe_top] at h,
  apply hI.ne_univ,
  assumption,
end

lemma _root_.is_coatom.is_proper (hI : is_coatom I) : is_proper I := is_proper_of_ne_top hI.1

lemma is_proper_iff_ne_top : is_proper I ↔ I ≠ ⊤ := ⟨λ h, h.ne_top, λ h, is_proper_of_ne_top h⟩

lemma is_maximal.is_coatom (h : is_maximal I) : is_coatom I :=
⟨is_maximal.to_is_proper.ne_top,
  λ _ _, by { rw [ext_iff, coe_top], exact is_maximal.maximal_proper ‹_› }⟩

lemma is_maximal.is_coatom' [is_maximal I] : is_coatom I := is_maximal.is_coatom ‹_›

lemma _root_.is_coatom.is_maximal (hI : is_coatom I) : is_maximal I :=
{ maximal_proper := λ _ _, by simp [hI.2 _ ‹_›],
  ..is_coatom.is_proper ‹_› }

lemma is_maximal_iff_is_coatom : is_maximal I ↔ is_coatom I := ⟨λ h, h.is_coatom, λ h, h.is_maximal⟩

end directed

section order_top
variables [has_le P] [order_top P] {I : ideal P}

lemma top_of_top_mem (hI : ⊤ ∈ I) : I = ⊤ :=
by { ext, exact iff_of_true (I.mem_of_le le_top hI) trivial }

lemma is_proper.top_not_mem (hI : is_proper I) : ⊤ ∉ I := λ h, hI.ne_top $ top_of_top_mem h

end order_top

section semilattice_sup
variables [semilattice_sup P] {x y : P} {I : ideal P}

/-- A specific witness of `I.directed` when `P` has joins. -/
lemma sup_mem (x y ∈ I) : x ⊔ y ∈ I :=
let ⟨z, h_mem, hx, hy⟩ := I.directed x ‹_› y ‹_› in
I.mem_of_le (sup_le hx hy) h_mem

@[simp] lemma sup_mem_iff : x ⊔ y ∈ I ↔ x ∈ I ∧ y ∈ I :=
⟨λ h, ⟨I.mem_of_le le_sup_left h, I.mem_of_le le_sup_right h⟩,
 λ h, sup_mem x h.left y h.right⟩

end semilattice_sup

section semilattice_sup_directed
variables [semilattice_sup P] [is_directed P (swap (≤))] {x : P} {I J K : ideal P}

/-- The infimum of two ideals of a co-directed order is their intersection. -/
instance : has_inf (ideal P) :=
⟨λ I J, { carrier   := I ∩ J,
  nonempty  := inter_nonempty I J,
  directed  := λ x ⟨_, _⟩ y ⟨_, _⟩, ⟨x ⊔ y, ⟨sup_mem x ‹_› y ‹_›, sup_mem x ‹_› y ‹_›⟩, by simp⟩,
  mem_of_le := λ x y h ⟨_, _⟩, ⟨mem_of_le I h ‹_›, mem_of_le J h ‹_›⟩ }⟩

/-- The supremum of two ideals of a co-directed order is the union of the down sets of the pointwise
supremum of `I` and `J`. -/
instance : has_sup (ideal P) :=
⟨λ I J, { carrier   := {x | ∃ (i ∈ I) (j ∈ J), x ≤ i ⊔ j},
  nonempty  := by { cases inter_nonempty I J, exact ⟨w, w, h.1, w, h.2, le_sup_left⟩ },
  directed  := λ x ⟨xi, _, xj, _, _⟩ y ⟨yi, _, yj, _, _⟩,
    ⟨x ⊔ y,
     ⟨xi ⊔ yi, sup_mem xi ‹_› yi ‹_›,
      xj ⊔ yj, sup_mem xj ‹_› yj ‹_›,
      sup_le
        (calc x ≤ xi ⊔ xj               : ‹_›
         ...    ≤ (xi ⊔ yi) ⊔ (xj ⊔ yj) : sup_le_sup le_sup_left le_sup_left)
        (calc y ≤ yi ⊔ yj               : ‹_›
         ...    ≤ (xi ⊔ yi) ⊔ (xj ⊔ yj) : sup_le_sup le_sup_right le_sup_right)⟩,
     le_sup_left, le_sup_right⟩,
  mem_of_le := λ x y _ ⟨yi, _, yj, _, _⟩, ⟨yi, ‹_›, yj, ‹_›, le_trans ‹x ≤ y› ‹_›⟩ }⟩

instance : lattice (ideal P) :=
{ sup          := (⊔),
  le_sup_left  := λ I J (i ∈ I), by { cases J.nonempty, exact ⟨i, ‹_›, w, ‹_›, le_sup_left⟩ },
  le_sup_right := λ I J (j ∈ J), by { cases I.nonempty, exact ⟨w, ‹_›, j, ‹_›, le_sup_right⟩ },
  sup_le       := λ I J K hIK hJK a ⟨i, hi, j, hj, ha⟩,
    K.mem_of_le ha $ sup_mem i (mem_of_mem_of_le hi hIK) j (mem_of_mem_of_le hj hJK),
  inf          := (⊓),
  inf_le_left  := λ I J, set.inter_subset_left I J,
  inf_le_right := λ I J, set.inter_subset_right I J,
  le_inf       := λ I J K, set.subset_inter,
  .. ideal.partial_order }

@[simp] lemma mem_inf : x ∈ I ⊓ J ↔ x ∈ I ∧ x ∈ J := iff.rfl
@[simp] lemma mem_sup : x ∈ I ⊔ J ↔ ∃ (i ∈ I) (j ∈ J), x ≤ i ⊔ j := iff.rfl

lemma lt_sup_principal_of_not_mem (hx : x ∉ I) : I < I ⊔ principal x :=
le_sup_left.lt_of_ne $ λ h, hx $ by simpa only [left_eq_sup, principal_le_iff] using h

end semilattice_sup_directed

section ideal_Inter_nonempty

variables [preorder P] [ideal_Inter_nonempty P]

@[priority 100]
instance ideal_Inter_nonempty.to_directed_ge : is_directed P (swap (≤)) :=
⟨λ a b, begin
    obtain ⟨c, hc⟩ : ∃ a, ∀ I : ideal P, a ∈ I := ideal_Inter_nonempty.exists_all_mem,
    exact ⟨c, hc (principal a), hc (principal b)⟩,
  end⟩

variables {α β γ : Type*} {ι : Sort*}

lemma ideal_Inter_nonempty.all_Inter_nonempty {f : ι → ideal P} :
  (⋂ x, (f x : set P)).nonempty :=
begin
  obtain ⟨a, ha⟩ : ∃ a : P, ∀ I : ideal P, a ∈ I := ideal_Inter_nonempty.exists_all_mem,
  exact ⟨a, by simp [ha]⟩
end

lemma ideal_Inter_nonempty.all_bInter_nonempty {f : α → ideal P} {s : set α} :
  (⋂ x ∈ s, (f x : set P)).nonempty :=
begin
  obtain ⟨a, ha⟩ : ∃ a : P, ∀ I : ideal P, a ∈ I := ideal_Inter_nonempty.exists_all_mem,
  exact ⟨a, by simp [ha]⟩
end

end ideal_Inter_nonempty

section semilattice_sup_ideal_Inter_nonempty

variables [semilattice_sup P] [ideal_Inter_nonempty P] {x : P} {I J K : ideal P}

instance : has_Inf (ideal P) :=
{ Inf := λ s, { carrier := ⋂ (I ∈ s), (I : set P),
  nonempty := ideal_Inter_nonempty.all_bInter_nonempty,
  directed := λ x hx y hy, ⟨x ⊔ y, ⟨λ S ⟨I, hS⟩,
    begin
      simp only [←hS, sup_mem_iff, mem_coe, set.mem_Inter],
      intro hI,
      rw set.mem_Inter₂ at *,
      exact ⟨hx _ hI, hy _ hI⟩
    end,
    le_sup_left, le_sup_right⟩⟩,
  mem_of_le := λ x y hxy hy,
    begin
      rw set.mem_Inter₂ at *,
      exact λ I hI, mem_of_le I ‹_› (hy I hI)
    end } }

variables {s : set (ideal P)}

@[simp] lemma mem_Inf : x ∈ Inf s ↔ ∀ I ∈ s, x ∈ I :=
by { change x ∈ (⋂ (I ∈ s), (I : set P)) ↔ ∀ I ∈ s, x ∈ I, simp }

@[simp] lemma coe_Inf : ↑(Inf s) = ⋂ (I ∈ s), (I : set P) := rfl

lemma Inf_le (hI : I ∈ s) : Inf s ≤ I :=
λ _ hx, hx I ⟨I, by simp [hI]⟩

lemma le_Inf (h : ∀ J ∈ s, I ≤ J) : I ≤ Inf s :=
λ _ _, by { simp only [mem_coe, coe_Inf, set.mem_Inter], tauto }

lemma is_glb_Inf : is_glb s (Inf s) := ⟨λ _, Inf_le, λ _, le_Inf⟩

instance : complete_lattice (ideal P) :=
{ ..ideal.lattice,
  ..complete_lattice_of_Inf (ideal P) (λ _, @is_glb_Inf _ _ _ _) }

end semilattice_sup_ideal_Inter_nonempty

section distrib_lattice

variables [distrib_lattice P]
variables {I J : ideal P}

lemma eq_sup_of_le_sup {x i j: P} (hi : i ∈ I) (hj : j ∈ J) (hx : x ≤ i ⊔ j) :
  ∃ (i' ∈ I) (j' ∈ J), x = i' ⊔ j' :=
begin
  refine ⟨x ⊓ i, I.mem_of_le inf_le_right hi, x ⊓ j, J.mem_of_le inf_le_right hj, _⟩,
  calc
  x    = x ⊓ (i ⊔ j)       : left_eq_inf.mpr hx
  ...  = (x ⊓ i) ⊔ (x ⊓ j) : inf_sup_left,
end

lemma coe_sup_eq : ↑(I ⊔ J) = {x | ∃ i ∈ I, ∃ j ∈ J, x = i ⊔ j} :=
begin
  ext,
  rw [mem_coe, mem_sup],
  exact ⟨λ ⟨_, _, _, _, _⟩, eq_sup_of_le_sup ‹_› ‹_› ‹_›,
  λ ⟨i, _, j, _, _⟩, ⟨i, ‹_›, j, ‹_›, le_of_eq ‹_›⟩⟩
end

end distrib_lattice

section boolean_algebra

variables [boolean_algebra P] {x : P} {I : ideal P}

lemma is_proper.not_mem_of_compl_mem (hI : is_proper I) (hxc : xᶜ ∈ I) : x ∉ I :=
begin
  intro hx,
  apply hI.top_not_mem,
  have ht : x ⊔ xᶜ ∈ I := sup_mem _ ‹_› _ ‹_›,
  rwa sup_compl_eq_top at ht,
end

lemma is_proper.not_mem_or_compl_not_mem (hI : is_proper I) : x ∉ I ∨ xᶜ ∉ I :=
have h : xᶜ ∈ I → x ∉ I := hI.not_mem_of_compl_mem, by tauto

end boolean_algebra

end ideal

/-- For a preorder `P`, `cofinal P` is the type of subsets of `P`
  containing arbitrarily large elements. They are the dense sets in
  the topology whose open sets are terminal segments. -/
structure cofinal (P) [preorder P] :=
(carrier : set P)
(mem_gt  : ∀ x : P, ∃ y ∈ carrier, x ≤ y)

namespace cofinal

variables [preorder P]

instance : inhabited (cofinal P) :=
⟨{ carrier := set.univ, mem_gt := λ x, ⟨x, trivial, le_rfl⟩ }⟩

instance : has_mem P (cofinal P) := ⟨λ x D, x ∈ D.carrier⟩

variables (D : cofinal P) (x : P)
/-- A (noncomputable) element of a cofinal set lying above a given element. -/
noncomputable def above : P := classical.some $ D.mem_gt x

lemma above_mem : D.above x ∈ D :=
exists.elim (classical.some_spec $ D.mem_gt x) $ λ a _, a

lemma le_above : x ≤ D.above x :=
exists.elim (classical.some_spec $ D.mem_gt x) $ λ _ b, b

end cofinal

section ideal_of_cofinals

variables [preorder P] (p : P) {ι : Type*} [encodable ι] (𝒟 : ι → cofinal P)

/-- Given a starting point, and a countable family of cofinal sets,
  this is an increasing sequence that intersects each cofinal set. -/
noncomputable def sequence_of_cofinals : ℕ → P
| 0 := p
| (n+1) := match encodable.decode ι n with
           | none   := sequence_of_cofinals n
           | some i := (𝒟 i).above (sequence_of_cofinals n)
           end

lemma sequence_of_cofinals.monotone : monotone (sequence_of_cofinals p 𝒟) :=
by { apply monotone_nat_of_le_succ, intros n, dunfold sequence_of_cofinals,
  cases encodable.decode ι n, { refl }, { apply cofinal.le_above }, }

lemma sequence_of_cofinals.encode_mem (i : ι) :
  sequence_of_cofinals p 𝒟 (encodable.encode i + 1) ∈ 𝒟 i :=
by { dunfold sequence_of_cofinals, rw encodable.encodek, apply cofinal.above_mem, }

/-- Given an element `p : P` and a family `𝒟` of cofinal subsets of a preorder `P`,
  indexed by a countable type, `ideal_of_cofinals p 𝒟` is an ideal in `P` which
  - contains `p`, according to `mem_ideal_of_cofinals p 𝒟`, and
  - intersects every set in `𝒟`, according to `cofinal_meets_ideal_of_cofinals p 𝒟`.

  This proves the Rasiowa–Sikorski lemma. -/
def ideal_of_cofinals : ideal P :=
{ carrier   := { x : P | ∃ n, x ≤ sequence_of_cofinals p 𝒟 n },
  nonempty  := ⟨p, 0, le_rfl⟩,
  directed  := λ x ⟨n, hn⟩ y ⟨m, hm⟩,
               ⟨_, ⟨max n m, le_rfl⟩,
               le_trans hn $ sequence_of_cofinals.monotone p 𝒟 (le_max_left _ _),
               le_trans hm $ sequence_of_cofinals.monotone p 𝒟 (le_max_right _ _) ⟩,
  mem_of_le := λ x y hxy ⟨n, hn⟩, ⟨n, le_trans hxy hn⟩, }

lemma mem_ideal_of_cofinals : p ∈ ideal_of_cofinals p 𝒟 := ⟨0, le_rfl⟩

/-- `ideal_of_cofinals p 𝒟` is `𝒟`-generic. -/
lemma cofinal_meets_ideal_of_cofinals (i : ι) : ∃ x : P, x ∈ 𝒟 i ∧ x ∈ ideal_of_cofinals p 𝒟 :=
⟨_, sequence_of_cofinals.encode_mem p 𝒟 i, _, le_rfl⟩

end ideal_of_cofinals

end order
