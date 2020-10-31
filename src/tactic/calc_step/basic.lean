/-
Copyright (c) 2020 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/
import tactic.core
import tactic.calc_step.lemmas
import tactic.norm_num

/-
TODO:
* special support for `0` and `1`? things like:

  - `0 < x ↔ -x < 0`
  - `(h : 0 ≤ x * y) {h0 : 0 ≤ 2} : 0 ≤ y`
  - `1 < x ↔ x⁻¹ < 1`

* `linarith` and `chain_ineq` as dischargers?
  probably not... just let the user chain the tactics.

* call specialized parts of `norm_num` as discharger.

-/

meta def pexpr.to_expr
  (e : pexpr) (allow_mvars : opt_param bool tt) (subgoals : opt_param bool tt) : tactic expr :=
tactic.to_expr e allow_mvars subgoals

meta def expr.elab (e : pexpr) (allow_mvars : opt_param bool tt) (subgoals : opt_param bool tt) :
  tactic expr :=
tactic.to_expr e allow_mvars subgoals

namespace tactic

open calc_step calc_step.side calc_step.op calc_step.sign

-- move this to `calc_step` namespace
/-- The default side that the `calc_step` tactic acts on is on the left,
but for `div` (division) the default is to divide on the right. -/
meta def get_side : side → op → side
| L _   := L
| R _   := R
| N mul := L
| N add := L
| N div := R
| N sub := R
| _ _   := N

meta def calc_step_unary (hyp : expr) (pat : expr → pexpr) : tactic pexpr :=
do t ← target,
  let prf := (``(%%(pat hyp) : %%t)),
  prf.elab >> return (pat hyp)

meta def calc_step_binary (val : pexpr) (hyp : expr) (pat : expr → expr → pexpr) : tactic pexpr :=
do t ← target,
  e ← val.elab,
  let prf := (``(%%(pat e hyp) : %%t)),
  prf.elab >> return (pat e hyp)

meta def calc_step (e : option pexpr) (s : side) (op : op) (sgn : sign) : tactic unit :=
focus1 $ do
  let sd := get_side s op,
  newgoal ← mk_mvar,
  prf ← match e with
  | none   := (lookup_unary.find (sd, op, sgn)).mfirst (calc_step_unary newgoal) <|>
              fail "Couldn't find useful lemma"
  | some x := (lookup_binary.find (sd, op, sgn)).mfirst (calc_step_binary x newgoal) <|>
              fail "Couldn't find useful lemma"
  end,
  prf.elab >>= apply,
  trace format!"Try this: {prf}",
  all_goals' $ try $ `[assumption <|> norm_num, done],
  gs ← get_goals,
  set_goals (newgoal::gs)

namespace interactive

setup_tactic_parser

meta def side_p : lean.parser calc_step.side :=
do t ← ident, if t = `L then return side.L else if t = `R then return side.R else failed

meta def sign_p : lean.parser calc_step.sign :=
do t ← ident,
if t = `pos then return sign.pos else
if t = `neg then return sign.neg else
                 return sign.none

meta def op_p : lean.parser calc_step.op :=
do t ← ident,
if t = `mul then return op.mul else
if t = `add then return op.add else
if t = `div then return op.div else
if t = `sub then return op.sub else
if t = `inv then return op.inv else
if t = `neg then return op.neg else
                 failed -- "expecting `mul`, `add`, `div`, `sub`, `inv`, or `neg`"

meta def calc_step (op : parse op_p)
  (q : parse parser.pexpr?) (s : parse side_p?) (sgn : parse sign_p?) :
  tactic unit :=
tactic.calc_step q s.iget op sgn.iget

meta def add (q : parse parser.pexpr) (s : parse side_p?) : tactic unit :=
tactic.calc_step q s.iget op.add none

meta def negate : tactic unit :=
tactic.calc_step none N neg none

meta def subtract (q : parse parser.pexpr) (s : parse side_p?) : tactic unit :=
tactic.calc_step q s.iget sub none

meta def mul_by (q : parse parser.pexpr) (s : parse side_p?) (sgn : parse sign_p?) : tactic unit :=
tactic.calc_step q s.iget mul sgn.iget

meta def div_by (q : parse parser.pexpr) (s : parse side_p?) (sgn : parse sign_p?) : tactic unit :=
tactic.calc_step q s.iget div sgn.iget

meta def take_inv (sgn : parse sign_p?) : tactic unit :=
tactic.calc_step none N inv sgn.iget

end interactive

end tactic


example {G : Type} [group G] (a b c : G) (h : c * a = c * b) : a = b :=
begin
  calc_step mul c,
  -- mul_by 2,
end

example (a b : ℕ) (ha : a ≠ 0) (h : 2 * a = 2 * b) : a = b :=
begin
  calc_step mul 2,
  -- mul_by 2,
end

example (a b : ℚ) (x : ℚ) (h : 2 * a < 2 * b) : a < b :=
begin
  -- negate,
  -- take_inv neg,
  mul_by 2 L pos,
  assumption,
end
