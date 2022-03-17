/-
Copyright (c) 2022 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jujian Zhang
-/
import analysis.mean_inequalities

/-!
# IMO 1984 Q1

For nonnegative real numbers `x, y, z` such that `x + y + z = 1` prove that
`0 ≤ xy + yz + xz - 2xyz ≤ 7/27`

`0 ≤ xy + yz + xz - 2xyz`:
`x + y + z = 1`, so at least one of `x, y, z` is less than or equal to `1/2`. Wlog `x ≤ 1/2`. Then,
`xy + yz + xz - 2xyz = yz(1 - 2x) + xy + xz` and everything on the right hand side is nonnegative.

`xy + yz + xz - 2xyz ≤ 7/27`:
We assumed that `x ≤ y ≤ z` to simplify the proof. First we see that
`xy + yz + xz - 2xyz = 1/4 * (1 - 2x)(1 - 2y)(1 - 2z) + 1/4`.
So we split into two cases according to whether `0 ≤ 1 - 2z` or `1 - 2z < 0`:
* if `0 ≤ 1 - 2z`, then AM-GM tells us `(1 - 2x)(1 - 2y)(1 - 2z) ≤ 1 / 27` and it's done;
* if `1 - 2z < 0`, then `xy + yz + xz - 2xyz = 1/4 * (1 - 2x)(1 - 2y)(1 - 2z) + 1/4 ≤ 1/4`.
-/

namespace imo1984_q1

section

open real
variables (x y z : ℝ)

lemma possible_orders :
  (x ≤ y ∧ y ≤ z) ∨
  (x ≤ z ∧ z ≤ y) ∨
  (y ≤ x ∧ x ≤ z) ∨
  (y ≤ z ∧ z ≤ x) ∨
  (z ≤ x ∧ x ≤ y) ∨
  (z ≤ y ∧ y ≤ x) :=
begin
  by_contra rid,
  simp only [not_or_distrib] at rid,
  rcases rid with ⟨r1,r2,r3,r4,r5,r6⟩,
  simp only [not_and_distrib] at *,
  cases r1; cases r2; cases r3; cases r4; cases r5; cases r6;
  linarith,
end

variables (add_eq : x + y + z = 1) (hx : 0 ≤ x) (hy : 0 ≤ y) (hz : 0 ≤ z)
include add_eq hx hy hz

lemma zero_le : 0 ≤ x * y + y * z + x * z - 2 * x * y * z :=
have ineq1 : x ≤ 1/2 ∨ y ≤ 1/2 ∨ z ≤ 1/2, begin
  by_contra rid,
  simp only [not_or_distrib] at rid,
  rcases rid with ⟨r1, r2, r3⟩,
  linarith,
end,
begin
  wlog := ineq1 using x y z,
  rw show x * y + y * z + x * z - 2 * x * y * z = y * z * (1 - 2 * x) + x * y + x * z, by ring,
  have ineq2 : 0 ≤ (1 - 2 * x) := by linarith,
  refine add_nonneg (add_nonneg (mul_nonneg (mul_nonneg _ _) _) (mul_nonneg _ _)) (mul_nonneg _ _);
  linarith,
end

lemma le_7_div_27 (hxy : x ≤ y) (hyz : y ≤ z) : x * y + y * z + x * z - 2 * x * y * z ≤ 7/27 :=
have eq1 : (1 - 2 * x) * (1 - 2 * y) * (1 - 2 * z) =
  -1 + 4 * (y * z + x * z + x * y) - 8 * x * y * z, from
calc (1 - 2 * x) * (1 - 2 * y) * (1 - 2 * z)
    = 1 - 2 * (x + y + z) + 4 * (y * z + x * z + x * y) - 8 * x * y * z : by ring
... = 1 - 2 * 1 + 4 * (y * z + x * z + x * y) - 8 * x * y * z : by simp [add_eq]
... = -1 + 4 * (y * z + x * z + x * y) - 8 * x * y * z : by norm_num,
have EQ : x * y + y * z + x * z - 2 * x * y * z =
  1/4 * (1 - 2 * x) * (1 - 2 * y) * (1 - 2 * z) + 1/4, by linarith,
begin
  have x_ineq : 0 ≤ 1 - 2 * x, by linarith,
  have y_ineq : 0 ≤ 1 - 2 * y, by linarith,
  have xy_ineq : _, from mul_nonneg x_ineq y_ineq,
  have ineq' : (0 : ℝ) ≤ 1/3, by linarith,
  have ineq'' : (0 : ℝ) ≤ 1/4, by linarith,
  have ineq''' : (0 : ℝ) < 3, by linarith,
  have eq' : (1 : ℝ) / 3 + 1 / 3 + 1 / 3 = 1, by norm_num,

  by_cases z_ineq : 0 ≤ 1 - 2*z,
  { have xyz_ineq := mul_nonneg xy_ineq z_ineq,
    have ineq1 := geom_mean_le_arith_mean3_weighted ineq' ineq' ineq' x_ineq y_ineq z_ineq eq',
    simp only [← mul_add] at ineq1,
    rw [calc 1 - 2*x + (1 - 2*y) + (1 - 2*z) = 3 - 2*(x+y+z) : by ring, add_eq] at ineq1,
    norm_num at ineq1,
    rw [←mul_rpow, ←mul_rpow, ←rpow_le_rpow_iff _ _ (_ : (0 : ℝ) < 3), ←rpow_mul] at ineq1,
    norm_num at ineq1,
    have ineq2 := add_le_add (mul_le_mul (le_refl (1/4 : ℝ)) ineq1 _ _) (le_refl (1/4 : ℝ)),
    rw [← mul_assoc, ← mul_assoc, ← EQ] at ineq2,
    linarith,
    assumption',
    apply real.rpow_nonneg_of_nonneg _ _,
    assumption' },
  { have xyz_ineq := mul_nonpos_of_nonneg_of_nonpos xy_ineq (le_of_lt (not_le.mp z_ineq)),
    have ineq1 : 1 / 4 * (1 - 2 * x) * (1 - 2 * y) * (1 - 2 * z) + 1 / 4 ≤ 1 / 4 := by linarith,
    rw ← EQ at ineq1,
    linarith, },
end

end

theorem imo1984_q1 (x y z : ℝ) (add_eq : x + y + z = 1) (hx : 0 ≤ x) (hy : 0 ≤ y) (hz : 0 ≤ z) :
  0 ≤ x * y + y * z + x * z - 2 * x * y * z ∧ x * y + y * z + x * z - 2 * x * y * z ≤ 7/27 :=
and.intro
  (zero_le x y z add_eq hx hy hz)
  begin
    rcases (possible_orders x y z) with h|h|h|h|h|h;
    convert le_7_div_27 _ _ _ _ _ _ _ h.1 h.2 using 1,
    assumption',
    all_goals { ring1 <|> { convert add_eq using 1, ring } },
  end

end imo1984_q1
