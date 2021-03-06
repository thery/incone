From mathcomp Require Import ssreflect seq ssrfun ssrbool ssrnat eqtype.
Require Import all_cs reals.
Require Import Qreals Reals Psatz ClassicalChoice FunctionalExtensionality.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section reals_via_rational_approximations.
Import QArith.
Local Open Scope R_scope.

Definition rep_RQ : (Q -> Q) ->> R := make_mf (
  fun phi x => forall eps, 0 < Q2R eps-> Rabs(x-Q2R(phi eps)) <= Q2R eps).
(* This is close to the standard definition of the chauchy representation. Usually integers
are prefered to avoid to many possible answers. I tried using integers, but it got very ugly
so I gave up at some point. I feel like the above is the most natural formulation of the Cauchy
representation anyway. *)

(* Auxillary lemmas for the proof that the Cauchy representation is surjective. *)
Lemma approx : forall r, r - Int_part r <= 1.
Proof. move => r; move: (base_Int_part r) => [bipl bipr]; lra. Qed.

Lemma approx' : forall r, 0 <= r - Int_part r.
Proof. move => r; move: (base_Int_part r) => [bipl bipr]; lra. Qed.

Lemma rep_RQ_sur: rep_RQ \is_cototal.
Proof.
move => x.
exists (fun eps => Qmult eps (Qmake(Int_part(x/(Q2R eps))) xH)) => epsr eg0.
rewrite Q2R_mult.
set eps := Q2R epsr.
rewrite Rabs_pos_eq.
- set z := Int_part(x/eps).
  have ->: (x - eps * Q2R (z#1)) = (eps * (x / eps - z)).
  + rewrite /Q2R/=; field.
    by apply: Rlt_dichotomy_converse; right; rewrite /eps.
  rewrite -{3}(Rmult_1_r eps).
  apply: Rmult_le_compat_l; first by left; rewrite /eps.
  apply: (approx (x * /eps)).
apply: (Rmult_le_reg_l (/eps)).
  by apply: Rinv_0_lt_compat; rewrite /eps.
rewrite Rmult_0_r.
set z := Int_part(x/eps).
have ->: (/eps*(x - eps * Q2R (z#1))) = (x/eps - z).
- rewrite /Q2R/=; field.
  by apply: Rlt_dichotomy_converse; right; rewrite /eps.
by apply (approx' (x * /eps)).
Qed.

Lemma rep_RQ_sing: rep_RQ \is_singlevalued.
Proof.
move => phi x x' phinx phinx'.
apply (cond_eq_f accf_Q2R_0) => q qg0.
set r := Q2R (phi (q/(1 + 1))%Q); rewrite /R_dist.
have ->: (x-x') = ((x-r) + (r-x')) by field.
apply /triang /Rle_trans.
- apply /Rplus_le_compat; last rewrite Rabs_minus_sym; [apply phinx | apply phinx'];
  rewrite Q2R_div; try lra; rewrite {2}/Q2R/=; lra.
by rewrite Q2R_div; try lra; rewrite {2 4}/Q2R/=; lra.
Qed.

Definition RQ := continuity_space.Pack
	0%Q
	0%Q
	Q_countable
	Q_countable
	(make_dict rep_RQ_sur rep_RQ_sing).

Section addition.
Definition Ropp_rlzrf phi (eps: Q) := Qopp (phi eps).

Definition Ropp_rlzr := F2MF Ropp_rlzrf.

Lemma Ropp_rlzr_spec: Ropp_rlzr \realizes (F2MF Ropp: RQ ->> RQ).
Proof.
rewrite F2MF_rlzr_F2MF => phi x phinx eps epsg0 /=.
rewrite Q2R_opp; move: (phinx eps epsg0); split_Rabs; lra.
Qed.

Lemma Ropp_rlzr_cont: Ropp_rlzr \is_continuous_operator.
Proof.
by rewrite cntop_F2MF /Ropp_rlzrf => phi; exists (fun eps => [:: eps]) => psi q' [<-].
Qed.

Lemma Ropp_hcr: (F2MF Ropp: RQ ->> RQ) \has_continuous_realizer.
Proof. exists Ropp_rlzr; split; [apply/Ropp_rlzr_spec | apply/Ropp_rlzr_cont]. Qed.

Lemma Ropp_cont: (Ropp: RQ -> RQ) \is_continuous.
Proof. exact/Ropp_hcr. Qed.

Definition Rplus_rlzrf phi (eps: Q) :=
	(Qplus (phi (inl (Qdiv eps (1+1)))).1 (phi (inr (Qdiv eps (1+1)))).2).

Definition Rplus_rlzr: names (RQ \*_cs RQ) ->> names RQ:= F2MF Rplus_rlzrf.

Lemma Rplus_rlzr_spec:
  Rplus_rlzr \realizes (F2MF (fun x => Rplus x.1 x.2) : (RQ \*_cs RQ) ->> RQ).
Proof.
rewrite F2MF_rlzr_F2MF => phi x phinx eps eg0.
rewrite /Rplus_rlzr Q2R_plus.
set r := Q2R (lprj phi (Qdiv eps (1 + 1))).
set q := Q2R (rprj phi (Qdiv eps (1 + 1))).
have ->: (x.1 + x.2 - (r + q)) = (x.1 - r + (x.2 - q)) by field.
apply: triang; rewrite -(eps2 (Q2R eps)).
have eq: Q2R eps * / 2 = Q2R (eps / (1 + 1)).
- symmetry; rewrite Q2R_div; last by lra.
  by rewrite {2}/Q2R/=; lra.
by rewrite eq; apply: Rplus_le_compat; apply phinx; lra.
Qed.

Lemma Rplus_rlzr_cont: Rplus_rlzr \is_continuous_operator.
Proof.
rewrite cntop_F2MF => phi.
exists (fun eps => [:: inl (Qdiv eps (1 + 1)); inr (Qdiv eps (1 + 1))]).
by rewrite /Rplus_rlzrf => psi q' [-> [->]].
Qed.

Lemma Rplus_cont: (fun (xy: RQ \*_cs RQ) => xy.1 + xy.2: RQ) \is_continuous.
Proof. exists Rplus_rlzr; split; first exact/Rplus_rlzr_spec; exact/Rplus_rlzr_cont. Qed.
End addition.

Section multiplication.
(* Multiplication is more involved as the precision of approximations that have to be used
depends on the size of the inputs *)
  Let trunc eps:Q := if Qlt_le_dec eps 1 then eps else 1%Q.

  Lemma trunc_le eps: Q2R (trunc eps) <= Q2R eps.
  Proof.
      by rewrite /trunc; case: (Qlt_le_dec eps 1) => ass /=; [lra | apply Qle_Rle].
  Qed.

  Lemma truncI eps: 0 < Q2R eps -> 0 < Q2R (trunc eps) <= 1.
  Proof.
    rewrite /trunc; case: (Qlt_le_dec eps 1) => /= ass; last by rewrite /Q2R/=; lra.
    split => //; apply Rlt_le; replace 1 with (Q2R 1) by by rewrite /Q2R/=; lra.
    by apply Qlt_Rlt.
  Qed.

  Let rab := (fun (phi : Q -> Q) => inject_Z (up(Rabs(Q2R(phi (1#2)))+1))).

  Lemma rab_pos phi: 1 <= Q2R (rab phi).
  Proof.
    rewrite /Q2R/rab/=; rewrite Rinv_1 Rmult_1_r.
    apply: Rle_trans; last by apply Rlt_le; apply archimed.
    by rewrite -{1}(Rplus_0_l 1); apply Rplus_le_compat_r; exact: Rabs_pos.
  Qed.

  Lemma up_le r: up r <= r + 1.
  Proof. by have:= archimed r; lra. Qed.

  Lemma up_lt r : r < up r.
  Proof. by have:= archimed r; lra. Qed.

  Lemma rab_spec phi (x: RQ): phi \is_description_of x ->
                      Rabs x <= Q2R (rab phi).
  Proof.
    move => phinx.
    rewrite /rab{1}/Q2R/= Rinv_1 Rmult_1_r.
    apply/Rle_trans/Rlt_le/up_lt.
    suff: Rabs x - Rabs (Q2R (phi (1#2))) <= 1 by lra.
    apply/Rle_trans; first apply/Rabs_triang_inv.
    apply/Rle_trans; first apply/phinx; rewrite /Q2R/=; lra.
 Qed.
    
  Definition Rmult_rlzrf phi (eps: Q) :=
    (lprj phi (trunc eps / (1 + 1)/(rab (rprj phi)))
     *
     (rprj phi (eps / (1 + 1)/(rab (lprj phi)))))%Q.
  
  Definition Rmult_rlzr : names (RQ \*_cs RQ) ->> names RQ:= F2MF Rmult_rlzrf.

  Lemma Rmult_rlzr_spec:
    Rmult_rlzr \realizes (F2MF (fun x => Rmult x.1 x.2):RQ \*_cs RQ ->> RQ).
  Proof.
    rewrite F2MF_rlzr_F2MF => phi [x y] [phinx psiny] eps eg0 /=.
    rewrite Q2R_mult.
    set r := Q2R (lprj phi (trunc eps / (1 + 1) / rab (rprj phi))%Q).
    set q := Q2R (rprj phi (eps / (1 + 1) / rab (lprj phi))%Q).
    have g0: 0 < Q2R (eps / (1 + 1)) by rewrite Q2R_div; first rewrite {2}/Q2R/=; lra.
    have ->: (x * y - r * q) = ((x - r) * y + r * (y - q)) by field.
    have ->: (Q2R eps) = (Q2R (eps/ (1 + 1)) + Q2R (eps/ (1 + 1))).
    - by rewrite Q2R_div; first rewrite {3 5}/Q2R/=; lra.
    apply/triang/Rplus_le_compat.
    - rewrite Rabs_mult; have rab_pos:= (rab_pos (rprj phi)).
      case: (classic (y = 0)) => [eq | neq].
      + by apply/ Rle_trans; last apply/ Rlt_le /g0; rewrite eq Rabs_R0; lra.
      rewrite -[X in _ <= X]Rmult_1_r -(Rinv_l (Rabs y)); last by split_Rabs; lra.
      rewrite -Rmult_assoc; apply: Rmult_le_compat; try by split_Rabs; lra.
      have neq': ~ rab (rprj phi) == 0 => [/Qeq_eqR eq | ].
      + by have := rab_pos; rewrite eq /Q2R /=; lra.
      have le:= truncI eg0.
      apply/Rle_trans.
      + apply/phinx; rewrite Q2R_div; try lra.
        apply Rmult_gt_0_compat; last by apply Rlt_gt; apply Rinv_0_lt_compat; lra.
        by rewrite Q2R_div; first rewrite {2}/Q2R/=; try lra.
        rewrite Q2R_div// Q2R_div//Q2R_div// {2 5}/Q2R/=; try lra.
      have le':= trunc_le eps.
      apply/Rmult_le_compat; try lra.
      by apply/Rlt_le/Rinv_0_lt_compat/Rlt_le_trans/rab_pos; lra.
    apply Rinv_le_contravar; first by split_Rabs; lra.
    exact /rab_spec.
  rewrite Rabs_mult; case: (classic (r = 0)) => [eq | neq].
  - by apply/ Rle_trans; [rewrite eq Rabs_R0 | apply/ Rlt_le/ g0]; lra.
  rewrite /Qdiv -(Rmult_1_l (Q2R (eps / (1 + 1)))).
  rewrite -(Rinv_r (Rabs r)); last by split_Rabs; lra.
  rewrite Rmult_assoc; apply: Rmult_le_compat; try by split_Rabs; lra.
  have neq': ~ rab (lprj phi) == 0 => [/Qeq_eqR eq | ].
  - by have := rab_pos (lprj phi); rewrite eq /Q2R /=; lra.
  rewrite Rmult_comm; apply/ Rle_trans; first apply psiny.
    suff lt: 0 < / Q2R (rab (lprj phi)).
    + by rewrite Q2R_div /Rdiv; first apply/Rmult_lt_0_compat; lra.
    by apply/Rinv_0_lt_compat/Rlt_le_trans/rab_pos; lra.
  rewrite Q2R_div; try lra.
  rewrite /Rdiv; apply Rmult_le_compat_l; try lra.
  apply Rle_Rinv; first exact: Rabs_pos_lt; try lra.
  - rewrite /rab {1}/Q2R/= Rinv_1 Rmult_1_r.
    apply/Rle_lt_trans/(archimed (Rabs (Q2R (lprj phi (1 # 2)))+1)).1.
    by have:= Rabs_pos (Q2R (lprj phi (1#2))); lra.
  rewrite /rab{1}/Q2R/= Rinv_1 Rmult_1_r.
  apply/Rle_trans/Rlt_le/(archimed (Rabs (Q2R (lprj phi (1 # 2)))+1)).1.
  suffices: (Rabs r - Rabs (Q2R (lprj phi (1#2))) <= 1) by lra.
  apply/ Rle_trans; first exact/Rabs_triang_inv.
  have ->: (r - Q2R (lprj phi (1#2))) = ((r - x) - (Q2R (lprj phi (1#2)) - x)) by field.  
  apply/Rle_trans.
  apply/triang/Rplus_le_compat; last rewrite Rabs_Ropp.
  rewrite Rabs_minus_sym; apply/phinx.
  rewrite Q2R_div; first rewrite  /Qdiv Q2R_mult; first apply/Rmult_lt_0_compat.
  rewrite {2}/Q2R/=; have := truncI eg0; lra.
  by apply/Rinv_0_lt_compat/Rlt_le_trans/rab_pos; lra.
  by move => /Qeq_eqR eq; have := rab_pos (rprj phi); rewrite eq /Q2R /=; lra.
  rewrite Rabs_minus_sym; apply/phinx; rewrite /Q2R/=; lra.
  have rps:= rab_pos (rprj phi).
  apply/Rle_trans.
  - apply/Rplus_le_compat_r; rewrite/Rdiv.
    rewrite Q2R_div => [ | /Qeq_eqR eq]; last by rewrite /Q2R /=; lra.
    apply/Rmult_le_compat_l/Rinv_le_contravar/rab_pos; try lra.
    by have:= truncI eg0; rewrite /Qdiv Q2R_mult {4}/Q2R/=; lra.
  by rewrite Rinv_1 Rmult_1_r /Qdiv Q2R_mult {2 3}/Q2R/=; have:= truncI eg0; lra.
Qed.
End multiplication.

Section limit.
(* The unrestricted limit function is discontinuous with respect to the Cauchy representation,
and thus there is no hope to prove it computable *)
Lemma cnst_dscr q: (cnst q) \is_description_of (Q2R q: RQ).
Proof. rewrite /cnst => eps; split_Rabs; lra. Qed.

Lemma cnst_sqnc_dscr q: (cnst q) \is_description_of (cnst (Q2R q): RQ\^w).
Proof. rewrite /cnst => n eps ineq; split_Rabs; lra. Qed.

Lemma Q_sqnc_dscr qn:
  (fun neps => qn neps.1) \is_description_of ((fun n => Q2R (qn n)): RQ\^w).
Proof. move => n eps ineq /=; split_Rabs; lra. Qed.

Lemma lim_cnst x: lim (cnst x) x.
Proof. exists 0%nat; rewrite /cnst; split_Rabs; lra. Qed.

Lemma lim_not_cont: ~(lim: RQ\^w ->> RQ) \has_continuous_realizer.
Proof.
move => [/= F [/= rlzr /cntop_spec cont]].
pose xn := cnst (Q2R 0): RQ\^w.
have limxn0: lim xn (Q2R 0) by exists 0%nat; rewrite /xn/cnst; split_Rabs; lra.
have qnfdF: cnst 0%Q \from dom F.
	by apply /(rlzr_dom rlzr); [exact/cnst_sqnc_dscr | exists (Q2R 0)].
have [Lf Lmod]:= cont (cnst 0%Q) qnfdF.
set fold := @List.fold_right nat nat.
pose L := Lf 1%Q.
pose m:= fold maxn 0%N (unzip1 L).
have mprop: forall n eps, List.In (n, eps) L -> (n <= m)%nat.
	rewrite /m; elim: {1 2}L => // a K ih n eps /=.
	by case =>[-> | ineq]; apply/leq_trans; [ | apply/leq_maxl | apply/ih/ineq | apply/leq_maxr].
pose yn:= (fun n => Q2R (if (n <= m)%nat then 0%Q else 3#1)): RQ\^w.
pose rn (p: nat * Q) := if (p.1 <= m)%nat then 0%Q else 3#1.
have rnyn: rn \is_description_of yn by apply/Q_sqnc_dscr.
have limyn3: lim yn 3.
	exists (S m) => n /leP ineq; rewrite /yn.
	case: ifP => [/leP ineq' | ]; [lia | split_Rabs; lra].
have [phi Frnphi]: rn \from dom F by apply /(rlzr_dom rlzr); first exact/rnyn; exists 3.
have coin: (cnst 0%Q) \and rn \coincide_on L.
	apply /coin_lstn => [[n eps] listin].
	rewrite /cnst /rn; case: ifP => // /= /leP ineq.
	exfalso; apply/ineq/leP/mprop/listin.
have [psi Fqnpsi]:= qnfdF.
have eq: psi 1%Q == phi 1%Q.
- have [a' crt]:= Lmod 1%Q; rewrite (crt rn coin phi)// (crt (cnst 0%Q) _ psi) //.
  exact/coin_ref.
have := Qeq_eqR (psi 1%Q) (phi 1%Q) eq.
have psin0: psi \is_description_of (0: RQ).
	apply /(rlzr_val_sing _ rlzr)/Fqnpsi/lim_cnst; first exact/lim_sing.
	rewrite /cnst/=/Q2R /=; split_Rabs; lra.
have phin3: phi \is_description_of (3: RQ).
	by apply/(rlzr_val_sing _ rlzr)/Frnphi/limyn3; first exact/lim_sing.
have l01: 0 < Q2R 1 by rewrite /Q2R/=; lra.
have:= psin0 1%Q l01; have:= phin3 1%Q l01.
by rewrite {2 4}/Q2R/=; split_Rabs; lra.
Qed.

Fixpoint Pos_size p := match p with
	| xH => 1%nat
	| xI p' => S (Pos_size p')
	| xO p' => S (Pos_size p')
end.

Lemma Pos_size_gt0 p: (0 < Pos_size p)%nat.
Proof. by elim p. Qed.

Definition Z_size z:= match z with
	| Z0 => 0%nat
	| Z.pos p => Pos_size p
	| Z.neg p => Pos_size p
end.

Lemma Z_size_eq0 z: Z_size z = 0%nat <-> z = 0%Z.
Proof.
split; last by move => ->.
case z => // p /=; have := Pos_size_gt0 p => /leP ineq eq; rewrite eq in ineq; lia.
Qed.

Lemma Z_size_lt z: IZR z < 2 ^ (Z_size z).
Proof.
rewrite pow_IZR; apply IZR_lt; rewrite -two_power_nat_equiv.
elim: z => // p; elim: p => // p /= ih.
rewrite !Pos2Z.inj_xI two_power_nat_S.
have ineq: (Z.pos p + 1 <= two_power_nat (Pos_size p))%Z by lia.
apply/ Z.lt_le_trans; last by apply Zmult_le_compat_l; last lia; apply ineq.
by lia.
Qed.

Lemma size_Qden_leq eps: 0 < Q2R eps -> /2^(Pos_size (Qden eps)) <= Q2R eps.
Proof.
move => ineq; rewrite /Q2R/Rdiv /Qdiv -[/_]Rmult_1_l.
apply Rmult_le_compat; [ | apply Rlt_le; apply Rinv_0_lt_compat; apply pow_lt | | ]; try lra.
	apply IZR_le; suffices: (0 < Qnum eps)%Z by lia.
	by apply Qnum_gt; apply Rlt_Qlt; rewrite {1}/Q2R/=; try lra.
apply Rinv_le_contravar; first exact /IZR_lt/Pos2Z.is_pos.
by have /=:= Z_size_lt (Z.pos (Qden eps)); lra.
Qed.

Definition lim_eff_frlzr phin eps :=
	phin (S (Pos_size (Qden eps))%nat, (Qmult eps (1#2))): Q.

Definition lim_eff_rlzr := F2MF lim_eff_frlzr.

Lemma lim_eff_frlzr_crct:
	lim_eff_rlzr \realizes (lim_eff: RQ\^w ->> RQ).
Proof.
rewrite F2MF_rlzr => psi xn psinxn [x limxnx].
exists x; split => // eps epsg0.
set N:= (Pos_size (Qden eps)).
have ->: x - Q2R (lim_eff_frlzr psi eps) = x - (xn N.+1) + (xn N.+1 - Q2R (lim_eff_frlzr psi eps)) by lra.
rewrite /lim_eff_frlzr -/N; apply/triang/Rle_trans.
	apply/Rplus_le_compat; first by rewrite Rabs_minus_sym; apply/limxnx.
	by apply psinxn; rewrite Q2R_mult {2}/Q2R/=; lra.
have lt1:= pow_lt 2 (Pos_size (Qden eps)); have lt2:= size_Qden_leq epsg0.
by rewrite Q2R_mult {2}/Q2R /= /N Rinv_mult_distr; lra.
Qed.
End limit.

Require Import sets.

Definition sign (x: RQ) : cs_Kleeneans := match (total_order_T x 0) with
                     | inleft l => match l with
                                  | left _ => false_K
                                  | right _ => bot_K
                                  end
                     | inright _ => true_K
                     end.

Definition mf_sign:= F2MF sign.

Definition sign_rlzrf phi n : option bool :=
  let eps := Qpower_positive (1#2) (Pos.of_nat n) in
  let q := phi eps in
  if Qlt_le_dec q (Qopp eps) then Some false else
    if Qlt_le_dec eps q then Some true else None.

Definition sign_rlzr := F2MF sign_rlzrf.

Lemma sign_rlzr_spec:
  sign_rlzr \realizes mf_sign.
Proof.
rewrite F2MF_rlzr_F2MF => phi x phinx /=; rewrite /sign /=.
case: (total_order_T x 0) => [[lt | eq] | gt].
- - have gt: 0 < -x by lra.
    have [r [ineq ineq']]:= accf_Q2R_0 gt.
    exists (Pos_size (Qden r)).
    rewrite /sign_rlzrf /=.
    have []:= phinx (Qpower_positive (1#2) (Pos.of_nat (Pos_size (Qden r)))).
Admitted.

Lemma sign_rlzr_cntop:
  sign_rlzr \is_continuous_operator.
Proof.
rewrite cntop_F2MF => phi.
exists (fun n => [:: Qpower_positive (1#2) (Pos.of_nat n)]) => phi' n /= [coin _].
by rewrite /sign_rlzrf /= coin.
Qed.

Lemma sign_cont: sign \is_continuous.
Proof. by exists sign_rlzr; split; [exact/sign_rlzr_spec | exact/sign_rlzr_cntop]. Qed.
End reals_via_rational_approximations.