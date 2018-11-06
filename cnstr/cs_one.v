From mathcomp Require Import ssreflect ssrfun.
Require Import all_core all_cs_base.
Require Import FunctionalExtensionality.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section TERMINAL.
Inductive one := star.

Definition id_rep S := make_mf (fun phi (s: S) => phi star = s).

Lemma id_rep_sur S: (@id_rep S) \is_cototal.
Proof. by move => s; exists (fun str => s). Qed.

Definition cs_id_assembly_mixin S: interview_mixin.type (one -> S) (S).
Proof. exists (@id_rep S); exact /id_rep_sur. Defined.

Lemma id_rep_sing S: (@id_rep S) \is_singlevalued.
Proof. by move => s t t' <- <-. Qed.

Definition cs_id_modest_set_mixin S:
	dictionary_mixin.type (interview.Pack (cs_id_assembly_mixin S)).
Proof. split; exact/id_rep_sing. Defined.

Lemma one_count:
	one \is_countable.
Proof.
exists (fun n => match n with 0 => None | S n => Some star end) => q.
by case q => [str | ]; [exists 1; elim: str | exists 0].
Qed.

Canonical cs_one := @continuity_space.Pack
	one
	one
	star
	star
	one_count
	one_count
	(dictionary.Pack (cs_id_modest_set_mixin one)).

Definition one_fun (X: cs) (x: X) := star.

Lemma trmnl_uprp_fun (X: cs): exists! f: X -> one, True.
Proof.
by exists (@one_fun X); split => // f _; apply functional_extensionality => x; elim (f x).
Qed.

Lemma one_fun_hcr (X: cs): (F2MF (@one_fun X): X ->> cs_one) \has_continuous_realizer.
Proof.
exists (F2MF (fun _ _ => star)); split; first by rewrite F2MF_rlzr_F2MF.
by rewrite F2MF_cont; exists (fun _ => nil).
Qed.

Lemma one_fun_cont (X: cs): (@one_fun X: _ -> cs_one) \is_continuous.
Proof. exact/one_fun_hcr. Qed.

Definition one_cfun X := exist_c (@one_fun_hcr X) : (X c-> cs_one).

Lemma trmnl_uprp_cont (X: cs):
	exists! f: X c-> cs_one, True.
Proof.
exists (@one_cfun X); split => // f _.
apply /eq_sub; apply functional_extensionality => x.
by case: (projT1 f x).
Qed.
End TERMINAL.