From mathcomp Require Import all_ssreflect zify.
From Equations Require Import Equations.
From mathcomp Require Import finmap.


Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

From Dep Require Import Global_Syntax Inductive_Linearity.

(*Substitutions.*)



Open Scope fset_scope.
Open Scope fmap_scope.
Lemma in_ptcp_of_act_f : forall a, (ptcp_from a \in  a).
Proof. case. intros. rewrite //=.  Qed.

Lemma in_ptcp_of_act_t : forall a, (ptcp_to a \in a).
Proof. case. intros. rewrite //=. Qed.

Coercion ptcps_of_act (a : action) := ptcp_from a |` [fset ptcp_to a].
Definition env := {fmap ptcp -> endpoint}.  
Definition ptcps := {fset ptcp}.



Lemma ptcps_of_act_eq : forall a, ptcps_of_act a = [fset ptcp_from a; ptcp_to a].
Proof. done. Qed.

Lemma in_action_eq : forall p a, p \in a = (p == ptcp_from a) ||  (p == ptcp_to a).
Proof. intros. destruct a. rewrite /= /ptcps_of_act /in_mem /=. lia. Qed.
Notation negb_invol :=  Bool.negb_involutive.

Fixpoint ptcps_of_g (g : gType) : {fset ptcp} := 
match g with 
| GMsg a _ g0 => a `|`(ptcps_of_g g0)
| GBranch a gs => a `|` \bigcup_( i <- map ptcps_of_g gs) i
| GRec n g0 => ptcps_of_g g0
| _ => fset0
end.

Ltac split_and := intros;repeat (match goal with 
                   | [ H : is_true (_ && _) |- _ ] => destruct (andP H);clear H
                   | [ |- is_true (_ && _) ] => apply/andP;split 

                  end);auto.



Coercion ptcps_of_g : gType >-> finset_of. 
Let inE := (inE,in_ptcp_of_act_f,in_ptcp_of_act_t,negb_or,negb_and,ptcps_of_act_eq,in_action_eq,negb_invol,eqxx).

Lemma mapf : forall (A : choiceType) (B : Type) (S : {fset A}) (F : A -> B) (k : A), k \in S -> [fmap x : S => F (val x)].[? k] = Some (F k).
Proof.
intros. rewrite /=. rewrite /fnd.  case : insubP;rewrite /=;intros; subst. f_equal. rewrite ffunE. done. rewrite H in i. done. 
Qed.

Lemma mapf2 : forall (A : choiceType) (B : Type) (S : {fset A}) (F : A -> B) (k : A), k \notin S -> [fmap x : S => F (val x)].[? k] = None.
Proof.
intros. rewrite /=. rewrite /fnd.  case : insubP;rewrite /=;intros; subst. rewrite i in H. done. done. 
Qed.

Lemma mapf_if : forall (A : choiceType) (B : Type) (S : {fset A}) (F : A -> B) (k : A),  [fmap x : S => F (val x)].[? k] = if k \in S then Some (F k) else  None.
Proof.
intros. rifliad. rewrite mapf. done. done. rewrite mapf2. done. lia. 
Qed.

Lemma fsubset_in : forall (A : choiceType) (b c : {fset A}), b `<=` c -> (forall j, j \in b -> j \in c).
Proof.
intros. Search _ fsub1set. move : H0. rewrite -!fsub1set.  intros. apply : fsubset_trans. apply : H0. apply H. 
Qed.


Lemma neg_sym : forall (A : eqType) (a b : A), (a != b) = (b != a).
Proof.
intros. destruct (eqVneq a b).  done. done. 
Qed.



Lemma apply_allP : forall (A : eqType) (P : A -> bool) l x, all P l -> x \in l -> P x. intros. by apply (allP H). Qed.
Lemma apply_allP2 : forall (A : eqType) (P : A -> bool) l x (P0 : bool), P0 && all P l -> x \in l -> P x. 
intros. destruct (andP H). by apply (allP H2). Qed.

Hint Resolve apply_allP apply_allP2.

Lemma and_left : forall (b0 b1 : bool), b0 && b1 -> b0.
Proof. intros. apply (andP H). Qed. 

Lemma and_right : forall (b0 b1 : bool), b0 && b1 -> b1.
Proof. intros. apply (andP H). Qed. 


Lemma true_right : forall (b : bool), b -> b && true.
Proof. intros. rewrite H. done. Qed.

Hint Resolve and_left and_right mem_nth true_right. 


(*Note we project GRec GEnd to ERec EEnd instead of to EEnd as the paper does*)
(*This is bad because projection can make non-contractive types, so change proj and project to original definition for recursion, then show boundness is preserved by projection and finally that projecting onto ptcp not present in gtype returns end, finally you can finish the proof of projP *)

Definition is_leaf g := if g is EEnd then true else if g is EVar _ then true else false.
Definition is_var g := if g is EVar _ then true else false.

(*Fixpoint binds_e (i : nat) (e : endpoint) := 
 match e with
  | EVar n => if n == i then true else false 
  | EEnd => false 
  | EMsg d a u e0' => binds_e i e0'
  | EBranch d a es => has (binds_e i) es 
  | ERec e0' => binds_e i.+1 e0'
  end.

Fixpoint sdf (i : nat) (e : endpoint) :=
 match e with
  | EVar n => if i < n then EVar n.-1 else e
  | EEnd => e 
  | EMsg d a u e0' => EMsg d a u (sdf i e0')
  | EBranch d a es => EBranch d a (map (sdf i) es)
  | ERec e0' => ERec (sdf i.+1 e0')
  end.*)



Fixpoint fv (e : endpoint)  :=  
match e with 
| EMsg d c v e0 => fv e0
| EBranch d c es => \bigcup_( i <- map fv es) i 
| ERec n e0 => (fv e0) `\  n
| EVar j => [fset j]
| EEnd => fset0
end.


Inductive proj : gType -> ptcp -> endpoint -> Prop :=
| cp_msg_from g e a u : proj g (ptcp_from a) e -> proj (GMsg a u g) (ptcp_from a) (EMsg Sd (action_ch a) u e)
| cp_msg_to g e a u : proj g (ptcp_to a) e -> proj (GMsg a u g) (ptcp_to a) (EMsg Rd (action_ch a) u e)
| cp_msg_other g a e  u p : p \notin a -> proj g p e -> proj  (GMsg a u g) p e
| cp_branch_from gs es a : size gs = size es -> Forall (fun p => proj p.1 (ptcp_from a) p.2) (zip gs es) -> 
                                 proj (GBranch a gs) (ptcp_from a) (EBranch Sd (action_ch a) es)
| cp_branch_to gs es a : size gs = size es ->Forall (fun p => proj p.1 (ptcp_to a) p.2) (zip gs es) -> 
                               proj  (GBranch a gs) (ptcp_to a) (EBranch Rd (action_ch a) es)
| cp_branch_other gs p e a : p \notin a -> Forall (fun g => proj g p e) gs -> 
                               proj (GBranch a gs) p e
| cp_end p : proj GEnd p EEnd
| cp_rec0 g p n : proj g p (EVar n)  -> proj (GRec n g) p EEnd
| cp_rec1 g p e n : proj g p e  -> e <> EVar n -> n \in (fv e) -> proj (GRec n g) p (ERec n e)
| cp_rec2 g p e n : proj g p e  ->  n \notin (fv e) -> proj (GRec n g) p e
| cp_var n p : proj (GVar n) p (EVar n).
Hint Constructors proj.





(*We must project mu.a0.a1.var 0 to end as projection on non-involved ptcps gives exotic types. Realized this from last proof goal in projP where each branch must proejct to the same outside the support of the props S g*)



(*Definition project_rec e := if e == EVar 0 then EEnd else if binds_e 0 e then ERec e else sdf 0 e.*)

(*Replaced GRec GEnd -> EEnd and GRec GVar _ -> EEnd with a membership test,
  this is what the other definitions implicitly checks, but now we make it explicit
  For the original definition, projection doesn't commute with substitution, fx projection on (GRec (GVar n)) then substituting vs
  first substituting then projecting. This is an exotic term, but to use that fact we must assume contractiveness and in the message case the counter resets, and we can only increment if it we also assume boundness and now we must carry these assumptions through all proofs that use them. Instead we do the membership test and hope it now commutes *)
(*Fixpoint project g p := 
match g with 
| GEnd => EEnd
| GMsg a u g0 => if p == (ptcp_from a) then EMsg Sd (action_ch a) u (project g0 p) 
                               else if p == (ptcp_to a) then EMsg Rd (action_ch a) u (project g0 p) else project g0 p
| GBranch a gs => if p == (ptcp_from a) then EBranch Sd (action_ch a) (map (fun g => project g p) gs)
                                else if p == (ptcp_to a) then EBranch Rd (action_ch a) (map (fun g => project g p) gs) else if gs is g'::gs' then project g' p else EEnd
| GRec g => project_rec  (project g p)
| GVar n => EVar n
end.*)



*

Section Pred.

Fixpoint traverse_pred (P : gType -> bool) g := P g &&
match g with 
| GMsg _ _ g0 => traverse_pred P g0
| GBranch _ gs => all (traverse_pred P) gs
| GRec n g' => traverse_pred P g'
| _ => true 
end.



Definition action_pred (g : gType) :=
match g with 
| GMsg a u g0 => (~~ (ptcp_from a == ptcp_to a))
| GBranch a gs => (~~ (ptcp_from a == ptcp_to a))
| _ => true
end.

Definition size_pred (g : gType) :=
match g with 
| GBranch a gs => (0 < size gs) 
| _ => true
end.

(*Definition self_action ( a : action) := ptcp_from a == ptcp_to a *)


(*Lemma test : forall a gs, traverse_pred action_pred (GBranch a gs) -> (~~ (ptcp_from a == ptcp_to a)). eauto.*)

Definition all_eq_F (A B : eqType)  (F : A -> B) (l : seq A) (a : A)  := all (fun g' => F a == F g') l.

Fixpoint rproject g p := 
match g with 
| GEnd => EEnd
| GMsg a u g0 => if p == (ptcp_from a) then EMsg Sd (action_ch a) u (rproject g0 p) 
                               else if p == (ptcp_to a) then EMsg Rd (action_ch a) u (rproject g0 p) else rproject g0 p
| GBranch a gs => if p == (ptcp_from a) then EBranch Sd (action_ch a) (map (fun g => rproject g p) gs)
                                else if p == (ptcp_to a) then EBranch Rd (action_ch a) (map (fun g => rproject g p) gs) else if gs is g'::gs' then rproject g' p else EEnd
| GRec n g => (ERec n (rproject g p))
| GVar n => EVar n
end.



Fixpoint clean e := 
match e with 
| EMsg d c v e0 => EMsg d c v (clean e0)
| EBranch d c es => EBranch d c (map clean es)
| ERec n e0 => if clean e0 == EVar n then EEnd else if n \in (fv e0) then ERec n (clean e0) else clean e0
| EVar j => EVar j
| EEnd => EEnd
end.
Print SubstType.


Lemma fv_clean e :  fv (clean e) = fv e. 
Proof. elim : e;try solve [rewrite /=;try done];intros. 
rewrite /=. rifliad. rewrite (eqP H0) in H. rewrite -H /=. by rewrite fsetDv. 
rewrite /= H. done. rewrite H. Search _ (?a `\` _ = ?a). rewrite mem_fsetD1 //=. lia. 
rewrite /= !big_map. induction l. rewrite !big_nil. done. rewrite !big_cons. f_equal. rewrite H. done. rewrite !inE. done. apply IHl. intros. apply H. rewrite !inE H0.  lia.
Qed.




Lemma subst_nop : forall e e' x, x \notin (fv e) -> subst_e x e e' = e. Proof. 
elim;rewrite /=;try done;intros. move : H. rewrite !inE.  rewrite neg_sym. move/negbTE=>->. done. 
move : H0. rewrite !inE. move/orP=>[]. by rewrite eq_sym=>->.  
intros. rifliad. rewrite H //=. 
f_equal. auto. f_equal. rewrite big_map in H0.  induction l. done. simpl. f_equal.  apply H.  rewrite !inE.  lia. simpl in H0. move : H0. 
rewrite big_cons. rewrite !inE. split_and. apply IHl. intros. apply H. rewrite !inE H1. lia. done. move : H0.  rewrite big_cons !inE. split_and. 
Qed.


Lemma fv_nil_var : forall e n, fv e = fset0 -> e <> EVar n. 
Proof.
elim;rewrite /=;try  done. intros. have : n \in [fset n]. by  rewrite !inE. move : H. move/fsetP=>->. done. 
Qed.


Lemma fv_subst : forall  e e' n x, fv e' = fset0 -> n <> x -> (n \in (fv (subst_e x e e'))) = (n \in (fv e)).
Proof. elim;rewrite /=;try done;intros. rewrite !inE. rifliad. rewrite H !inE. have : n0 == n = false by lia. by move=>->. 
rewrite /= !inE. done. 
rifliad. rewrite /=. Check mem_map. Search (_ \in (map _ _)). Search _ (_ \in _ = _ \in _).  Search _ ((is_true _ -> is_true _) -> _ = _). rewrite !inE.  destruct (n0 != n)eqn:Heqn;rewrite /= //=.   rewrite Heqn //=.
apply H. done. done. rewrite Heqn //=. 
rewrite !big_map.  elim : l H. rewrite !big_nil. done. intros. rewrite !big_cons. rewrite !inE. rewrite H2 //=. 
destruct ( (n \in fv a)) eqn:Heqn; rewrite !Heqn //=. apply H. intros. apply H2. rewrite !inE H3. lia. done. done. rewrite !inE. done.
Qed.

Lemma clean_subst : forall (e0 : endpoint)  e' x, fv e' = fset0 -> clean (e0[e e'//x]) = (clean e0)[e clean e'//x].
Proof.
elim;intros. 
- simpl. rifliad.
- simpl. done.
- simpl. case_if.  
 * rewrite (eqP H1) /=. rifliad. by rewrite /= eqxx. rewrite subst_nop //=. rewrite fv_clean. lia. 
 * rewrite /= H //=.  rewrite fv_subst //=; last lia. symmetry. case_if.
  ** by rewrite (eqP H2) /= H1 eqxx. 
  ** case_if.
   *** rewrite /= H1. rifliad. exfalso. move : H4. destruct (clean e);rewrite /=.  rifliad. move/eqP. apply : fv_nil_var. 
       rewrite fv_clean //=. by rewrite H2. done. done. done. rifliad.

   *** rifliad. exfalso. move : H4. destruct (clean e);rewrite /=.  rifliad. move/eqP. apply : fv_nil_var. 
       rewrite fv_clean //=. by rewrite H2. done. done. done. rifliad.
- rewrite /= H //=. 
- rewrite /=. f_equal. rewrite -!map_comp. apply/eq_in_map. move => ll Hin /=. rewrite H //=.
Qed.

Lemma rproject_subst : forall g g0 p i,  rproject (g[g g0//i]) p = (rproject g p)[e (rproject g0 p)//i].
Proof. elim;rewrite /=;try done;intros. rifliad. rifliad. rewrite /=.  rewrite H. done.  
rifliad. simpl. f_equal. done. simpl. f_equal. done. 
rifliad. simpl. f_equal. 
rewrite -!map_comp. apply/eq_in_map. move=>ll Hin. simpl. apply H.  done. 
simpl. f_equal.
rewrite -!map_comp. apply/eq_in_map. move=>ll Hin. simpl. apply H.  done. destruct l. done. simpl. apply H. rewrite !inE. done. 
Qed.



Fixpoint fv_g (g : gType) :=
  match g with
  | GVar j => [fset j]
  | GEnd => fset0
  | GMsg _ _ g0 => fv_g g0
  | GBranch _ gs => \bigcup_( i <- map fv_g gs) i 
  | GRec n g0 => (fv_g g0) `\ n
  end.




Fixpoint project g p := 
match g with 
| GEnd => EEnd
| GMsg a u g0 => if p == (ptcp_from a) then EMsg Sd (action_ch a) u (project g0 p) 
                               else if p == (ptcp_to a) then EMsg Rd (action_ch a) u (project g0 p) else project g0 p
| GBranch a gs => if p == (ptcp_from a) then EBranch Sd (action_ch a) (map (fun g => project g p) gs)
                                else if p == (ptcp_to a) then EBranch Rd (action_ch a) (map (fun g => project g p) gs) else if gs is g'::gs' then project g' p else EEnd
| GRec n g => if (project g p) == EVar n then EEnd else if n \in (fv (project g p)) then ERec n (project g p) else project g p
| GVar n => EVar n
end.

Lemma match_n : forall (gs : seq gType) k,  match gs with
  | [::] => EEnd
  | g'0 :: _ => project g'0 k end = project (nth GEnd gs 0) k.
Proof.
elim. done. intros. rewrite /=. done.
Qed.

Lemma project_clean_rproject : forall g p, project g p = clean (rproject g p).
Proof.
elim;rewrite /=;try done;intros.
- rifliad.
 * move : H1. by  rewrite -H (eqP H0) eqxx. 
 * move : H1. by  rewrite -H (eqP H0) eqxx. 
 * move : H0. rewrite H (eqP H2) eqxx. done. 
 * rewrite H. done. 
 * rewrite H in H1. rewrite fv_clean in H1. lia. 
 * move : H1.  rewrite H (eqP H2) /= inE eqxx. done. 
 * move : H1.  rewrite H fv_clean H3.  done. 
- rifliad;rewrite //=;try f_equal;eauto.
- rifliad;rewrite //=;try f_equal;eauto.
 * rewrite -map_comp. induction l. done. simpl.  f_equal.  apply H. rewrite !inE. lia. apply IHl. intros. apply H. rewrite !inE H1.
 lia. 
 * rewrite -map_comp. induction l. done. simpl.  f_equal.  apply H. rewrite !inE. lia. apply IHl. intros. apply H. rewrite !inE H2.
 lia. 
destruct l;try done.  apply H. rewrite !inE. done. 
Qed.


Lemma fv_rproject_in : forall g p n,  n  \in (fv (project g p)) -> n \in (fv_g g).
Proof. move => g p n. rewrite project_clean_rproject fv_clean. move : g p n.
elim;rewrite /=;intros;try done. move : H0. rewrite !inE. split_and. eauto.  
destruct (p == ptcp_from a) eqn:Heqn.  simpl in H0. eauto. 
destruct (p == ptcp_to a) eqn:Heqn2.  simpl in H0. eauto. 
eauto. move : H0.  rifliad.  simpl. rewrite !big_map. 
elim : l H n.  rewrite !big_nil. done. intros. move : H2.  rewrite !big_cons !inE.  move/orP=>[]. move/H1.  move=>-> //=. by rewrite !inE. intros. apply/orP. right. apply H.  intros. apply : H1. rewrite !inE H2. lia. eauto. done.

elim : l H n.  done. simpl. intros. move : H3.  rewrite !big_cons !inE. move/orP=>[]. move/H2.  move=>-> //=. by rewrite !inE. intros. apply/orP. right. apply H.  intros. apply : H2. rewrite !inE H3. lia. eauto. done. rewrite big_map.
destruct l. done. intros. rewrite big_cons !inE. erewrite H. done. rewrite !inE //=. eauto. 
Qed.

Lemma fv_project : forall g p, fv_g g = fset0 -> fv (project g p) = fset0.
Proof. intros. apply/fsetP=>k. destruct ( (k \in fv (project g p))) eqn :Heqn. move : Heqn. rewrite project_clean_rproject fv_clean. move : H. move/fsetP=>Hall. intros. rewrite -Hall. erewrite (@fv_rproject_in _ p).  done. rewrite project_clean_rproject.  rewrite fv_clean. done. rewrite !inE. done. 
Qed.

Lemma clean_rproject_subst : forall g g0 p i,  fv_g g0 = fset0 -> clean (rproject (g[g g0//i]) p) = (clean (rproject g p))[e (clean (rproject g0 p))//i].
Proof. intros. rewrite rproject_subst clean_subst. done. rewrite -fv_clean. rewrite -project_clean_rproject. rewrite fv_project //=. Qed.

Lemma project_subst : forall g g0 p i,  fv_g g0 = fset0 -> project g[g g0//i] p = (project g p)[e (project g0 p)//i].
Proof. intros. rewrite !project_clean_rproject. rewrite clean_rproject_subst //=. Qed.




Definition projmap  (S : ptcps) (g : gType)  : env := [fmap p : S => project g (val p)].

(*From metatheory*)
Definition ptcp_le (p0 p1 : ptcp) := let: Ptcp n0 := p0 in let: Ptcp n1 := p1 in n0 <= n1.

  Lemma nat_list_max : forall (xs : list ptcp),
    { n : ptcp | forall x, x \in xs -> ptcp_le x  n }.
  Proof.
    induction xs as [ | x xs [y H] ].
    (* case: nil *)
    exists (Ptcp 0). inversion 1.
    (* case: cons x xs *) destruct x,y.
    exists (Ptcp (n + n0)%nat). intros z J. move : J. rewrite inE. move/orP=>[]. move/eqP=>->. rewrite /=. lia. move/H. rewrite /ptcp_le. destruct z.  lia. 
   Qed.

 Lemma atom_fresh_for_list :
    forall (xs : list ptcp), { n : ptcp | ~ n \in xs }.
  Proof.
    intros xs. destruct (nat_list_max xs) as [x H]. destruct x. exists (Ptcp (n.+1)).
    intros J. rewrite /ptcp_le in H. apply H in J. lia. 
  Qed. 
Definition fresh (S : ptcps) :=
    match atom_fresh_for_list S with
      (exist x _ ) => x
    end.



Definition project_pred  (g : gType):=  if g is GBranch a gs then let S := ptcps_of_g g in
                                                                                all_eq_F (projmap (fresh S |` (S  `\` a))) gs (nth GEnd gs 0) else true.


Lemma traverse_split : forall g (P0 P1 : pred gType), traverse_pred (predI P0 P1) g = (traverse_pred P0 g) && (traverse_pred P1 g).
Proof. 
elim;rewrite /=;intros;try done. lia. lia. rewrite H. lia. rewrite H. lia. 
destruct ( P0 (GBranch a l));rewrite /=; try done. destruct ( P1 (GBranch a l));rewrite //=. 
rewrite -all_predI. apply/eq_in_all. move=> x Hin. simpl. eauto. lia. 
Qed.


(*Hint Resolve traverse_pred_pred.*)
End Pred.



Ltac uf s := rewrite /s -/s.

Definition rec_pred : pred gType := foldr predI predT ([::action_pred;project_pred;size_pred]).



Notation props := (predI (predI action_pred size_pred) project_pred).




Definition locked_pred := locked traverse_pred.


Lemma locked_split
     : forall (g : gType) (P0 P1 : pred gType), locked_pred (predI P0 P1) g = locked_pred P0 g && locked_pred P1 g.
Proof. intros. unlock locked_pred. apply traverse_split. Qed.



Check locked_pred.

Class CHint (b : Prop) : Prop:= { chint : (b : Prop) }.
Lemma locked_pred_hint : forall P g, locked_pred P g -> CHint (locked_pred P g).
intros. constructor. done. Qed.

Lemma in_hint : forall (A : eqType) (a : A) (l : seq A), a \in l -> CHint (a \in l).
intros. constructor. done. Qed.

Lemma lt_hint : forall n0 n1, n0 < n1 -> CHint (n0 < n1).
intros. constructor. done. Qed.

Lemma size_eq_hint : forall (A : Type) (l0 l1 : seq A), size l0 = size l1 -> CHint (size l0 = size l1).
intros. constructor. done. Qed.

Hint Resolve locked_pred_hint in_hint lt_hint size_eq_hint: typeclass_instances.


Class CGoal (b : Prop) : Prop := { cgoal : (b : Prop) }.

Generalizable Variables D E.

Lemma cgoal_imp : forall (P0 P1 : Prop), (P0 -> P1)  -> CGoal P0 -> CGoal P1.
Proof. intros. destruct H0. constructor. auto. Qed.

Lemma chint_imp : forall (P0 P1 : Prop), (P0 -> P1)  -> CHint P0 -> CGoal P1.
Proof. intros. destruct H0. constructor. auto. Qed.

Instance CGoal_Hint `{H : CHint D} : CGoal D. destruct H. constructor. done. Defined.


Instance imp_locked_pred_rec P g n : CHint (locked_pred P (GRec n g)) -> CGoal (locked_pred P g).
apply chint_imp. unlock locked_pred. rewrite /=. lia. Defined.


Instance imp_locked_pred_msg P a u g : CHint (locked_pred P (GMsg a u g)) -> CGoal (locked_pred P g).
apply chint_imp. unlock locked_pred. rewrite /=. lia. Defined.


Instance imp_locked_pred_branch P a gs : CHint (locked_pred P (GBranch a gs)) -> CGoal (all (locked_pred P) gs).
apply chint_imp. unlock locked_pred. simpl. lia. Defined.

Instance imp_locked_pred_branch_nth P gs i : CGoal (all (locked_pred P) gs) -> CGoal (i < size gs) -> CGoal (locked_pred P (nth GEnd gs i)).
case. move => H. apply cgoal_imp. move => H2. move : H. unlock locked_pred. intros. apply (allP H). apply/mem_nth.  done. Defined.

Instance imp_mem_nth (A : eqType) (gs : seq A) n d : CGoal (n < size gs) -> CGoal (nth d gs n \in gs).
apply cgoal_imp. eauto.  Defined.

Instance imp_size_pred gs a: CGoal (size_pred (GBranch a gs)) -> CGoal (0 < size gs).
apply cgoal_imp. eauto. Defined.

Instance imp_rec_size g : CGoal (locked_pred size_pred g) -> CGoal (size_pred g).
apply cgoal_imp.  unlock locked_pred.  elim : g;rewrite /=;try done;lia. Defined.

Instance imp_rec_project g : CGoal (locked_pred project_pred g) -> CGoal (project_pred g).
apply cgoal_imp.  unlock locked_pred. elim : g;rewrite /=;try done;lia. Defined.

Instance imp_rec_action g : CGoal (locked_pred action_pred g) -> CGoal (action_pred g).
apply cgoal_imp.
 unlock locked_pred. elim : g;rewrite /=;try done;lia. Defined.

Instance imp_rec_pred g : CGoal (locked_pred rec_pred g) -> CGoal (rec_pred g).
apply cgoal_imp.
 unlock locked_pred. elim : g;rewrite /=;try done;lia. Defined.

Instance imp_locked_rec_size g : CGoal (locked_pred rec_pred g) -> CGoal (locked_pred size_pred g).
apply cgoal_imp. unlock locked_pred.  rewrite !traverse_split /=. lia. Defined.

Instance imp_locked_rec_action g : CGoal (locked_pred rec_pred g)  -> CGoal (locked_pred action_pred g).
apply cgoal_imp.  unlock locked_pred.  rewrite traverse_split. lia. Defined.

Instance imp_locked_rec_project g : CGoal (locked_pred rec_pred g)  -> CGoal (locked_pred project_pred g).
apply cgoal_imp.  unlock locked_pred.  rewrite !traverse_split. lia. Defined.



Ltac norm_eqs := repeat (match goal with 
                   | [ H : (_ == _) |- _ ] => move : H => /eqP=>H
                   | [ H : (_ == _) = true |- _ ] => move : H => /eqP=>H
                   | [ H : (_ == _) = false |- _ ] => move : H => /negbT=>H

                  end);subst;repeat (match goal with 
                   | [ H : is_true (?a != ?a_) |- _ ] => rewrite eqxx in H;done 

                  end).

Lemma notin_big : forall p gs i, p \notin \bigcup_(j <- gs) (ptcps_of_g j) -> i < size gs -> p \notin ptcps_of_g (nth GEnd gs i).
Proof.
intros. apply/negP=>HH. apply (negP H). apply/bigfcupP. exists (nth GEnd gs i). rewrite mem_nth //=. apply HH. Qed.

Hint Resolve notin_big.

Ltac brute :=  typeclasses eauto with typeclass_instances.

Lemma CGoal_imp2 : forall P, CGoal P -> P. intros. destruct H. done. Defined.


Ltac to_goal := apply Build_CHint; apply CGoal_imp2.

(*Ltac cc := to_goal; solve [ eauto with typeclass_instances | apply : CGoal_Imp]. (*.*)
(*Ltac ccg := try (apply  CGoal_imp2 ) ;move; cc. *)*)

Lemma lock_traverse  : traverse_pred = locked_pred.
Proof. unlock locked_pred. done. Qed.
Ltac ul := unlock locked_pred.
Ltac usl := ul; rewrite /= lock_traverse.

Ltac cc_fail := to_goal; solve [ typeclasses eauto with typeclass_instances ]. (*.*)
Ltac cc := (try solve [cc_fail | usl;cc_fail | done]);try usl. 

(*Ltac ccg := try (apply  CGoal_imp2 ) ;move; cc. *)



Notation "{hint P }" := (@CHint  P)(format "{hint  P }").
Notation "{goal P }" := (@CGoal  P)(format "{goal  P }").



Lemma size_pred_msg : forall a u g, (locked_pred action_pred) (GMsg a u g) -> ptcp_from a != ptcp_to a.
Proof. move => a u g.  ul.  rewrite /=. eauto. Qed.

Instance unsafe_locked_traverseP  P g : CHint (locked_pred P g) -> CGoal (locked_pred P g).
Proof. ul. apply chint_imp.  unlock locked_pred. done.  Defined.

Instance imp_action a u g : CGoal (locked_pred action_pred (GMsg a u g)) -> CGoal (ptcp_from a != ptcp_to a).
Proof. ul. apply cgoal_imp. unlock locked_pred. rewrite /=. lia. Defined.


(*Maybe bad rule*)
Instance goalType_branch a gs : CGoal (locked_pred action_pred (GBranch a gs)) -> CGoal (ptcp_from a != ptcp_to a).
Proof. ul. apply cgoal_imp.  unlock locked_pred. rewrite /=. lia. Defined.

Instance imp_locked_pred_in_branch P a gs x :CHint (locked_pred P (GBranch a gs)) ->  CGoal (x \in gs)  -> CGoal (locked_pred P x).
ul. case. move=> H. apply cgoal_imp.   move : H. unlock locked_pred. simpl. intros. destruct (andP H). apply (allP H2). done. 
Defined.

(*Lemma CGoal_less : forall P n0 n1, CGoal n0 P -> CGoal n1 P. intros. destruct H. constructor. done. Defined.
Hint Resolve CGoal_less : typeclass_instances.*)

Lemma project_tw0 : forall g p0 p1, locked_pred rec_pred g -> p0 \notin (ptcps_of_g g) ->  p1 \notin (ptcps_of_g g)  -> project g p0 = project g p1.  
Proof.
elim; rewrite /=;intros;try done. erewrite H;eauto. cc.
rewrite !inE in H1,H2. split_and. 
rewrite (negbTE H5) (negbTE H2) (negbTE H1) (negbTE H7). apply H;cc.  
move : H1 H2. rewrite !inE. split_and.
rewrite (negbTE H5) (negbTE H2) (negbTE H1) (negbTE H7). rewrite !match_n.  apply H;cc.
rewrite big_map in H6. 
apply/notin_big. done. cc. 
rewrite big_map in H4. 
apply/notin_big. done. cc. 
Qed.


(*Lemma traverse_subpred : forall g (p0 p1 : pred gType), subpred p0 p1 -> locked_pred p0 g -> locked_pred p1 g.
Proof. elim;rewrite /=;try done;intros. all : try (rewrite H0 //=; lia). 
rewrite H //=. eauto. rewrite H //=. lia.  rewrite H0 //=. eauto. lia. rewrite H0 //=. eauto. lia. 
rewrite H0 //=. apply/allP=>k Hin.  apply : H;eauto.  lia. 
Qed.

Lemma rec_pred_project : subpred rec_pred project_pred. 
Proof. move=>k. rewrite /rec_pred /=. lia. Qed.

Lemma rec_pred_size : subpred rec_pred size_pred. 
Proof. move=>k. rewrite /rec_pred /=. lia. Qed.

Hint Resolve traverse_subpred rec_pred_project rec_pred_size.*)


Lemma project_predP_aux : forall a gs p i, locked_pred rec_pred (GBranch a gs) ->
p \notin a -> i < size gs  -> (project (nth GEnd gs 0) p) = project (nth GEnd gs i) p.
Proof. 
intros. have : project_pred (GBranch a gs) by cc.   rewrite /= /all_eq_F. move/allP=>Hall. have : (nth GEnd gs i) \in gs by eauto.
move/Hall/eqP/fmapP=>HH0. specialize HH0 with p. move :HH0.  rewrite !mapf_if. rifliad.  case. move=><-. done. move=> _. 
move : H2. move/negbT. rewrite inE negb_or. move/andP=>[].  rewrite inE big_map. intros. move : a0.  rewrite /fresh. destruct (atom_fresh_for_list (a `|` \bigcup_(j <- gs) j)) eqn:Heqn.  rewrite Heqn. 


have : (nth GEnd gs i) \in gs by eauto. move/Hall/eqP/fmapP=>HH0. specialize HH0 with x. move :HH0.  rewrite !mapf_if. rifliad.
case. intros.

have : p \notin ( \bigcup_(j <- gs) j). move : b H0. rewrite !inE. move/orP=>[]. 
move/orP=>[]. move/eqP=>->. rewrite eqxx. done. move/eqP=>->. rewrite eqxx. split_and.  by move/andP=>[] -> ->. 
move => HH0.

clear Heqn. move : n.  move/negP. rewrite !inE. split_and. 
erewrite project_tw0. erewrite (@project_tw0 (nth GEnd gs i)). 
apply : H3.
cc. eapply notin_big in HH0. eauto. done.  apply/notin_big. done. done. cc. apply/notin_big. done. cc. apply/notin_big.  
done. cc. 
move : H2. by rewrite big_map !inE  /fresh Heqn eqxx/=. 
Qed.

(*Lemma traverse_nth : forall a gs i P, locked_pred P (GBranch a gs) -> i < size gs -> locked_pred P (nth GEnd gs i).
Proof. intros. simpl in H. eauto.  Qed.

Lemma traverse_nth0 : forall a gs P, subpred P size_pred  -> locked_pred P (GBranch a gs) -> locked_pred P (nth GEnd gs 0).
Proof.
intros. simpl in H0. destruct (andP H0). apply H in H1. simpl in H1. eauto. Qed.

Hint Resolve traverse_nth traverse_nth0.*)


Lemma project_predP : forall a gs p i j, locked_pred rec_pred (GBranch a gs) ->
 p \notin a -> i < size gs -> j < size gs -> (project (nth GEnd gs i) p) = project (nth GEnd gs j) p.
Proof. intros. erewrite <- project_predP_aux;eauto.   apply : project_predP_aux;eauto. 
Qed.

Lemma is_leafP : forall e, is_leaf e -> e = EEnd \/ exists n, e = EVar n. 
Proof. rewrite /is_leaf.  intros. destruct e;eauto; try done. Qed.

Lemma isnt_leafP : forall e, ~ is_leaf e -> e <> EEnd /\ forall  n, e <> EVar n. 
Proof. rewrite /is_leaf.  intros. destruct e;eauto; try done. Qed.


(*Lemma ptcps_not_leaves : forall (g : gType) p, locked_pred (predI project_pred size_pred) g -> p \in ptcps_of_g g -> ~~ is_leaf (project g p).  
Proof. elim;try solve [rewrite /=;try done];intros. 
rewrite /=. apply H in H1. rewrite (negbTE H1). done.  done. 
rewrite /=. move : H1. rewrite /= !inE. repeat  move/orP=>[].
move/eqP=>->. rewrite eqxx. done. 
move/eqP=>->. rewrite eqxx. rifliad. move => HH.  
rifliad.
apply H. simpl in H0. done. done. 
simpl in H. move : H1.
rewrite /= !inE. destruct (p == ptcp_from a) eqn:Heqn0;rewrite /=;rifliad.  rewrite H1 /= big_map.
move/bigfcupP=>[] g /andP => [] [] /[dup]. move=>Hin'.  move/nthP=>Hnth _. specialize Hnth with GEnd. destruct Hnth. 
rewrite -H3 match_n. rewrite -H3 in Hin'. intros.  erewrite project_predP. apply : H. eauto.
simpl in H0. destruct (andP H0). eauto. eauto. clear Heqn0.  rewrite traverse_split in H0. destruct (andP H0). eauto. 
rewrite traverse_split in H0. lia. by rewrite !inE Heqn0 H1. rewrite traverse_split in H0. destruct (andP H0). simpl in H5. lia. done. 
Qed.*)
 
(*Lemma project_ptcps : forall a gs, project_pred (GBranch a gs) -> size_pred (GBranch a gs)  -> forall p i j, p \notin a -> i < size gs -> j < size gs -> ptcps_of_g (nth GEnd gs i) = ptcps_of_g (nth GEnd gs j).
Proof. intros. erewrite <- project_predP_aux. eauto.   apply : project_predP_aux;eauto. Qed.
*)


Lemma match_n2
     : forall (A B : Type) (gs : seq A) (a : A) (f : A -> B),
       match gs with
       | [::] => f a
       | g' :: _ => f g'
       end = f (nth a gs 0).
Proof. intros. destruct gs. done. done. Qed.


(*Lemma propsC : forall g, props g = (locked_pred action_pred g) && (locked_pred size_pred g) && (locked_pred project_pred g).
Proof. intros. rewrite !traverse_split. done. Qed. 

Lemma props_action : forall g, props g -> locked_pred action_pred g.
Proof.
intros. rewrite propsC in H. destruct (andP H). destruct (andP H0). done.
Qed.

Lemma props_size : forall g, props g -> locked_pred size_pred g.
Proof.
intros. rewrite propsC in H. destruct (andP H). destruct (andP H0). done.
Qed.

Lemma props_project : forall g, props g -> locked_pred project_pred g.
Proof.
intros. rewrite propsC in H. destruct (andP H). destruct (andP H0). done.
Qed.

Hint Resolve  props_action props_size props_project.*)

(*Lemma props_msg : forall g u a, props (GMsg a u g) -> props g.
Proof. intros. move : H. rewrite !propsC /=. lia. Qed.

Lemma props_branch : forall gs a n, props (GBranch a gs) -> n < size gs -> props (nth GEnd gs n).
Proof. intros.  move : H. simpl. move/andP=>[] H Hall. rewrite !propsC /=. 
move : Hall. move/allP=>HH0. move : (@mem_nth _ GEnd gs n)=>HH1. apply HH0 in HH1. 
move : HH1. rewrite propsC. done. done. 
Qed.

Lemma props_rec : forall g, props (GRec g) -> props g.
Proof. intros. move : H. rewrite !propsC /=. lia. Qed.*)

Lemma notin_label : forall p a, p \notin a = (p != (ptcp_from a)) && (p != (ptcp_to a)).
Proof.
intros. destruct a. rewrite !inE. done. Qed.

Lemma in_label : forall p a, p \in a = (p == (ptcp_from a)) || (p == (ptcp_to a)).
Proof.
intros. destruct a. by  rewrite !inE /=. 
Qed.

Lemma nth_project : forall gs p i, nth EEnd (map (fun g => project g p) gs) i = project (nth GEnd gs i) p.
Proof.
elim;rewrite /=;try done; intros. rewrite !nth_nil /=. done.
rewrite /=. destruct i;rewrite /=. done. done.
Qed.





(*



Lemma bound_project : forall g p i, bound_i i g -> locked_pred size_pred g  -> (bound_i_e i (project g p)).
Proof. elim;rewrite /=;try done;intros.
rifliad. rewrite /= H //=. rifliad; rewrite /=; auto. 
rifliad; rewrite /=. rewrite all_map.   apply/allP=> x /nthP=>HH. simpl. apply : H. specialize HH with GEnd. destruct HH.
rewrite -H3 mem_nth //=. 
 specialize HH with GEnd. destruct HH. 
rewrite -H3. apply (allP H0).  rewrite mem_nth //=. destruct (andP H1). apply (allP H3). edestruct HH. rewrite -H5 mem_nth //=. 

rewrite all_map. apply/allP=>x Hin. simpl. apply : H. done. apply (allP H0). done. destruct (andP H1). apply (allP H4). done. 
rewrite match_n. apply : H. rewrite mem_nth //=. lia. apply (allP H0). rewrite mem_nth //=.  lia. destruct (andP H1). apply (allP H4). rewrite mem_nth //=.
Grab Existential Variables. eauto.
Qed.

Lemma project_end_bound : forall g p, bound_i 0 g -> locked_pred size_pred g  -> p \notin (ptcps_of_g g) -> project g p = EEnd.
Proof.
intros. edestruct (project_end); eauto. destruct H2. eapply bound_project in H;eauto. erewrite H2 in H. done. Qed.

*)


(*Ltac ssubst := (repeat apply_eqs);subst.*)

(*
(*This definition cannot handle the generalized harmony lemma. Projection will not be defined on S for the reduced g' if g' `<` S *)
Definition projectable1 := forall g, props g -> forall p, p \in g -> exists e, proj g p e.

(*Fixed in this definition, but the result can easily be pushed to be more general, is that necessary? 
*)
Definition projectable2 := forall g, props S g -> forall p, p \in S -> exists e, proj g p e.

Definition projectable3 := forall g, props g -> forall p, exists e, proj g p e.
*)

Lemma nat_fact : forall n, n - (n - n) = n. lia. Qed.

Lemma forallzipP1 : forall (A B : eqType) (P : A * B -> Prop) a b l l',  size l = size l' -> (forall x0, x0 < size l -> P (nth a l x0,nth b l' x0)) -> 
Forall P (zip l l').
Proof.
intros. apply/Forall_forall. intros. move : H1. move/nthP=>HH. specialize HH with (a,b). 
destruct HH. rewrite -H2. rewrite nth_zip //=. apply H0. move : H1. by rewrite size_zip minnE H nat_fact. 
Qed.


Lemma forallzipP2 : forall (A B : eqType) (P : A * B -> Prop) a b l l', Forall P (zip l l') -> size l = size l' -> (forall x0, x0 < size l -> P (nth a l x0,nth b l' x0)).
Proof.
move => A B P a b. elim. case. done. done. move => a0 l IH. case. done. move => a1 l0 H Hsize. intros. simpl in H0. destruct x0. simpl. simpl in H. inversion H. done. simpl. apply IH. simpl in H. inversion H. done. simpl in Hsize. lia. lia. 
Qed.

Lemma forallzipP : forall (A B : eqType) (P : A * B -> Prop) a b l l',  size l = size l' -> (forall x0, x0 < size l -> P (nth a l x0,nth b l' x0)) <-> 
Forall P (zip l l').
Proof.
intros.  split. apply forallzipP1. done. move/forallzipP2=>HH. apply HH. done. 
Qed.

Lemma forallP : forall (A : eqType) (P : A -> Prop) a l,(forall x0, x0 < size l -> P (nth a l x0)) -> 
Forall P l.
Proof. intros.
apply/Forall_forall. intros. move : H0 => /nthP H3.  specialize H3 with a. destruct H3. rewrite -H1. auto.
Qed.



Hint Resolve Build_CHint.



Lemma projP : forall g p, locked_pred rec_pred g -> proj g p (project g p).
Proof. 
elim;intros;rewrite /=;try done. rifliad. apply cp_rec0. rewrite -(eqP H1). apply H. cc. apply cp_rec1. apply H. cc. apply negbT in H1.  apply/eqP. done. done. apply cp_rec2. apply H. cc. rewrite H2. done. 
rifliad;eauto. 
norm_eqs. 
apply cp_msg_from;eauto. apply : H. cc.
norm_eqs.  apply cp_msg_to;eauto.  apply : H. cc.
norm_eqs.  apply cp_msg_other. by  rewrite !inE H2 H1. apply : H. cc.
rifliad. 
norm_eqs. apply cp_branch_from. rewrite size_map //=.
apply/forallzipP. by rewrite size_map.
intros. rewrite /=. 
erewrite nth_project. apply : H. eauto. cc.
norm_eqs. apply cp_branch_to. rewrite size_map //=.
apply/forallzipP. by rewrite size_map.
intros. rewrite /=. 
erewrite nth_project. apply : H. eauto.   cc. 
rewrite match_n  /=. apply cp_branch_other. rewrite !inE. norm_eqs. by  rewrite H2 H1. 

apply/forallP. intros. 
have : project (nth GEnd l 0) p = project (nth GEnd l x0) p.

simpl in H. apply : project_predP_aux.  cc. by rewrite !inE H1 H2. done. 
move=>->. apply : H;cc. 
Qed.


(*Instance locked_pred_cons a a0 l : {hint locked_pred rec_pred (GBranch a (a0 :: l))} -> {goal locked_pred rec_pred (GBranch a l)}.
Proof. apply chint_imp. ul. rewrite /=. split_and. move : H0.  rewrite /rec_pred /=. split_and. 2 : { done. move : H0. rewrite rec_predrewrite /rec_pred /=. split_and.  rewrite !locked_split /=; ul;rewrite /=.  split_and. rewrite split_locked_pred. ul. rewrrewrite traverse_pred_split.*)



Lemma in_foldr : forall l n,  n \in foldr (fun g' : gType => cat (fv_g g')) nil l ->  exists g, g \in l /\ n \in (fv_g g).
Proof. elim;try done;move => l n H n'.
rewrite /= mem_cat. move/orP=>[]. intros. exists l. by rewrite !inE /= a. 
move/H. move=>[] x [].  intros. exists x. rewrite !inE a b. lia. Qed.

Lemma in_foldr2 : forall l n p g, g \in l -> n \in (fv (project  g p)) ->  n \in foldr (fun g' : gType => cat (fv (project g' p))) nil l.
Proof. elim;try done;intros. move : H0.
rewrite !inE. move/orP=>[]. move/eqP. intros. subst. simpl. rewrite mem_cat H1. done. intros.  simpl. rewrite mem_cat. apply/orP. right. apply : H. eauto. done. 
Qed.

Lemma my_in_cons : forall (A :eqType) (a : A) l, a \in (a::l).
Proof. intros. rewrite !inE. done. Qed.

Lemma my_in_cons2 : forall (A :eqType) (a a0 : A) l, a \in l -> a \in (a0::l).
Proof. intros. rewrite !inE H. lia. Qed.

Hint Resolve my_in_cons my_in_cons2.

Lemma big_cup_in : forall (A : eqType) (B: choiceType) n (l : seq A) (f0 f1 : A -> {fset B}), (forall x n, x \in l -> n \in (f0 x) -> n \in (f1 x)) -> n \in \bigcup_(j <- l) (f0 j) ->  n \in \bigcup_(j <- l) (f1 j).
Proof. move => A B n. elim. move => f0 f1.  rewrite big_nil. done. intros. move : H1. rewrite !big_cons !inE. move/orP=>[].  intros. rewrite H0 //=. intros. erewrite H. lia. intros. apply H0. eauto. eauto. apply b. 
Qed.

Lemma foldr_exists : forall (A : eqType) (B : choiceType) (l : seq A) (f0 : A -> {fset B}) p, p \in \bigcup_(j <- l) (f0 j) = has (fun x => p \in f0 x) l. 
Proof. 
move => A B. elim. move => f0 p. rewrite big_nil. done. intros. simpl. rewrite big_cons !inE. destruct ( (p \in f0 a) ) eqn:Heqn;rewrite /=. 
done.
apply H.
Qed.


Lemma fv_project_in : forall g p n, locked_pred rec_pred g ->  (n \in (fv_g g)) -> (n  \in (fv (project g p))).
Proof.
elim;rewrite //=;intros. move : H1. rewrite !inE.  split_and. apply (H p) in H3;last cc.
- rifliad. rewrite (eqP H1) in H3. simpl in H3. rewrite !inE in H3. lia. 
  simpl. rewrite !inE.  split_and. 
- apply (H p) in H1;last cc. rifliad.
- rifliad. simpl. have : all (locked_pred rec_pred) l by cc. clear H0 H2. move : H1. rewrite !big_map. move => HH. move/allP => Hall. apply : big_cup_in.  intros. apply : H. done. apply Hall. done. eauto. done.
  rewrite /= !big_map. 
  apply : big_cup_in.  intros. apply : H. done. cc. eauto. rewrite big_map in H1. done. 
- rewrite match_n. apply H. cc. cc. move : H1. rewrite big_map foldr_exists. move/hasP=>[] x. intros. 
  intros.  move : p0. move/nthP=>Hnth. specialize Hnth with GEnd. destruct Hnth.

  apply : fv_rproject_in. 
  erewrite project_predP. apply : H. apply/mem_nth. apply : H1. cc. rewrite H4.  done. cc.   all:cc. instantiate (1 := fresh a). rewrite /fresh. destruct (atom_fresh_for_list a). apply/negP.  move => HH. apply n0. destruct a. move : HH. rewrite !inE.  done. 
Qed.

Lemma fv_project_eq : forall g p n, locked_pred rec_pred g ->  (n \in fv_g g) = (n \in fv (project g p)).
Proof. intros. destruct ( (n \in fv_g g)) eqn:Heqn. rewrite fv_project_in //=.
destruct ((n \in fv (project g p))) eqn:Heqn2. erewrite fv_rproject_in in Heqn. done. eauto. done. 
Qed.


(*Lemma Forall_mono : forall (A : Type) (l0 : seq A) (r0 r1 : A  -> Prop),  Forall r0 l0  -> (forall x, r0 x -> r1 x) -> Forall r1 l0.
Proof.
intros. induction H;auto.
Qed.

Lemma Forall_mono_In : forall (A : Type) (l0 : seq A) (r0 r1 : A  -> Prop),  Forall r0 l0  -> (forall x, In x l0 -> r0 x -> r1 x) -> Forall r1 l0.
Proof.
intros. induction H;auto. constructor. simpl in H0. apply H0. auto. done. simpl in H0.  auto.
Qed.

Lemma Forall2_mono : forall (A B : Type) (l0 : seq A) (l1 : seq B) (r0 r1 : A -> B -> Prop),  Forall2 r0 l0 l1  -> (forall x y, r0 x y -> r1 x y) -> Forall2 r1 l0 l1.
Proof.
intros. induction H;auto.
Qed.

Hint Resolve Forall_mono Forall2_mono.*)





(*Lemma in_dom : forall (d : env) p e, d.[? p] = Some e -> p \in d.
Proof.
intros.
destruct (p \in d) eqn:Heqn. done. rewrite -fndSome in Heqn. rewrite /isSome in Heqn. rewrite H in Heqn. done.
Qed.*)

(*Lemma all_proj_spec : forall g d p e, allproj g d -> d.[? p] = Some e <-> proj g p e /\ p \in ptcps_of_g g. 
Proof. 
move => g d p e H. elim : H e. 
- intros. split;intros. 
 * have : p \in d0. move : H0.  apply : in_dom. move/H. rewrite H0. case. move=>->. intros. . Search _ (_.[? _]). exists p. rewrite H //=.*)



Unset Elimination Schemes. 
Inductive Estep : endpoint ->  (dir * ch * (value + nat))  -> endpoint -> Prop :=
| estep_msg d c v e0  : Estep (EMsg d c v e0) (d,c, inl v) e0
| estep_msg_async d vn c c' v e0 e0'  : Estep e0 (d,c,vn) e0' -> c <> c' -> 
                                        Estep (EMsg Sd c' v e0) (d,c,vn) (EMsg Sd c' v e0')
| estep_branch n es d c   : n < size es -> Estep (EBranch d c es) (d,c, inr n) (nth EEnd es n)
| estep_branch_async es0 es1 vn d c c'  : size es0 = size es1 -> Forall (fun p =>  Estep p.1 (Sd,c,vn) p.2) (zip es0 es1) -> c <> c' -> 
                                          Estep (EBranch d c' es0) (Sd,c,vn) (EBranch d c' es1)
| estep_rec e l e' n: Estep e[e (ERec n e)//n] l e' -> Estep (ERec n e) l e'.
Set Elimination Schemes.
Hint Constructors Estep.

Lemma Estep_ind
     : forall P : endpoint -> dir * ch * (value + nat) -> endpoint -> Prop,
       (forall (d : dir) (c : ch) (v : value) (e0 : endpoint), P (EMsg d c v e0) (d, c, inl v) e0) ->
       (forall (d : dir) (vn : value + nat) (c c' : ch) (v : value) (e0 e0' : endpoint),
        Estep e0 (d, c, vn) e0' -> P e0 (d, c, vn) e0' -> c <> c' -> P (EMsg Sd c' v e0) (d, c, vn) (EMsg Sd c' v e0')) ->
       (forall (n : nat) (es : seq endpoint) (d : dir) (c : ch), n < size es -> P (EBranch d c es) (d, c, inr n) (nth EEnd es n)) ->
       (forall (es0 es1 : seq endpoint) (vn : value + nat) (d : dir) (c c' : ch),
        size es0 = size es1 ->
        Forall (fun p : endpoint * endpoint => Estep p.1 (Sd, c, vn) p.2) (zip es0 es1) ->
        Forall (fun p : endpoint * endpoint => P p.1 (Sd, c, vn) p.2) (zip es0 es1) ->
        c <> c' -> P (EBranch d c' es0) (Sd, c, vn) (EBranch d c' es1)) ->
       (forall (e : endpoint) (l : dir * ch * (value + nat)) (e' : endpoint) (n : nat),
        Estep (e)[e ERec n e // n] l e' -> P (e)[e ERec n e // n] l e' -> P (ERec n e) l e') ->
       forall (e : endpoint) (p : dir * ch * (value + nat)) (e0 : endpoint), Estep e p e0 -> P e p e0.
Proof.
intros. move : e p e0 H4. fix IH 4;intros. destruct H4.
- apply H;auto.
- apply H0;auto.
- apply H1;auto.
- apply H2;auto. elim : H5;auto. 
- apply H3;auto. 
Qed.



Inductive EnvStep : env -> label -> env -> Prop := 
| envstep_rule (Δ : env) e0 e1 e0' e1' l : Estep e0 (Sd,action_ch l.1,l.2) e0' ->  Estep e1 (Rd,action_ch l.1,l.2) e1' ->  
                           EnvStep Δ.[ptcp_from l.1 <- e0].[ptcp_to l.1 <- e1] l  Δ.[ptcp_from l.1 <- e0'].[ptcp_to l.1 <- e1'].
Hint Constructors EnvStep.




(*Fixpoint non_zero (g : gType) := if g is GBranch a gs then (0 < (size gs)) && (all non_zero gs) else true.*)

Check in_fnd. 
(*Definition Coherent g := Linear g /\ (exists Δ, co_allproj g Δ) /\ non_refl g.*)


Lemma map_same : forall (d : env) p e, d.[? p] = Some e ->  d.[ p <- e] = d.
Proof.
intros. move : H. intros. apply/fmapP. intros. rewrite fnd_set. rifliad. by rewrite (eqP H0) H. 
Qed.



Lemma rem2_map : forall (d : env) p1 p2 e1 e2, d.[p1 <- e1].[p2 <- e2] = d.[\  p1 |` [fset p1]].[p1 <- e1].[p2 <- e2]. 
Proof.
intros. rewrite !setf_rem /=.
have : (p2 |` (p1 |` domf d)) `\` ([fset p1; p1] `\ p1 `\ p2) = (p2 |` (p1 |` domf d)).
apply/eqP. apply/fset_eqP.  intro x. rewrite !inE /=  -!eqbF_neg. 
destruct (x == p2) eqn:Heqn. by rewrite /=. rewrite /=. destruct (x == p1). by rewrite /=. rewrite /=. done.
move=>->. have : p2 |` (p1 |` domf d) = domf ((d.[p1 <- e1]).[p2 <- e2]).  apply/eqP/fset_eqP. move => x. by rewrite /=.  
move => ->. by rewrite restrictfT. 
Qed.



Lemma neg_false : forall (A : eqType) (a b : A), a != b <-> a == b = false. 
Proof.
intros. case : (eqVneq a b);rewrite /=;intros;split;done.
Qed.


Lemma EnvStepdom : forall (d0 d1 : env) l, EnvStep d0 l d1 -> domf d0 = domf d1.
Proof.
intros.
inversion H. subst. rewrite /=.  done.
Qed.


(*Coercion action_to_ch (a : action) : ch := let: Action _ _ c := a in c.

Lemma traverse_top_msg : forall a u g P, (locked_pred P) (GMsg a u g) -> P (GMsg a u g). 
Proof. rewrite /=. intros. eauto. Qed.

Lemma traverse_next_msg : forall a u g P, (locked_pred P) (GMsg a u g) -> locked_pred P g. 
Proof. rewrite /=;intros;eauto. Qed.



Hint Resolve traverse_top_msg traverse_next_msg size_pred_msg.*)

(*Existing Class subgType.*)


Lemma traverse_action_pred_unf : forall g0 g1 i, locked_pred action_pred g0 -> locked_pred action_pred g1 -> locked_pred action_pred (substitution i g0 g1).
Proof. 
elim;intros;rewrite /=;try done. 
- rifliad. cc. 
- rifliad. cc.  usl.  apply H;cc. 
- usl.  split_and; cc. apply : H; cc. 
- usl. split_and. cc. cc. rewrite all_map. apply/allP=> ll Hin /=. apply : H;cc. 
Qed.

Instance traverse_action_pred_unfG : forall g0 g1 i, {goal locked_pred action_pred g0} -> {goal locked_pred action_pred g1} -> {goal locked_pred action_pred (substitution i g0 g1)}.
Proof. intros. constructor. apply traverse_action_pred_unf;cc. Qed.


Lemma traverse_size_pred_unf : forall g0 g1 i, locked_pred size_pred g0 -> locked_pred size_pred g1 -> locked_pred size_pred (substitution i g0 g1).
Proof. 
elim;intros;rewrite /=; simpl in *;try done;auto.
- rifliad. cc. 
- rifliad. cc. apply H. cc. cc. 
- cc. apply H. cc. cc. 
- cc. split_and. rewrite size_map. cc. 
- rewrite all_map. apply/allP=> ll Hin /=. apply : H;cc. 
Qed.

Instance traverse_size_pred_unfG : forall g0 g1 i, {goal locked_pred size_pred g0} -> {goal locked_pred size_pred g1} -> {goal locked_pred size_pred (substitution i g0 g1)}.
Proof. intros. constructor. apply traverse_size_pred_unf;cc. Defined.



Lemma mapf3 : forall (A : choiceType) (B : Type) (S : {fset A}) (F : A -> B) (k : A), k \in S -> [fmap x : S => F (val x)] =  [fmap x : S => F (val x)].[k <- F k].  
Proof.
intros. apply/fmapP=>k0. rewrite /= /fnd.  case : insubP; intros; rewrite  /=. rewrite insubT. move : i. rewrite inE. move=>->. lia.  
intros. rewrite /=.  f_equal. rewrite !ffunE /=. rifliad. rewrite /=. simpl in *. rewrite e.  rewrite (eqP H0). done. rewrite insubT /= !ffunE. f_equal. f_equal. move : e i=><-. intros. 
rewrite fsetsubE. done. 
case : insubP. intros. simpl in *. have : k = k0.  move : i0 H. rewrite !inE. move/orP. case. by move/eqP. intros. rewrite b in i. done. 
intros. subst. rewrite -x in i. rewrite H in i.  done. 
intros. rewrite /=. done.
Qed.

Lemma mapf_or : forall (A : choiceType) (B : Type) (S0 S1 : {fset A}) (F : A -> B), [fmap x : (S0 `|` S1) => F (val x)] =  [fmap x : S0 => F (val x)] + [fmap x : S1 => F (val x)].
Proof. intros. apply/fmapP=>k. Search _ ((_ + _).[? _]). rewrite fnd_cat. rewrite /domf. rifliad.  rewrite !mapf. done. done. rewrite inE H. lia. destruct (k \in S0) eqn:Heqn.  rewrite !mapf. done. done. rewrite inE H. lia. rewrite !mapf2. done. lia. rewrite inE. lia.
Qed.



Lemma all_eq_map : forall (A B C: eqType) (l : seq A) a (F : B -> C) (F1 : A -> B), all_eq_F (F \o F1) l a -> all_eq_F F (map F1 l) (F1 a).  
Proof. move => A B C. elim. done. intros. move : H0 H. rewrite /all_eq_F all_map /=. move/andP=>[];intros. rewrite (eqP a1) eqxx /=. rewrite -all_map. apply :H. rewrite -(eqP a1).  done.
Qed.


Definition try_fnd (d : env) (p : ptcp) := if d.[? p] is Some e then e else EEnd.



Definition map_subst (i : nat) (d : env) g := [fmap x : (domf d) => subst_e i (try_fnd d (val x)) (project g (val x))]. 




Lemma nth_subst : forall l g0 i, nth GEnd (map (fun g0' => substitution i g0' g0) l) 0 = substitution i (nth GEnd l 0) g0.
Proof.
elim. intros; rewrite //=. 
intros. rewrite /=. done.
Qed.





(*
Lemma is_leaf_subst_e : forall e e0 i, ~~(is_leaf e) -> ~~ is_leaf (subst_e i e e0).
Proof. elim;rewrite/=;intros;try done. apply H. Qed. *)

(*Lemma subst_e_project_rect : forall e e0 i,  project_rec (subst_e i.+1 e e0) = subst_e i (project_rec e) e0. 
Proof. elim;rewrite /=;try done;intros. destruct n. rifliad. simpl. rifliad.*)


(*Lemma contractive_project : forall g i n p, contractive_i i g ->  -> project g p = EVar n -> i <= n.
Proof.
elim;rewrite /=;intros. inversion H0. subst. done.  inversion H0. move : H1. rifliad. 
move : H1. rifliad. intros. apply : H. subst. done.*)


(*Lemma ptcps_subsitution_aux : forall g0 g1 i, ptcps_of_g g0 `<=` ptcps_of_g (substitution i g0 g1).
Proof. elim;rewrite /=;try done;intros. rifliad. simpl. done. apply/fsetUSS.  done. eauto. 
rewrite !big_map. apply/fsetUSS. done. apply/bigfcupsP. intros.  apply/fsubset_trans. apply : (H i0 H0). 
3 : { apply/bigfcup_sup. done. done. }
Qed.

Lemma ptcps_subsitution_aux1 : forall g0 g1 i, ptcps_of_g (substitution i g0 g1) `<=` ptcps_of_g g0 `|` (ptcps_of_g g1).
Proof. elim;rewrite /=;try done;intros. rifliad. Search _ (fset0 `|`_).  rewrite fset0U. done. rewrite /=. done.
rifliad. simpl. Search _ (?a `<=` ?a `|` _). apply fsubsetUl. simpl. done. 
 apply/fsetUSS. rewrite fsubsetUl //=. done. done. done. rewrite -fsetUA. apply/fsetUSS. done. rewrite !big_map. apply/bigfcupsP. intros.  apply/fsubset_trans. apply : (H i0 H0). apply/fsetUSS. apply/bigfcup_sup. done. done. done. 
Qed.

(*Search _ (?A `<=` _ ->  _).
Lemma squeeze : forall (S0 S1 : ptcps), S0 `<=` S1 -> S1 `<= S2 -> *)

Lemma ptcps_substitution : forall g, ptcps_of_g g[GRec g] = g.
Proof.
intros. apply/fsetP=>k. 
apply Bool.eq_true_iff_eq. split. intros. move : (ptcps_subsitution_aux1 g (GRec g) 0). move/fsubset_in. 
have : ptcps_of_g g = ptcps_of_g (GRec g). done. move=><-. Search _ (?a`|`?a). rewrite fsetUid. move=>Hall.  apply Hall. done. 
intros. move : (ptcps_subsitution_aux g (GRec g) 0). move/fsubset_in=>Hall. apply Hall. done. 
Qed.*)


(*Lemma project_end : forall g p, p \notin (ptcps_of_g g) -> locked_pred size_pred g -> project g p.
Proof.
elim;intros;rewrite /=;try done.
- eauto. eauto. 
- simpl in H0. apply H in H0. rewrite /is_leaf in H0.  destruct H0. rewrite /is_leaf H0. auto. destruct H0. rewrite H0. eauto. by simpl in H1. 
- move : H0.  rewrite /= !inE  !negb_or. rifliad. by rewrite (eqP H0) eqxx.  rewrite (eqP H2) eqxx. lia. 
  intros. destruct (andP H3). apply H in H5 as [].  auto. destruct H5. eauto. eauto. 
- move : H0. rewrite /= !inE !negb_or. rifliad. by rewrite (eqP H0) eqxx. rewrite (eqP H2) eqxx. lia.
  rewrite big_map match_n. move/andP=>[] _. move/bigfcupP=>HH.   
  have : p \notin ptcps_of_g (nth GEnd l 0). apply/negP=>HH'. apply : HH. exists (nth GEnd l 0). rewrite mem_nth //=.  
  simpl in H1. lia. done. intros. edestruct H. 2 : { apply : x. } rewrite mem_nth //=. by simpl in H1;lia. simpl in H1. 
  destruct (andP H1). apply (allP H4). rewrite mem_nth //=. rewrite H3. auto.  destruct H3. rewrite H3. eauto. 
Qed.*)




(*Lemma project_subst2 : forall g g0 i p, locked_pred size_pred g -> p \notin ptcps_of_g g0 -> project (substitution i g g0) p = subst_e i (project g p) (project g0 p).
Proof.
elim;intros. 
rewrite /=. rifliad. done.
rewrite /=. simpl in H1. symmetry. case_if. 
have :  p \in (ptcps_of_g (substitution i.+1 g g0)). apply/fsubset_in. apply ptcps_subsitution_aux. done.
move=>->. rewrite /= H //=. cc. 
rifliad. move : (ptcps_subsitution_aux1 g g0 i.+1). move/fsubset_in=>Hin. apply Hin in H3. move : H3. 
rewrite !inE (negbTE H1) H2. done.

simpl. rifliad. rewrite H //=. cc. 
rewrite H //=. cc.
rewrite H //=. cc.
rewrite /=. rifliad. rewrite -map_comp. simpl. f_equal. rewrite -map_comp. apply/eq_in_map=>ll Hl. simpl. apply H. done. cc. 
done.

rewrite /=. rifliad. rewrite -map_comp. simpl. f_equal. rewrite -map_comp. apply/eq_in_map=>ll Hl. simpl. apply H. done. cc. done. 
rewrite !match_n.
rewrite nth_subst. apply : H. apply/mem_nth. simpl in H1. cc.
cc. done.
Qed.*)



(*Lemma project_subst : forall g g0 i p, bound_i i g -> (exists j, contractive_i j g)  -> project (substitution i g g0) p = subst_e i (project g p) (project g0 p).
Proof.
elim;intros.
- rewrite /=. rifliad.
- done.
- rewrite /=.
- 2 : {  rewrite /=. rifliad. rewrite /=. f_equal. apply H. simpl in H0. done. destruct H1. simpl in H1. exists 0. done. 
  rewrite /=. f_equal. apply H. simpl in H0. done.  destruct H1. simpl in H1. exists 0. done. apply H.  simpl in H0. done. 
  destruct H1. exists 0. simpl in H1. done. }

2 : {  rewrite /=. rifliad. rewrite /=. f_equal. rewrite -!map_comp. apply eq_in_map. move=> x Hin. simpl. apply H. done. simpl in H0. apply (allP H0). done. destruct H1. simpl in H1. exists 0. apply (allP H1). done. 
  rewrite /=. f_equal.  rewrite -!map_comp. apply eq_in_map. move=> x Hin.  apply H. simpl in H0. done.  simpl in H0. apply (allP H0). done. destruct H1. simpl in H1. exists 0. apply (allP H1). done. 
  rewrite !match_n. rewrite nth_subst. apply H. apply/mem_nth. admit. (*traverse size_pred*) simpl in H0. apply (allP H0). apply/mem_nth. admit. destruct H1. exists 0. apply (allP H1). apply/mem_nth. admit.
rewrrite -H.  rewrite -nth_project. rewrite -map_comp. . Hexists 0. done. apply H.  simpl in H0. done. 
  destruct H1. exists 0. simpl in H1. done. }

 { 
simpl in H1. eauto. lia. move : H0. rewrite /=. intros. apply/andP. split. lia. apply : bound_cont_eq. 2: {  lia. } apply : bound_le.    2: { lia. } lia. done.
 symmetry. rifliad.
 *  rewrite H //=. move : H0. rewrite /=. apply : H0.
    
Lemma project_subst : forall g g0 i p, locked_pred size_pred g -> p \in ptcps_of_g g0 -> project (substitution i g g0) p = subst_e i (project g p) (project g0 p).
Proof.
elim;intros;rewrite/=. by rifliad. done. 
have :  p \in (ptcps_of_g (substitution i.+1 g g0)). apply/fsubset_in. apply ptcps_subsitution_aux. done.
move=>->. rewrite H //=. 
move : H1. rewrite /= !inE. repeat move/orP=>[].

move/eqP=>->. rewrite eqxx.

rifliad.  rewrite H in H1;eauto.   move : H0.
rewrite HH in H1. done.  rewrite H in H1;auto.  simpl. rewrite H1 in HH. move/isnt_leafP=>[]. intros. 
destruct (project g p); try done. done. eauto. apply is_leafP in H3. rewrite H in H2;auto.  destruct H3. rewrite H3 in H2. 
by simpl in H2. destruct H3. rewrite H3 in H2. simpl in H2. simpl in H0. eapply bound_project in H0;eauto. erewrite H3 in H0. 
simpl in H0. move : H2.  rifliad. rewrite /=.  f_equal. eauto. 
rifliad. rewrite /=. f_equal. eauto.
rifliad. rewrite /=. f_equal. eauto.
eauto.
rifliad. rewrite /=. f_equal. rewrite -!map_comp.  apply /eq_in_map=>ll Hin. simpl. apply H. done. eauto. simpl in H1. destruct (andP H1).   eauto. simpl. f_equal. rewrite -!map_comp.  apply /eq_in_map=>ll Hin. simpl. apply H. done. eauto. simpl in H1. destruct (andP H1). eauto.

rewrite !match_n.
rewrite nth_subst. apply : H. apply/mem_nth. simpl in H1. by destruct (andP H1).  simpl in H0. apply (allP H0). apply/mem_nth. simpl in H1. destruct (andP H1).  done. simpl in H1. destruct (andP H1). apply (allP H4). apply/mem_nth. done.  
Qed.



Lemma projmap_subst : forall g0  g i S, bound_i i g0 -> locked_pred size_pred g0 -> projmap S (substitution i g0 g) = map_subst i (projmap S g0) g.
Proof.
intros. rewrite /projmap /map_subst. apply/fmapP=>k. rewrite !mapf_if. 
rewrite (@mapf_if _ _ _ (fun x =>  subst_e i (try_fnd ([fmap p => project g0 (val p)]) (x)) (project g (x)))) /=.
rifliad. f_equal. rewrite project_subst. f_equal. rewrite /try_fnd. rewrite mapf_if H1. done. all : eauto.
Qed.*)



(*Instance locked_traverse : forall P g, CGoal (locked_pred P g) -> CGoal (traverse_pred P g).
Proof. move => P g. apply cgoal_imp. unlock locked_pred. done. Defined.*)



Lemma projmap_subst : forall g0  g i S, fv_g g = fset0 -> projmap S (substitution i g0 g) = map_subst i (projmap S g0) g.
Proof.
intros. rewrite /projmap /map_subst. apply/fmapP=>k. rewrite !mapf_if. 
rewrite (@mapf_if _ _ _ (fun x =>  subst_e i (try_fnd ([fmap p => project g0 (val p)]) (x)) (project g (x)))) /=.
rifliad. f_equal. rewrite project_subst. rewrite /try_fnd. rewrite mapf_if H0. done. done. 
Qed.

Ltac with_cc tac := cc;tac;cc.
Lemma traverse_project_pred_unf : forall g0 g1 i, locked_pred rec_pred g0 -> locked_pred project_pred g1 -> fv_g g1 = fset0 -> locked_pred project_pred (substitution i g0 g1).
Proof. 
elim;intros;rewrite /=; simpl in *;try done. 
- rifliad. cc.
- cc.  
- rifliad. cc. cc. apply H;cc.
-  cc; apply H; cc. 
- cc. have : (project_pred (GBranch a l)) by cc. rewrite /= /all_eq_F !big_map. intros. rewrite !all_map. apply/andP.  split. apply/allP=> x' Hin. 
  simpl. rewrite /projmap.  apply/eqP/fmapP=>k. rewrite !mapf_if. case_if. f_equal.
  move : Hin. move/nthP=>HH'. specialize HH' with GEnd. destruct HH'. rewrite -H5. erewrite nth_map. 
  rewrite !project_subst. f_equal. apply :  project_predP_aux. cc. 
  move : H3. rewrite !inE. move/orP=>[]. rewrite /fresh. destruct ( atom_fresh_for_list ([fset ptcp_from a; ptcp_to a] `|` \bigcup_(j <- l) substitution i j g1)) eqn:Heqn. 
rewrite Heqn. move/eqP=>->. clear Heqn.
  move : n. move/negP. rewrite !inE. move/andP=>[]. 
done. move/andP=>[].  done. done. done.  done.  cc. done.  apply/allP=>k Hin.  simpl. apply H.  done. cc. cc. done. 
Qed.

Lemma locked_predT : forall g, locked_pred predT g = true.
Proof. ul. elim;rewrite /=; try done;intros. apply/allP=> x Hin. rewrite H //=. Qed.

Instance traverse_predTG g : {goal locked_pred predT g}.
constructor. rewrite locked_predT. done. Defined. 


Check traverse_split.


Lemma locked_rec_pred_unf : forall g0 g1 i, locked_pred rec_pred g0 -> locked_pred rec_pred g1 -> fv_g g1 = fset0 -> locked_pred rec_pred (substitution i g0 g1).
Proof. intros. rewrite !locked_split traverse_project_pred_unf //=;cc. rewrite traverse_size_pred_unf //=;cc.  
rewrite traverse_action_pred_unf //=; cc. 
Qed.

Instance traverse_project_pred_unfG : forall g0 g1 i, {goal locked_pred rec_pred g0} -> {goal locked_pred project_pred g1} -> {hint fv_g g1  = fset0} -> {goal locked_pred project_pred (substitution i g0 g1)}.
Proof. intros. constructor. apply traverse_project_pred_unf;cc. Qed.



Instance unf_rec_rec_red : forall g n, {goal locked_pred rec_pred (GRec n g)} -> {hint fv_g (GRec n g) = fset0} -> {goal locked_pred rec_pred (g[g GRec n g//n])}.
Proof. move => g n [] H [] H1. constructor.
rewrite locked_rec_pred_unf //=. cc. Qed. 


Instance all_ForallG : forall (A : eqType)  (l l' : seq A) (P0 P1 : pred A), {hint Forall (fun p => P0 p.1 -> P1 p.2) (zip l l')} -> {hint exists (a : A),True} -> {hint size l = size l'} -> {goal all P0 l} -> {goal all P1 l'}.
Proof. Admitted. 
(*intros. destruct H,chint0,H0,H1,H2. constructor. apply/allP => x' Hin.  
move : cgoal1. move/Forall_forall=>Hall.
move : Hin. move/nthP=>Hnth. specialize Hnth with x. destruct Hnth. rewrite -H1. 
specialize Hall with (nth (x,x) (zip l l') x0). move : Hall. rewrite nth_zip /=. intros. apply : Hall. rewrite -nth_zip.  apply/mem_nth. by rewrite size_zip minnE chint0  nat_fact. done. apply (allP cgoal0). apply/mem_nth. rewrite chint0. done. done. 
Qed.*)

Instance gType_existsH : {hint exists _ : gType_EqType, True}.
constructor. exists GEnd.  done. Qed.

Lemma any_hint : forall (P : Prop), P -> {hint P}. intros. constructor. done. Qed.

Hint Resolve any_hint : typeclass_instances.
Lemma step_action : forall g l g',step g l g' -> locked_pred action_pred g -> locked_pred action_pred g'.  
Proof.
move => g l g'. elim; rewrite /=. 
- cc.
- intros.  split_and. 
- intros.  cc.
- intros. cc. split_and. cc. apply H0.  cc.
- intros. cc. split_and. cc. cc.   
- intros. apply H0. cc.
Qed.


Lemma step_size : forall g l g',step g l g' -> locked_pred size_pred g -> locked_pred size_pred g'.  
Proof.
move => g l g'. elim; rewrite /=;intros; try done;cc.  
apply H0. cc. split_and. rewrite -H. cc. cc. apply H0. cc.
Qed.
Check project_pred.

(*Lemma all_project_test : forall gs,  
all (fun g' : gType => [fmap p => project (nth GEnd gs 0) (fsval p)] == [fmap p => project g' (fsval p)]) gs ->
all (fun g' : gType => [fmap p => project (nth GEnd gs 0) (fsval p)] == [fmap p => project g' (fsval p)]) gs.*)

Lemma all_eq_F_end : forall (A B : eqType) (l : seq A) (F : A -> B) g g', g \in l -> g' \in l -> all_eq_F F l g ->  all_eq_F F l g'.
Proof.
move => A B.  intros.  move : H1. rewrite /all_eq_F. move/allP=>Hall. apply/allP=>x Hin. apply Hall in H0. rewrite -(eqP H0). 
apply Hall in Hin. rewrite -(eqP Hin). apply eq_refl.
Qed.

Lemma all_eq_F_end_not : forall (A B : eqType) (l : seq A) (F : A -> B) g g', g \in l -> g' \in l -> ~~(all_eq_F F l g) ->  ~~(all_eq_F F l g').
Proof. 
move => A B.  intros.  apply/negP. move => HH. apply (negP H1). eauto using all_eq_F_end. 
Qed.


Lemma all_eq_F_end2 : forall (A B : eqType) (l : seq A) (F : A -> B) g g', g \in l -> g' \in l -> all_eq_F F l g =  all_eq_F F l g'.
Proof.
intros.  destruct (all_eq_F F l g) eqn:Heqn.  rewrite (all_eq_F_end H H0) //=.
suff :  ~~(all_eq_F F l g'). move/negP. intros. destruct (all_eq_F F l g') eqn:Heqn2. done. done. 
apply  (all_eq_F_end_not H H0). destruct (all_eq_F F  l g). done. done.
Qed.


(*Lemma all_eq_F_in : forall (A B : eqType) (l : seq A) (F : A -> B) g, g \in l  ->  all_eq_F F l g.
Proof.
move => A B.  elim; try done. intros.   rewrite /=. move : H0. rewrite inE. move/orP=>[]. move/eqP=>->. rewrite eqxx /=.  rewrite /all_eq_F. apply/allP=>x Hin. 
apply Hall in Hin. rewrite -(eqP Hin). apply eq_refl.
Qed.*)

Lemma all_eq_F_cons : forall (A B : eqType) l a x (F : A -> B), all_eq_F F (x::l) a = (F x == F a) && (all_eq_F F l a). 
Proof. move => A B. rewrite /=. intros. by rewrite eq_sym.  Qed.

Check project.

(*Lemma test2 : forall g l g' g0 g'0 p, step g l g'  -> Estep (project g p) l (project g' p).*)
Print label. Check EMsg. 

Check Estep.


Instance linear_sgmsg : forall a u g0, {hint Linear (GMsg a u g0)} -> {goal Linear g0}.
Proof. 
move => a u g0. apply chint_imp. rewrite /Linear /=.  intros. move : (H (a::aa_p) a0 aa a1). rewrite cat_cons /=. 
  destruct ( aa_p ++ a0 :: rcons aa a1) eqn:Heqn. case : aa_p H0 Heqn.  done. done.
  intros. have : Tr ((a::aa_p ++ (a0::aa) ++ [::a1])) (GMsg a u g0). auto.  move/H2 => H3.  move : (H3 H1). 
  move => [] mi [] mo. intros. auto. 
Qed.

Instance linear_branch_aux : forall a gs, {hint Linear (GBranch a gs)} -> {goal Forall Linear gs}.  
Proof.
move => a gs. apply chint_imp. intros. apply/List.Forall_forall. intros. rewrite /Linear. intros. unfold Linear in H. have : Tr (a::aa_p ++ a0::aa ++ ([::a1])) (GBranch a gs). move : H0.  move/In_in. move/nthP=>Hnth. specialize Hnth with GEnd. destruct Hnth. rewrite -H3 in H1. apply : TRBranch. eauto. apply : H1. 
intros. apply : H. rewrite -cat_cons in x0. apply : x0. done. 
Qed.

Instance linear_branch : forall a gs n, {hint Linear (GBranch a gs)} -> {goal n < size gs} -> {goal Linear (nth GEnd gs n)}.
Proof. intros. destruct H,H0.  apply Build_CHint in chint0. apply linear_branch_aux in chint0. destruct chint0. move : cgoal1. move/Forall_forall. intros. constructor. eauto. Qed.



Instance linear_unf : forall g n, {hint Linear (GRec n g)} -> {goal Linear g[g GRec n g//n]}.
Proof. move => g n. apply chint_imp.
intros.  unfold Linear in *. intros. apply : H. constructor. eauto. done. 
Qed.

Lemma step_tr : forall g vn g', step g vn g' -> locked_pred size_pred g ->  exists s, Tr (s ++ [::vn.1]) g /\ Forall (fun a => (ptcp_to a) \notin vn.1) s.
Proof.
move => g vn g'. elim.
- intros. exists nil. rewrite /=. auto.
- intros. exists nil. rewrite /=. split;auto.  apply TRBranch with (n:=n)(d:=GEnd). done. done.
- intros.  simpl in H2. destruct H0. cc. destruct H0. exists (a::x). rewrite /=. auto. 
- intros. move : H1. move/Forall_forall=>Hall. specialize Hall with (nth (GEnd,GEnd) (zip gs gs') 0).
  rewrite nth_zip in Hall.  simpl in Hall. have : exists s : seq action, Tr (s ++ [:: l.1]) (nth GEnd gs 0) /\ Forall (fun a : action => ptcp_to a \notin l.1) s. apply Hall.  rewrite -nth_zip. apply/mem_nth. rewrite size_zip minnE H. 
  have :  size gs' - (size gs' - size gs') = size gs' by lia. move=>->. simpl in H3. rewrite -H. cc. lia. cc. intros. destruct x,H1. exists (a::x). simpl. split;auto.  apply TRBranch with (n:=0)(d:=GEnd).  cc. done. done. 
- intros. destruct H0.  cc. destruct H0. exists x. auto. 
Qed.



(*Lemma In_exists : forall (A : Type) (a : A) l, In a l -> exists (l0 l1 : seq A), l = l0 ++ (a::l).*)
Lemma ch_diff : forall g a0 aa a1, Linear g -> Tr (a0::(aa++[::a1])) g  -> Forall ( fun a => (ptcp_to a) \notin a1) (a0::aa) ->  Forall (fun a => action_ch a != action_ch a1) (a0::aa).
Proof.
intros. apply/List.Forall_forall. intros. 
destruct (eqVneq (action_ch x) (action_ch a1)); last done. inversion H1. subst.
exfalso. simpl in H2. destruct H2. 
- subst. apply : no_indep. apply : H5.  apply H6. apply Linear_1 in H. apply : H. 
  rewrite -[_::_]cat0s in H0. apply : H0. rewrite /same_ch. apply/eqP. done.
- apply List.in_split in H2.  destruct H2,H2. rewrite H2 in H0. rewrite /Linear in H.
  specialize H with (a0::x0) x x1 a1. 
have : (a0 :: (x0 ++ (x :: x1)%SEQ)%list ++ [:: a1]) = ((a0 :: x0) ++ x :: x1 ++ [:: a1]).
  rewrite /=. f_equal. rewrite -catA. f_equal.


  intros. move : H0.  rewrite x2. move/H=>H3. 
  have : same_ch x a1. by rewrite /same_ch e. move/H3. case. intros. move : H1.  
  rewrite H2. intros. inversion H1. apply List.Forall_app in H8. destruct H8. inversion H9. apply : no_indep. 
  apply H12.  apply H13.  done.
Qed.

Lemma distinct_ch : forall g vn g', step g vn g' -> Linear g ->locked_pred size_pred g ->  exists s, Tr (s ++ [::vn.1]) g /\  Forall (fun a =>  (action_ch a) != (action_ch vn.1)) s.
Proof. intros. edestruct (step_tr). eauto. eauto. destruct H2. exists x. split;auto. inversion H3. done. apply : ch_diff. eauto.
subst.  auto. auto. 
Qed.

(*needs contractiveness to solve*)
(*Lemma Tr_uniq : forall g a0 a1, Tr ([::a0]) g -> Tr ([::a1]) g -> a0 = a1.
Proof. elim;intros. inversion H. inversion H0. inversion H0. inversion H1. subst. apply H. inversion H0. done. by inversion H;inversion H0.
inversion H0. inversion H0. inversion H
inversion H0;inversion H1.*)

(*Lemma distinct_ch : forall g vn g', step g vn g' -> forall a, Linear g ->locked_pred size_pred g ->  a <> vn.1 -> Tr ([::a]) g ->  (action_ch a) != (action_ch vn.1).
Proof. move => g vn g'. intros.  edestruct distinct_ch_aux. eauto. cc. cc. destruct H4. destruct x. simpl in H4.  elim; intros. simpl inH1inversion H3. simpl. subst. done. simpl in H2. inversion H3. subst. done.  inversion H5. subst. apply H0. cc. cc. done. simpl in H2. done. 
apply IHstep. cc. cc. done. 
edestruct distinct_ch_aux. all: eauto. destruct H2. destruct x.  simpl in H2. destrctedestruct (step_tr). eauto. eauto. destruct H2. exists x. split;auto. inversion H3. done. apply : ch_diff. eauto.
subst.  auto. auto. 
Qed.*)



Instance hint_size_eq2 (gs gs' : seq gType) x0 : {hint size gs = size gs'} -> {goal x0 < size gs'} -> {goal x0 < size gs}.
Proof. case. move => H. case. move => H0. constructor. rewrite H. done. Qed.

(*Lemma step_not_leaf : forall g l g' p, step g l g' -> ~~ (is_leaf (project g p)). 
Proof. *)

Lemma project_pred_ptcps : forall a gs i p, locked_pred rec_pred (GBranch a gs) -> i < size gs -> p \in fv_g (GBranch a gs) -> p \in  fv_g (nth GEnd gs i).
Proof. intros.  move : H1. Print fresh.  destruct (atom_fresh_for_list ([::ptcp_from a;ptcp_to a])). Check fv_project_eq. rewrite !(@fv_project_eq _ x).  move : n. move/negP. rewrite !inE. split_and. move : H1. rewrite /=. rewrite (negbTE H2) (negbTE H4). rewrite match_n. intros. erewrite project_predP.  apply : H1. cc. rewrite !inE. lia. cc. cc. cc. cc. 
Qed.



 Lemma project_pred_ptcps2 : forall a gs i p, locked_pred rec_pred (GBranch a gs) -> i < size gs ->  (p \in  fv_g (nth GEnd gs i)) ->  (p \in fv_g (GBranch a gs)).
Proof. intros.  rewrite /= big_map.  rewrite foldr_exists. apply/hasP.  exists (nth GEnd gs i). cc. done. 
Qed.

Lemma project_pred_ptcps_set : forall a gs i, locked_pred rec_pred (GBranch a gs) -> i < size gs -> fv_g (GBranch a gs) = fv_g (nth GEnd gs i).
Proof.
intros. apply/fsetP. move => x.  destruct ((x \in fv_g (nth GEnd gs i))) eqn:Heqn.
erewrite project_pred_ptcps2. done. cc. eauto. done. destruct ( (x \in fv_g (GBranch a gs)))eqn:Heqn2. erewrite project_pred_ptcps in Heqn. done. cc. eauto. lia. done. 
Qed.


Lemma fv_g_subst : forall  g g' n x, fv_g g' = fset0 -> n <> x -> (n \in (fv_g (substitution x g g'))) = (n \in (fv_g g)).
Proof. elim;rewrite /=;try done;intros. rewrite !inE. rifliad. rewrite H !inE. have : n0 == n = false by lia. by move=>->. 
rewrite /= !inE. done. 
rifliad. rewrite /=. Check mem_map. Search (_ \in (map _ _)). Search _ (_ \in _ = _ \in _).  Search _ ((is_true _ -> is_true _) -> _ = _). rewrite !inE.  destruct (n0 != n)eqn:Heqn;rewrite /= //=.   rewrite Heqn //=.
apply H. done. done. rewrite Heqn //=. 
rewrite !big_map.  elim : l H. rewrite !big_nil. done. intros. rewrite !big_cons. rewrite !inE. rewrite H2 //=. 
destruct ( (n \in fv_g a0)) eqn:Heqn; rewrite !Heqn //=. apply H. intros. apply H2. rewrite !inE H3. lia. done. done. 
Qed.


Lemma fv_g_unf : forall g g0 n, fv_g g0 = fset0 -> fv_g (g[g g0 // n]) = fv_g g `\ n. 
Proof. 
elim;rewrite /=;intros;apply/fsetP=>k;rewrite !inE.
- rifliad. rewrite (eqP H0) H !inE. by destruct (eqVneq k n0).
- rewrite /= !inE. destruct (eqVneq k n). subst. lia. lia. 
- lia.
- rifliad. rewrite /= (eqP H1) !inE. destruct (k != n0);rewrite /=. done. done.
- rewrite /= H //= !inE. destruct (k != n);rewrite /=;try lia.  rewrite H //= !inE. done.
- rewrite !big_map. induction l. rewrite !big_nil !inE. lia. 
  rewrite !big_cons !inE H //= !inE. destruct (k != n);rewrite /=. destruct (k \in fv_g a0) eqn:Heqn;rewrite Heqn //=.
  rewrite /= in IHl. apply IHl. intros. apply H. eauto.  done. rewrite /= in IHl. apply IHl. intros. apply H. eauto. done.
Qed.





Lemma step_test : forall g l g', step g l g' -> fv_g g = fset0 -> Linear g -> locked_pred rec_pred g ->  Estep (project g (ptcp_from l.1)) (Sd,action_ch l.1,l.2) (project g' (ptcp_from l.1)).
Proof. move => g l g'. elim.
- intros. rewrite /= eqxx. auto.  
- intros. rewrite /= eqxx. erewrite <- (@nth_map _ _ _ EEnd (fun g => project g (ptcp_from a))).    apply estep_branch. by   rewrite size_map.  done. 
- intros. move : H1. move/[dup]. intros. rewrite !inE in H1.  rewrite /=. 
  split_and. rewrite [_ == ptcp_to a]eq_sym. rewrite (negbTE H6).
  rifliad.
 * constructor. apply H0.  cc. cc. cc. edestruct distinct_ch. have : step (GMsg a u g1) l0 (GMsg a u g2) by eauto. intros. apply : x. auto. cc. destruct H8. move : H9. move/Forall_forall=>HH. apply/eqP. rewrite neg_sym. destruct x. simpl in H8. inversion H8. subst. rewrite !inE in H5. done. simpl in H8.  inversion H8. subst. apply HH. rewrite !inE. done.
 * apply : H0. cc. cc. cc. 
- intros. rewrite /=. move : H2. move/[dup]. move=>H2 Hdup. rewrite notin_label in H2. split_and. rewrite eq_sym. rifliad.
 * constructor. rewrite !size_map. done. apply/Forall_forall. move => x. 
   move/nthP=>HH. specialize HH with (EEnd,EEnd). destruct HH. 
 move : H8.  rewrite size_zip !size_map  H minnE nat_fact. intros. 
clear H6. rewrite nth_zip in H9. rewrite -H9 /=. 
   repeat erewrite (@nth_map _ GEnd _ EEnd (fun g => project g (ptcp_from l0.1))).  
   move : H1. move/Forall_forall=>Hall;intros. specialize Hall with (nth (GEnd,GEnd) (zip gs gs') x0).
   rewrite nth_zip in Hall. simpl in Hall. apply Hall. rewrite -nth_zip. apply/mem_nth. rewrite size_zip minnE H.
   have : size gs' - (size gs' - size gs') = size gs' by lia. move=>->. done. done. all: cc. simpl in H3. erewrite <- project_pred_ptcps_set.  cc. cc. cc. 
   rewrite !size_map. done.
 * edestruct distinct_ch. have : step (GBranch a gs) l0 (GBranch a gs') by eauto. intros. apply : x. auto. cc. destruct H8.   move : H9. move/Forall_forall=>Hall.  apply/eqP. rewrite neg_sym. apply : Hall. destruct x. simpl in H8.
   inversion H8. subst. rewrite !inE in Hdup. done. simpl in H8. inversion H8. auto. 
 * constructor. rewrite !size_map //=.   apply/(@forallP _ _ (EEnd,EEnd)).  intros. move : H1. move/Forall_forall=>HH0. specialize HH0 with (nth (GEnd,GEnd) (zip gs gs') x0).
   move : H9.   rewrite size_zip minnE !size_map H nat_fact=>H9. 

 rewrite nth_zip /= in HH0. rewrite nth_zip /=.  Check nth_project.  
  rewrite -!nth_project in HH0. apply : HH0. rewrite -nth_zip. apply/mem_nth.  rewrite size_zip minnE H nat_fact. done. done. erewrite <- project_pred_ptcps_set. eauto. cc. rewrite H. done. cc. cc. by rewrite !size_map. done.

*edestruct distinct_ch. have : step (GBranch a gs) l0 (GBranch a gs') by eauto. intros. apply : x. auto. cc. destruct H9.   move : H10. move/Forall_forall=>Hall.  apply/eqP. rewrite neg_sym. apply : Hall. destruct x. simpl in H9.
   inversion H9. subst. rewrite !inE in Hdup. done. simpl in H9. inversion H9. auto. 

 * rewrite !match_n.
   move : H1. move/Forall_forall=>Hall. specialize Hall with (nth (GEnd,GEnd) (zip gs gs') 0). 
   rewrite nth_zip in Hall. simpl in Hall. apply Hall. rewrite -nth_zip. apply/mem_nth. rewrite size_zip minnE H.
   have : size gs' - (size gs' - size gs') = size gs' by lia. move=>->. simpl in H4. rewrite -H. cc. all : cc. 
- intros. erewrite project_pred_ptcps_set in H3. eauto. cc. cc. 
- intros. have : locked_pred rec_pred (GRec n g0) by cc. clear H3. move=> H3. rifliad. 
 * rewrite !project_subst in H0.  rewrite (eqP H4) /= eqxx H4 in H0. apply H0. rewrite -H1. 
   rewrite fv_g_unf //=.  cc. have : locked_pred rec_pred (GRec n g0). cc. intros. cc. done. 
 * constructor. rewrite /= !project_subst /= in H0. rewrite H4 H5 in H0.   apply H0. rewrite -H1. by rewrite fv_g_unf. cc. cc.
   done. move : H0. rewrite project_subst /=. rewrite H4 H5. intros. rewrite subst_nop in H0. apply H0. rewrite -H1. by rewrite fv_g_unf. cc. cc. by rewrite H5. done. 
Qed.

Lemma step_test2 : forall g l g', step g l g' -> fv_g g = fset0 -> Linear g -> locked_pred rec_pred g ->  Estep (project g (ptcp_to l.1)) (Rd,action_ch l.1,l.2) (project g' (ptcp_to l.1)).
Proof. Admitted.
(* move => g l g'. elim.
- intros. rewrite /= eqxx. auto.  
- intros. rewrite /= eqxx. erewrite <- (@nth_map _ _ _ EEnd (fun g => project g (ptcp_from a))).    apply estep_branch. by   rewrite size_map.  done. 
- intros. move : H1. move/[dup]. intros. rewrite !inE in H1.  rewrite /=. 
  split_and. rewrite [_ == ptcp_to a]eq_sym. rewrite (negbTE H6).
  rifliad.
 * constructor. apply H0.  cc. cc. cc. edestruct distinct_ch. have : step (GMsg a u g1) l0 (GMsg a u g2) by eauto. intros. apply : x. auto. cc. destruct H8. move : H9. move/Forall_forall=>HH. apply/eqP. rewrite neg_sym. destruct x. simpl in H8. inversion H8. subst. rewrite !inE in H5. done. simpl in H8.  inversion H8. subst. apply HH. rewrite !inE. done.
 * apply : H0. cc. cc. cc. 
- intros. rewrite /=. move : H2. move/[dup]. move=>H2 Hdup. rewrite notin_label in H2. split_and. rewrite eq_sym. rifliad.
 * constructor. rewrite !size_map. done. apply/Forall_forall. move => x. 
   move/nthP=>HH. specialize HH with (EEnd,EEnd). destruct HH. 
 move : H8.  rewrite size_zip !size_map  H minnE nat_fact. intros. 
clear H6. rewrite nth_zip in H9. rewrite -H9 /=. 
   repeat erewrite (@nth_map _ GEnd _ EEnd (fun g => project g (ptcp_from l0.1))).  
   move : H1. move/Forall_forall=>Hall;intros. specialize Hall with (nth (GEnd,GEnd) (zip gs gs') x0).
   rewrite nth_zip in Hall. simpl in Hall. apply Hall. rewrite -nth_zip. apply/mem_nth. rewrite size_zip minnE H.
   have : size gs' - (size gs' - size gs') = size gs' by lia. move=>->. done. done. all: cc. simpl in H3. erewrite <- project_pred_ptcps_set.  cc. cc. cc. 
   rewrite !size_map. done.
 * edestruct distinct_ch. have : step (GBranch a gs) l0 (GBranch a gs') by eauto. intros. apply : x. auto. cc. destruct H8.   move : H9. move/Forall_forall=>Hall.  apply/eqP. rewrite neg_sym. apply : Hall. destruct x. simpl in H8.
   inversion H8. subst. rewrite !inE in Hdup. done. simpl in H8. inversion H8. auto. 
 * constructor. rewrite !size_map //=.   apply/(@forallP _ _ (EEnd,EEnd)).  intros. move : H1. move/Forall_forall=>HH0. specialize HH0 with (nth (GEnd,GEnd) (zip gs gs') x0).
   move : H9.   rewrite size_zip minnE !size_map H nat_fact=>H9. 

 rewrite nth_zip /= in HH0. rewrite nth_zip /=.  Check nth_project.  
  rewrite -!nth_project in HH0. apply : HH0. rewrite -nth_zip. apply/mem_nth.  rewrite size_zip minnE H nat_fact. done. done. erewrite <- project_pred_ptcps_set. eauto. cc. rewrite H. done. cc. cc. by rewrite !size_map. done.

*edestruct distinct_ch. have : step (GBranch a gs) l0 (GBranch a gs') by eauto. intros. apply : x. auto. cc. destruct H9.   move : H10. move/Forall_forall=>Hall.  apply/eqP. rewrite neg_sym. apply : Hall. destruct x. simpl in H9.
   inversion H9. subst. rewrite !inE in Hdup. done. simpl in H9. inversion H9. auto. 

 * rewrite !match_n.
   move : H1. move/Forall_forall=>Hall. specialize Hall with (nth (GEnd,GEnd) (zip gs gs') 0). 
   rewrite nth_zip in Hall. simpl in Hall. apply Hall. rewrite -nth_zip. apply/mem_nth. rewrite size_zip minnE H.
   have : size gs' - (size gs' - size gs') = size gs' by lia. move=>->. simpl in H4. rewrite -H. cc. all : cc. 
- intros. erewrite project_pred_ptcps_set in H3. eauto. cc. cc. 
- intros. have : locked_pred rec_pred (GRec n g0) by cc. clear H3. move=> H3. rifliad. 
 * rewrite !project_subst in H0.  rewrite (eqP H4) /= eqxx H4 in H0. apply H0. rewrite -H1. 
   rewrite fv_g_unf //=.  cc. have : locked_pred rec_pred (GRec n g0). cc. intros. cc. done. 
 * constructor. rewrite /= !project_subst /= in H0. rewrite H4 H5 in H0.   apply H0. rewrite -H1. by rewrite fv_g_unf. cc. cc.
   done. move : H0. rewrite project_subst /=. rewrite H4 H5. intros. rewrite subst_nop in H0. apply H0. rewrite -H1. by rewrite fv_g_unf. cc. cc. by rewrite H5. done. 
Qed.
*)


Lemma step_test3 : forall g l g', step g l g' -> fv_g g = fset0 -> Linear g -> locked_pred rec_pred g -> forall p, p \notin l.1 -> (project g p) = (project g' p).
Proof. Admitted.
Check Estep.
Lemma estep_uniq : forall e l e0 e1, Estep e l e0 -> Estep e l e1 -> e0 = e1.
move => e l e0 e1 H. elim : H e1;intros.
- inversion H. done. subst. done.
- inversion H2;subst. done. f_equal. apply H0. done.
- inversion H0;subst. done.    done. 
- inversion H3. subst. done. f_equal. subst.  clear H3 H12 H2. elim : es1 es3 es0 H H0 H1 H10 H11 ;intros.   destruct es3. done. destruct es0. done. done. destruct es3. rewrite H10 in H0. done. destruct es0. done. simpl in H1 ,H2, H11. inversion H1.  inversion H2. inversion H11. subst. f_equal. simpl in *. auto. eauto. 
- apply H0. inversion H1.  subst. done.
Qed.

Definition bound g := fv_g g == fset0.

(*Linear should be included in *)
Definition linear (g : gType) := true. 
Lemma linearP : forall g, reflect (Linear g)  (linear g) . 
Admitted.


Definition rec_pred2 := (predI (predI rec_pred bound) linear).
Lemma step_project_aux2 : forall g l g' g0 g'0 p, step g l g' -> fv_g g = fset0 -> Linear g -> fv_g g0 = fset0 -> Linear g0 -> step g0 l g'0 -> project g p = project g0 p -> project g' p = project g'0 p.
Proof. 
intros. destruct (p \in l.1) eqn:Heqn.
-  move : Heqn. rewrite !inE. move/orP=>[]. 
 * move/eqP=>HH. subst. have : Estep (project g (ptcp_from l.1))  (Sd,action_ch l.1,l.2) (project g' (ptcp_from l.1)).
   apply step_test;auto.


Admitted.


Lemma step_project_aux : forall gs gs' a l,Forall (fun p => step p.1 l p.2) (zip gs gs') ->  size gs = size gs' ->
(forall g, g \in gs -> all_eq_F (projmap (fresh (GBranch a gs) |` GBranch a gs `\` a)) gs g) -> forall g', g' \in gs' ->
all_eq_F (projmap (fresh (GBranch a gs') |` GBranch a gs' `\` a)) gs' g'.
Proof.  
elim.  case. done. done. move => a l IH. case. done. 
intros. simpl. split_and. 2 : { simpl in IH. eapply IH. simpl in H3. split_and. clear IH. simpl in H.  inversion H. clear H. clear H1 H2.
 intros. apply/allP=> g'0 Hin. apply/eqP/fmapP=>k. rewrite !mapf_if. rifliad. f_equal.
move : H3.
Lemma step_project_aux : forall gs gs' a l,Forall (fun p => step p.1 l p.2) (zip gs gs') ->  size gs = size gs' ->  project_pred (GBranch a gs) -> project_pred (GBranch a gs').  
Proof. uf project_pred. intros. rewrite /=. intros.  suff : forall g', g' \in gs' -> all_eq_F (projmap [fmap p => project g (fsval p)]) gs' g'. elim. case;try done.
move => a l IH [];try done.
intros. rewrite /=. split_and. simpl. simpl in H. inversion H. specialize IH with l0 a1 l1.  apply IH in H5.
intros. gs l gs' H. induction H. elim. done.
intros. move : H2.  rewrite /=. intros. apply/allP. rewrite /=. move=>d Ind. done.  
Qed.

Lemma step_project_aux : forall (a : action) gs gs' l, size gs = size gs' ->Forall (fun p => step p.1 l p.2) (zip gs gs') -> 
                                    all_eq_F (projmap (fresh (a `|` \bigcup_(j <- gs) j) |` (a `|` \bigcup_(j <- gs) j) `\` a)) gs (nth GEnd gs 0) ->
                                    all_eq_F (projmap (fresh (a `|` \bigcup_(j <- gs') j) |` (a `|` \bigcup_(j <- gs') j) `\` a)) gs' (nth GEnd gs' 0).
Proof. rewrite /all_eq_F /projmap /=. intros. apply/allP. move=> gs'0 Hin. apply/eqP/fmapP=>k. rewrite !mapf_if. rifliad. f_equal. 
  move : Hin. move/nthP=>Hnth. specialize Hnth with GEnd. destruct Hnth. rewrite -H4.
  eapply project_predP_aux with (a:=a). Check project_predP_aux.  cc.  split_and.
  rewrite /rec_pred /=. split_and. cc.
Lemma step_project : forall g l g',step g l g' -> locked_pred rec_pred g -> locked_pred rec_pred g'.  
Proof.
move => g l g'. elim; rewrite /=;intros; try done;cc;split_and.  
- rewrite /rec_pred /=. split_and. cc. apply H0. cc.
- rewrite /rec_pred /=. split_and. cc. rewrite big_map.  rewrite /all_eq_F big_map /projmap. Set Printing Coercions. apply/allP=> g'0 Hin. apply/eqP/fmapP=>k. 
  rewrite !mapf_if. rewrite !inE. rifliad. f_equal.
  move : Hin. move/nthP=>Hnth. specialize Hnth with GEnd. destruct Hnth. rewrite -H6.
  eapply project_predP_aux with (a:=a). cc.  split_and.
  rewrite /rec_pred /=. split_and. cc.
 * 


rewrite -H. cc. cc. apply H0. cc.
Qed.


(*Lemma step_project : forall gs l gs' a, Forall2 (fun g g' => step g l g') gs gs' -> project_pred_aux a gs ->  proejct_pred_aux a gs'.  



Lemma step_size : forall g l g',step g l g' -> locked_pred size_pred g -> locked_pred size_pred g'.  
Proof.
move => g l g'. elim; rewrite /=. intros. lia.
intros. destruct (andP H0). apply (allP H2). apply/mem_nth. done.
intros. auto. 

intros. destruct (andP H2). move : H0.  move/Forall2_forall=>[]. intros. rewrite -a0. rewrite H3 /=. 
apply/allP. move => g'' Hin. 
move : Hin. move/nthP=>Hnth. specialize Hnth with GEnd.  destruct Hnth. rewrite -H5. apply : b. apply In2_nth2 with (d:=GEnd).
rewrite a0.  done. done. apply (allP H4). apply mem_nth. rewrite a0. done.
Qed.*)

(*Lemma ptcps_eq : forall (g0 g1 : gType) i, ptcps_of_g g0 = ptcps_of_g g1 -> ptcps_of_g g0 = ptcps_of_g (substitution i g0 g1).
Proof. Admitted.


Lemma step_ptcps : forall g l g', step g l g' -> (ptcps_of_g g') `<=` (ptcps_of_g g).
Proof. move => g l g'. elim.
intros. rewrite /=. Search _ fsub.  rewrite fsubsetUr. done. 
intros. rewrite /=. Search _ (_ `<=` _ `|` _). rewrite big_map. apply fsubsetU.  apply/orP. right. Check bigfcup_sup. apply bigfcup_sup. apply mem_nth. done. done.
intros. rewrite /=. Search _ (?a `|` _ `<=` ?a `|` _). apply fsetUS. done.
intros. rewrite /=. apply fsetUS. induction H0. done. rewrite big_map /= !big_cons.
 Search _ (_ `|` _ `<=` _ `|` _). apply fsetUSS. done. rewrite big_map in IHForall2. apply IHForall2.  inversion H. auto.  
intros. rewrite /=. erewrite (@ptcps_eq g0).  apply : H. by rewrite /=. 
Qed.*)



(*Lemma fsubsetPn (A B : {fset ptcp}) : reflect (exists2 x, x \in A & x \notin B) (~~ (A `<=` B)).
Proof.
 rewrite -fsetD_eq0; apply: (iffP (fset0Pn _)) => [[x]|[x xA xNB]]. Check fsetD_eq0. 
  by rewrite inE => /andP[]; exists x.
by exists x; rewrite inE xA xNB.
Qed.*)







(*Lemma step_props : forall g l g' S, step g l g' -> props S g -> props S g'.
Proof.
intros. rewrite /=. move : H0. intros.   rewrite !propsC //=. rewrite (step_action H) //=.
 rewrite (step_size H) //=. rewrite (step_project H) //=. apply props_project.
 eauto. by apply props_size. by apply props_action.
Qed.*)




(*Hint Resolve linear_branch linear_unf.*)



(*Lemma is_leaf_ptcps : forall (g : gType) p, p \notin ptcps_of_g g =  is_leaf (project g p).  
Proof.
elim;rewrite /=;try done;intros. rewrite -H. rifliad.
rewrite !inE.  rifliad. by rewrite H0 /=. rewrite  H1 /=. lia. by rewrite H0 H1 /= H.
rewrite !inE. rifliad. by rewrite H0.  rewrite H1 /=. lia. rewrite H0 H1 /= match_n big_map -H.*)



Lemma step_ptcps : forall g l g',  step g l g' -> (locked_pred rec_pred g) -> (ptcp_from l.1 \in ptcps_of_g g) && (ptcp_to l.1 \in ptcps_of_g  g).
Proof. move => g l g'. elim;rewrite /=;try done;intros.
rewrite !inE /=. lia. 
rewrite !inE. lia. have : locked_pred rec_pred g1 by cc. move/H0/andP=>[]. rewrite !inE. move=>-> ->. rewrite orbC /=. rewrite orbC /=. done. 
have : all (locked_pred rec_pred) gs'. to_goal. apply :  all_ForallG. cc. apply Build_CHint in H0.  cc. cc.
move : H0. rewrite !inE.
move : H0. rewrite big_map. intros. rewrite !inE. lia.  apply H0 in H2. rewrite !inE. destruct (andP H2). rewrite H3 H4. lia. 
rewrite !big_map. rewrite !inE. destruct (((ptcp_from l0.1 == ptcp_from a)) || (ptcp_from l0.1 == ptcp_to a) ) eqn:Heqn. 
suff : (ptcp_from l0.1 \in \bigcup_(j <- gs) j) /\ (ptcp_to l0.1 \in \bigcup_(j <- gs) j).
move=>[] -> ->. lia.
move : H1. move/Forall_forall=>Hall. specialize Hall with (nth (GEnd,GEnd) (zip gs gs') 0). rewrite nth_zip in Hall;eauto. simpl in Hall. have : (nth GEnd gs 0, nth GEnd gs' 0) \in zip gs gs'. rewrite -nth_zip. apply mem_nth. rewrite size_zip minnE /= H nat_fact. rewrite -H.   lia. done. move/Hall=>Hall'. destruct (andP H3). have : (locked_pred (predI project_pred size_pred) (nth GEnd gs 0)) && bound_i i (nth GEnd gs 0).
destruct (andP H1). apply/andP. split. apply (allP H6). apply/mem_nth. destruct (andP H1). destruct (andP H7). done.  apply (allP H4). apply/mem_nth. destruct (andP H5). done. move/Hall'. move/andP=>[];intros.  split. 

apply/bigfcupP. exists (nth GEnd gs 0). rewrite andbC /= mem_nth //=. destruct (andP H1). destruct (andP H5). done. done. 
apply/bigfcupP. exists (nth GEnd gs 0). rewrite andbC /=. apply/mem_nth.  destruct (andP H1). destruct (andP H5). done.  done.

suff : (ptcp_from l0.1 \in \bigcup_(j <- gs) j) /\ (ptcp_to l0.1 \in \bigcup_(j <- gs) j).
move=>[] -> ->. lia.
move : H1. move/Forall_forall=>Hall. specialize Hall with (nth (GEnd,GEnd) (zip gs gs') 0). rewrite nth_zip in Hall;eauto. simpl in Hall. have : (nth GEnd gs 0, nth GEnd gs' 0) \in zip gs gs'. rewrite -nth_zip. apply mem_nth. rewrite size_zip minnE /= H nat_fact. rewrite -H.   lia. done. move/Hall=>Hall'. destruct (andP H3). have : (locked_pred (predI project_pred size_pred) (nth GEnd gs 0)) && bound_i i (nth GEnd gs 0).
destruct (andP H1). apply/andP. split. apply (allP H6). apply/mem_nth. destruct (andP H1). destruct (andP H7). done.  apply (allP H4). apply/mem_nth. destruct (andP H5). done. move/Hall'. move/andP=>[];intros.  split. 

apply/bigfcupP. exists (nth GEnd gs 0). rewrite andbC /= mem_nth //=. destruct (andP H1). destruct (andP H5). done. done. 
apply/bigfcupP. exists (nth GEnd gs 0). rewrite andbC /=. apply/mem_nth.  destruct (andP H1). destruct (andP H5). done.  done.

rewrite !ptcps_substitution in H0. apply H0. destruct (andP H1).  apply/andP. split.
move : H2. rewrite !traverse_split. move/andP=>[];intros. apply/andP. split. apply traverse_project_pred_unf.


rewrite bigfcupP.
 rewrite !Heqn. 
move : H0. move/andP. destruct (and3P H0).  Check and3P. destruct gs. done. rewrite !inE. lia. move : H1. rewrite notin_label. rewrite !inE.  move/andP=>[]. rewrite neg_sym.  move/negbTE. move=> HH. rewrite neg_sym. move/negbTE => HH2. rewrite HH HH2.  apply/andP.
 split. apply/orP. apply H0 in H2. destruct (andP H2). auto. destruct (andP (H0 H2)). rewrite H3.  lia. 
 destruct gs. simpl in H3. lia.  move : H2. rewrite notin_label. rewrite !inE.  move/andP=>[]. rewrite neg_sym.  move/negbTE. move=> HH. rewrite neg_sym. move/negbTE => HH2. rewrite HH HH2. apply/andP.
 split.
apply/orP. right. 
move : H1. 


apply/orP. right. 
move : H1. move/Forall_forall=>Hall. specialize Hall with (nth (GEnd,GEnd) (zip (g0::gs) gs') 0). rewrite nth_zip in Hall;eauto. simpl in Hall. have : (g0, nth GEnd gs' 0) \in zip (g0 :: gs) gs'.  have : g0 = nth GEnd (g0::gs) 0. done. move=>->. rewrite -nth_zip. apply mem_nth. simpl in H. rewrite size_zip minnE /= H nat_fact. rewrite -H.   lia. done. move/Hall=>Hall'. simpl in H3. destruct (andP H3). apply Hall' in H1. destruct (andP H1). done. Search _ (ptcps_of_g (substitution _ _ _)). 


eauto. simpl in H3. done. have :  (g0, nth GEnd gs' 0) \in zip (g0 :: gs) gs'.  apply : (andP Hall).

right. apply/bigfcupP.

 specialize Hall with (nth (GEnd,GEnd) (zip gs gs')).
done. 

 
(*Lemma step_project_Sd_msg : forall g a u g', locked_pred (action_pred) g ->step g (a,inl u) g' -> project g (ptcp_from a) = EMsg Sd (action_ch a) u (project g' (ptcp_from a)).
Proof. move => g a u g' H0 H. remember (a,inl u). move : H H0 Heqp. elim.
- move => a0 u0 g0 H []. intros. subst. rewrite /=. simpl in H. rifliad. move : H0. rewrite eqxx. lia. 
- move => a0 n d gs H H0 []. intros. subst. rewrite /=. simpl in H0. rifliad.
- intros. subst. rewrite /=. simpl in H2. rifliad.  f_equal. simpl in H1.
  

  3 : { apply: H0;auto.  apply : step_action. eauto. simpl. eauto. } f_equal. simpl in H1. rewrite /=. rifliad.  
 * rewrite notin_label in H1. rewrite (eqP H3) in H1.  lia. move : H3. rewrite ( move/eqP. lia.
 * f_equal.
Lemma step_project_aux2 : forall g l g' g0 g'0 p, step g l g' -> step g0 l g'0 -> project g p = project g0 p -> project g' p = project g'0 p.
Proof. 
move => g l g' g0 g0' p. 
 - elim. clear g l g'. move => a u g H. remember (a,inl u).  move : H p g Heqp0. elim.
  * intros. inversion Heqp0. subst. move : H. rewrite /=.  repeat ifliad; by case. 
  * intros. inversion Heqp0.
  * intros. rewrite Heqp0 in H1.  simpl in H1. rewrite notin_label in H1. move : H2.  rewrite /=. repeat ifliad.
   **  move : H2. rewrite /=.  repeat ifliad. case. by case. lia.
   ** simpl in H1.  move : H1. rewrite notin_label. rewrite /.
      2 : { ifliad. 2 : { move/H0=>->;auto. by  rewrite /= H2 H3. } rewrite /=. repeat ifliad. case. intros. rewrite -(eqP H3) in H1. move : H1. 
  rewrite /=. rewrite notin_label. lia. move : H1. rewrite /= notin_label. intros. f_equal. apply : H0. done. rewrite /=. repeat ifliad. } 
  
Set Printing Coercions. Set Printing All. rewrite inE. subst. lia. ifliad. rewrite rewrite {2}H0. //=. rewrite H0;auto.  apply H0 in Heqp0.
   ** by case.
   ** lia.

-
intros. move : H0. rewrite /=. ifliad. intros. inversion H;subst. simpl in H0.


Lemma step_project_aux2 : forall g l g' g0 g'0 S, step g l g' -> step g0 l g'0 -> projmap S g == projmap S g0 -> projmap S g' == projmap S g'0.
Proof. 
move => g l g' g0 g0' S. elim. 
intros. inversion H;subst. simpl in H0.*)


Lemma step_project_aux : forall gs l gs' S , Forall2 (fun g g' => step g l g') gs gs'  -> all_eq_F (projmap S) gs (nth GEnd gs 0) ->  all_eq_F (projmap S) gs' (nth GEnd gs' 0).
Proof. move => gs l gs' S. 

(*remember (nth GEnd gs n).  remember (nth GEnd gs' n). move => Hsize H. *)
(*elim : H n Heqg Heqg0 Hsize. done. *)
elim. done. move => x y l0 l' H.  intros. 
inversion H0. subst. by rewrite /= eqxx. 
subst. rewrite (@all_eq_F_end _ _ _ _ (nth GEnd (y0::l'0) 0)).  done.  rewrite !inE eqxx. lia. rewrite !inE eqxx. lia.
rewrite all_eq_F_cons. apply/andP. split. 
simpl. move : H2. rewrite (@all_eq_F_end2 _ _ _ _ _ (nth GEnd (x0::l1) 0)) //=.
move/andP=>[];intros. clear b. rewrite eq_sym.
apply : step_project_aux2. all : eauto. rewrite inE eqxx. lia. rewrite !inE eqxx. lia.

apply H1. 
 move : H2. rewrite (@all_eq_F_end2 _ _ _ _ _ (nth GEnd (x0::l1) 0)). rewrite all_eq_F_cons //= eqxx. lia.
apply/mem_nth. done. 
rewrite inE mem_nth //=. lia.
Qed.

Lemma in_action_from_fset : forall a, ptcp_from a \in (ptcps_of_act a).
Proof. intros. rewrite !inE eqxx //=. Qed.

Lemma in_action_to_fset : forall a, ptcp_to a \in (ptcps_of_act a).
Proof. intros. rewrite !inE eqxx orbC //=. Qed.

Hint Resolve in_action_from_fset in_action_to_fset.

(*Lemma step_project2 : forall gs l gs' S , Forall2 (fun g g' => step g l g') gs gs'  -> all (locked_pred (project_pred S)) gs -> 
 all (locked_pred (project_pred S)) gs'.
Proof.
move => gs l gs' S. elim. done. intros.
rewrite /=. simpl in H2. destruct (andP H2). apply/andP. split.*)

Lemma traverse_P : forall g P, locked_pred P g -> P g.
Proof. elim;rewrite /= ;try lia. Qed.

Lemma step_project : forall g l g' S,step g l g'  ->locked_pred (project_pred S) g -> locked_pred (project_pred S) g'.  
Proof.
move => g l g' S. elim; intros. all : try (simpl in *;lia).
- simpl in H0. destruct (andP H0). apply (allP H2). apply/mem_nth. done.
move : H0. move/Forall2_forall=>[];intros. simpl.  apply/andP. split. 2 : { apply/allP=>g'' Hin.  
move : Hin. move/nthP=>Hnth. specialize Hnth with GEnd. destruct Hnth. rewrite -H3. apply : b. apply In2_nth2 with (d:=GEnd). rewrite a0 H0 //=. done.  
simpl in H2. destruct (andP H2). apply (allP H5). apply/mem_nth. rewrite a0 //=. } 
apply : step_project_aux. eauto. simpl in H2. destruct (andP H2). done.
- apply H. apply traverse_project_pred_unf;auto. 
Qed.

Lemma step_idemp : forall g l g' (S : ptcps), step g l g' -> l.1 `<=` S -> [fmap x : S => project g (val x)] = [fmap x : S => project g' (val x)] <-> [fmap x : l.1 => project g (val x)] = [fmap x : l.1 => project g' (val x)].
Proof.
move => g l g' S. elim;intros.
-  split;intros. 
* apply/fmapP=>k. rewrite !mapf_if. ifliad.    move : H. simpl. move/fdisjointP.  rewrite /=. move=>Hdis.  
   ifliad.  specialize Hdis with k. rewrite H0 in Hdis. exfalso. apply/negP. apply Hdis. rewrite (eqP H) //=. done. 
 * apply/fmapP=>k. move : H. move/fmapP=>Hmap. specialize Hmap with k. move : Hmap. rewrite !mapf_if. ifliad. ifliad. f_equal. move : H. move/fdisjointP.  rewrite /=. move=>Hdis.  
   ifliad.  specialize Hdis with k. rewrite H0 in Hdis. exfalso. apply/negP. apply Hdis. rewrite (eqP H) //=. done. 
   ifliad. specialize Hdis with k. rewrite H0 in Hdis. exfalso. apply/negP. apply Hdis. rewrite (eqP H1). done. done.
-  apply/fmapP=>k. rewrite !mapf_if. iflia;try done.   move : H1. move/fdisjointP=>Hdis.  f_equal. rewrite /=. 
   specialize Hdis with k. iflia.
 *  rewrite H2 in Hdis. exfalso. apply : negP. apply : Hdis.  rewrite !inE /= H1 //=. done. 
 *  iflia. rewrite H2 in Hdis. exfalso. apply : negP. apply : Hdis.  rewrite !inE /= H3  orbC //=. done. 
 *  rewrite match_n. apply props_project in H0. simpl in H0.   destruct (andP H0). move : H4.  rewrite /project_pred_aux. rewrite /=. move/allP=>Hall. simpl in Hall. have : pro


ve => HH.  apply Hdis in HH. move/Hdis.
rewrite /=. Set Printing All. Check gType_EqType. Check False. Check eq_refl.  Check (Equality.sort _ = test :> Type). Check (@eq_refl (Equality.sort gType _). Check (@Equality.Pack nat  : Equality.type). apply : (equivP eqP). split. 2 : {  intros. eapply H0.  eauto. intros. eapply H0.  Set Printing All. apply : H0.  Search _ (reflect _ _ -> (_ -> _)). have : [fmap] = [fmap]. Set Printing All. 

have :   forall (t : Choice.type) (T : eqType), @eq (@finmap_of t T (Phant (forall _ : Choice.sort t, T))) (@fmap0 t T) (@fmap0 t T).
apply/eqP.
intros. apply/eqP. apply (elimT eqP). Check gType_eqType.  Set Printing All.  Unset Printing Notations. apply eqP. fset_eqP. apply/fmap_eqP.

(*Lemma step_label : forall g l g', step g l g' -> EnvStep ([fmap x : l.1 => project g (val x)]) l ([fmap x : l.1 => project g' (val x)]).
Proof.
Admitted.*)
x



(*

intros. destruct (andP H2).  

have :  all (locked_pred project_pred) gs'.
apply/allP=> g''  /nthP=>Hnth. specialize Hnth with GEnd.  destruct Hnth. rewrite -H6. move : H0. move/Forall2_forall=>[];intros. 
apply : b. apply/In2_nth2. apply GEnd. rewrite a0.  done. done. apply (allP H4). apply/mem_nth. rewrite a0.  done.
move=>->. rewrite andbC /=. 
apply/step_project_aux. eauto. eauto.
Admitted.*)





Ltac uis H := punfold H;inversion H;subst;pclearbot.






Lemma Forall3_Forall2_mid : forall (A B C : Type) (l0 : seq A) (l1 : seq B) ( l2 : seq C) (P : A -> C -> Prop), Forall3 (fun a b c => P a c) l0 l1 l2 -> Forall2 P l0 l2.
Proof.
intros. elim : H;auto.
Qed.

Lemma Forall2_exists : forall (A B C: Type) (l0 : seq A) (l1 : seq B) (P : A -> B -> C -> Prop), Forall2 (fun a b => exists c, P a b c) l0 l1 -> exists cs, Forall3 P l0 l1 cs.
Proof.
intros. elim : H;auto. exists nil. done.
intros. destruct H1. destruct H. exists (x1::x0). auto. 
Qed. 

(*Lemma in_front : forall (p : ptcp) (d : env)  (H : p \in d), d = d.[p <- d.[H]].
Proof.
intros. apply/fmapP=>k.  rewrite fnd_set. iflia. 
rewrite -in_fnd. rewrite (eqP H0). done. done. 
Qed.*)

Lemma in_front : forall (p : ptcp) (d : env) e, d.[? p] = Some e -> d = d.[p <- e].
Proof. intros. apply/fmapP=>k. rewrite fnd_set. iflia. rewrite (eqP H0). done. done.
Qed.



(*Lemma setfC (f : env) k1 k2 v1 v2 : f.[k1 <- v1].[k2 <- v2] =
   if k2 == k1 then f.[k2 <- v2] else f.[k2 <- v2].[k1 <- v1].
Proof.
apply/fmapP => k. rewrite fnd_if !fnd_set.
have [[->|kNk2] [// <-|k2Nk1]] // := (altP (k =P k2), altP (k2 =P k1)).
by rewrite (negPf kNk2).
Qed.*)



Lemma fsub_split : forall (A: choiceType) (S0 S1 : {fset A}), S0 `<=` S1 -> S1 = S0 `|` (S1 `\` S0).
Proof.  intros. move : H. move/fsubset_in=>H. apply/fsetP=>k. rewrite !inE. destruct (k \in S0) eqn:Heqn. rewrite /=.  rewrite H //=. 
rewrite /=. done. 
Qed. 

Lemma proj_gmsg : forall (a : action) u g0 (S : {fset ptcp}) , a `<=` S -> [fmap x : S => project (GMsg a u g0) (val x)] = [fmap x : S => project g0 (val x)].[ptcp_from a <- project (GMsg a u g0) (ptcp_from a)].[ptcp_to a <- project (GMsg a u g0) (ptcp_to a)].
Proof.
intros. rewrite (fsub_split H). rewrite mapf_or. apply/fmapP=>k.  rewrite fnd_cat /domf. iflia. 
- rewrite !mapf; try lia.  rewrite !fnd_set. 
 iflia. move : H0. rewrite !inE. rewrite H1 /= orbC /=. done. 
 iflia. move : H0. rewrite !inE. rewrite H2 /=. done. 
 rewrite /= H1 H2. rewrite mapf. done. rewrite inE H0. lia. 
- rewrite mapf_if.  iflia. move : H1.  rewrite !inE.   move/orP=>[]. move/eqP=>->. intros. rewrite !fnd_set /ptcp_to /ptcp_from eqxx. iflia.  rewrite (eqP H1). done. done. move=>/eqP ->. rewrite !fnd_set /ptcp_from /ptcp_to eqxx. done. 
move : H1.  rewrite !inE. move/negbT.  rewrite negb_or. move/andP=>[];intros. rewrite !fnd_set. iflia. iflia. rewrite mapf2. done. move : H0. rewrite !inE negb_or a0 b /=. move=>->. lia.   
Qed.

Lemma proj_msg_same : forall (a : action) g0 (S : {fset ptcp}) , a  `<=` S -> [fmap x : S => project g0 (val x)] = [fmap x : S => project g0 (val x)].[ptcp_from a <- project g0 (ptcp_from a)].[ptcp_to a <- project g0 (ptcp_to a)].
Proof.
intros. rewrite (fsub_split H). rewrite mapf_or. apply/fmapP=>k.  rewrite fnd_cat /domf. iflia. 
- rewrite !mapf; try lia.  rewrite !fnd_set. 
 iflia. rewrite (eqP H1). done. 
 iflia. rewrite (eqP H2). done.  
 rewrite fnd_cat. rewrite /domf. iflia. rewrite mapf_if. iflia. done. 
- rewrite !fnd_set. iflia. rewrite mapf_if. iflia. rewrite (eqP H1). done. move : H2 H1. rewrite !inE. lia. 
  iflia. rewrite mapf_if. iflia. rewrite (eqP H2). done. move : H2 H3. rewrite !inE. lia. rewrite fnd_cat. iflia. 
  rewrite !mapf_if. iflia. iflia. move : H4 H1 H2. rewrite !inE. lia. done. rewrite !mapf_if. iflia. done. done.
Qed.



(*Lemma match_nth : forall (A : Type) (gs : seq A) (a : A) F, match gs with | [::] => a | b :: _ => F b end = nth a gs.
  end*)

Check seq_eq. Print seq_eq.
Lemma seq_eqP : forall (A : eqType) (l : seq A) n d, n < size l ->  seq_eq l -> nth d l 0 = nth d l n.
Proof. move => A. case. done. intros. simpl in H0. move : H0. move/allP=>Hall. apply/eqP. apply : Hall. apply (allP H0). elim;try done;intros.  destruct n0; destruct n1;try done. simpl. erewrite <- H. rewrite /=. destruct n;rewrite /=;try done. rewrite -H //=.
Lemma project_pred_aux_nth : forall gs a k n d, n < size gs -> k \notin (ptcps_of_act a) -> project_pred_aux a gs -> project (nth GEnd gs 0) k = project (nth d gs n) k.
Proof. intros. move : H1. rewrite /project_pred_aux. 




Lemma step_weaken : forall d0 l d1 d, EnvStep d0 l d1 -> EnvStep (d0 + d) l (d1 + d).
Proof. Admitted.
Check Estep.

(*needed*)
Lemma step_to_Estep_from : forall g (l : label) g',  step g l g' -> props g -> Linear g  -> 
Estep (project g (ptcp_from l.1)) (Sd,action_ch l.1,l.2) (project g' (ptcp_from l.1)).
Proof. Admitted.

Lemma step_to_Estep_to : forall g (l : label) g',  step g l g' -> props g -> Linear g  -> 
Estep (project g (ptcp_to l.1)) (Rd,action_ch l.1,l.2) (project g' (ptcp_to l.1)).
Proof. Admitted.

(*needed*)
Lemma map_supp_a : forall (A : Type) (a : action) (F : ptcp -> A), [fmap x : a => F (val x)] = 
                                                             [fmap].[(ptcp_from a) <- F (ptcp_from a)].[ptcp_to a <- F (ptcp_to a)].
Proof. Admitted.

Lemma step_to_Estep : forall g (l : label) g' (S : {fset ptcp}), l.1 `<=` S ->  
 step g l g' -> props g -> Linear g  ->
 EnvStep ([fmap x : S => project g (val x)]) l ([fmap x : S => project g' (val x)]).
Proof.
move => g l g' S H H2.  intros. rewrite (fsub_split H). rewrite mapf_or. rewrite mapf_or.
rewrite (@step_idemp g l g' (S `\` l.1));auto.   apply : step_weaken.  rewrite !map_supp_a. constructor.  
apply step_to_Estep_from;auto.
apply step_to_Estep_to;auto.
apply/fdisjointP. intros. rewrite inE H3 //=.  
Qed.

















(*************Everything from here on is not used*******)
destruct l. constructor.  _ _ (project g)).  Set Printing All. constructor. 
have : [disjoint l.1 & (S `\` l.1)].  Search _ (_ `\`_). have : (l.1 `\` (S `\` l.1)). apply fsetDK in H. Check fsetDidPl.  move : H. move/fsetDidPl.  in H.   Search _ (_ `\` (_ `\` _)). 
  apply step_weaken. Set Printing All. elim : H2 H.
- intros.  simpl in H. rewrite proj_gmsg. apply fsub_split in H as H'. rewrite {2}(@proj_msg_same a).
  constructor; rewrite /= eqxx. done. have : ptcp_to a == ptcp_from a = false. apply props_action in H0. rewrite /= in H0. destruct (andP H0).  apply negbTE. move : H2. rewrite neg_sym.  done.  move=>->. constructor. done. done. 
- admit.
- admit.
- admit.
Admitted.



Lemma step_to_Estep : forall g l g' Δ,  step g l g' -> props g -> allproj g Δ -> Linear g -> exists Δ', allproj g' Δ' /\ EnvStep Δ l Δ' .
Proof. 
move => g l g' Δ H. elim : H Δ.
- intros. move : H1 => Hlinear. inversion H0. subst. exists Δ0.  split;auto. 
   rewrite -{2}(map_same H7)  -{2}(map_same H6). auto. 
- intros. move : H2 => Hlinear. punfold H1. inversion H1. punfold H0. inversion H0. subst. pclearbot. exists (nth [fmap] Δs n).  split. 
 * apply index_Forall2. done. 
 * apply (Forall2_mono H5). intros. inversion H3. done. done. 
 * have : (nth [fmap] Δs n).[? p0] = Some (nth SEEnd es0 n).  apply index_Forall2 with (l0:=Δs)(l1:= es0);auto.
   rewrite -(size_Forall2 H5) //=. intros.

   have : (nth [fmap] Δs n).[? p1] = Some (nth SEEnd es1 n).  apply index_Forall2 with (l0:=Δs)(l1:= es1);auto.
   rewrite -(size_Forall2 H5) //=. intros.  (*up until now just setup*)
   
   rewrite -(map_same x0). rewrite -(setf_rem1 (nth [fmap] Δs n) p1 (nth SEEnd es1 n)). (*pull p0 binding out in front*)
   rewrite -(map_same x). rewrite -(setf_rem1 (nth [fmap] Δs n) p0 (nth SEEnd es0 n)).  (*pull p1 binding out in front*)

   rewrite remf1_set. rewrite eq_sym. simpl in H12. move : H12. move/eqP. rewrite -eqbF_neg. move/eqP. move=>->. (*collect map restrictions before new bindings*)

   have : (((nth [fmap] Δs n).[~ p0]).[~ p1]) = Δ0. apply index_Forall;auto. by rewrite -(size_Forall2 H5). move=>->. (*replace restricted map with Δ0*)

   have : n < size es0 by  rewrite -(size_Forall2 H6) -(size_Forall2 H5). 
   have : n < size es1 by rewrite -(size_Forall2 H7) -(size_Forall2 H5). intros.  eauto. (*Now we reduce environments*)
- intros. move : H5 => Hlinear.  punfold H2. inversion H2. pclearbot. punfold H3. inversion H3. subst. inversion H13;try done. 
  punfold H4. inversion H4. subst. pclearbot. Check (linear_sgmsg Hlinear).
   move : (H0 _ H9 H5 H8 (linear_sgmsg Hlinear)) => [] Δ' [] Hp' Step'.
 clear H0. simpl in H1,H7. clear H2. clear H8. clear H13. (*Setup*)
   move : (EnvStepdom Step')=> Hdom. 
   
   have : p0 \in Δ'. rewrite inE -Hdom.  apply : in_dom. eauto. 
   have : p1 \in Δ'. rewrite inE -Hdom.  apply : in_dom. eauto. intros. 
   move : (in_fnd x). move : (in_fnd x0). intros. (*Show Δ' is defined for p0 and p1*)
   exists (Δ'.[p0 <- SEMsg Sd c u Δ'.[x0]].[p1 <- SEMsg Rd c u Δ'.[x]]). split;auto. (*auto handles projection goal*)
   destruct (p0 \notin l0) eqn:Heqn.
   * rewrite -(EnvStep_same Step' Heqn) in in_fnd. rewrite -(EnvStep_same Step' H1) in in_fnd0.
     rewrite in_fnd in H15. rewrite in_fnd0 in H16. inversion H15. inversion H16. subst. 
     apply EnvStep_weaken;auto.
     apply EnvStep_weaken;auto.
   *  move : (negbFE Heqn). rewrite in_label. move/orP=>Hor. 
      intros. subst.  rewrite -(EnvStep_same Step' H1) in in_fnd0. rewrite in_fnd0 in H16. inversion H16.
       apply EnvStep_weaken;auto.  apply : EnvStep_async;eauto; try solve [ apply : non_refl_label; eauto; inversion H4; pclearbot; done].
      *** have : step (SGMsg (Action p0 p1 c) u g1) l0 (SGMsg (Action p0 p1 c) u g2) by auto.  move=>Hstep. 
          have : non_zero (SGMsg (Action p0 p1 c) u g1). pfold. done. intros.
          move : (step_tr Hstep x1)=>[] s [] Htr Hf. have : exists s', s = (Action p0 p1 c)::s'. inversion Htr. destruct s;done. subst. destruct (split_list aa).
       **** subst. destruct s; last (simpl in H0; inversion H0; destruct s;done). inversion H0. have : p1 \in l0. 
            rewrite /in_mem /= /pred_of_label /to_action -H6. 
            rewrite /= eqxx orbC. done. intros. rewrite x2 in H1. done. 
       **** destruct H2,H2. subst. rewrite -cat_cons in H0. apply last_eq in H0. destruct H0. exists x2. rewrite H0. done. 
     
       ****  move=>[]s' Hs'. rewrite Hs' in Htr. rewrite -[_ ++ _]cat0s in Htr. apply Hlinear in Htr as Htr'.
             destruct (c == (action_to_ch l0.1)) eqn:Heqnc; last by (move : Heqnc=> /eqP).
             have : same_ch (Action p0 p1 c) l0.1. rewrite (eqP Heqnc). destruct (l0.1). by rewrite /same_ch /= eqxx.
             move/Htr'=> [] Hindep Houtdep. intros. rewrite Hs' in Hf. move : (ch_diff Hlinear Htr Hf). 
             move/List.Forall_forall=>Hf'. suff : ~~(same_ch (Action p0 p1 c) l0.1). rewrite /same_ch /=. move/eqP. 
             move => Hn Hn'. rewrite Hn' in Hn. destruct l0. simpl in Hn. destruct a. simpl in Hn. done.
             apply : Hf'. simpl. auto. destruct (p0 \in l0) eqn:Heqb. done. done. 
- intros. move : H5 => Hlinear.  uis H2. uis H3. 
  have : forall Δ, Forall2
         (fun g0 g2 : sgType =>
          non_refl g0 ->
          co_allproj g0 Δ ->
          non_zero g0 ->
          Linear g0 -> exists Δ' : env, co_allproj g2 Δ' /\ EnvStep Δ l0 Δ') gs gs'.
  intros. apply/Forall2_forall.  
  move : H0. move/Forall2_forall=>[]->Hf. split;auto. intros. eauto.
  move=> H0'.

  have : Forall3
         (fun d g0 g2 => exists Δ' : env, co_allproj g2 Δ' /\ EnvStep d l0 Δ') Δs gs gs'.
  apply/Forall3_forall.  rewrite -(size_Forall2 H0).   rewrite (size_Forall2 H9). split;auto.
  intros. move : H0. move/Forall2_forall=>[] Hsize Hff. apply : Hff. apply : In3_In2_r. apply : H5.
  move : H8. move/List.Forall_forall=>Hf8. suff : upaco1 non_reflF bot1 b. intros. pclearbot. done.
  apply Hf8.  apply : In2_In_l. apply : In3_In2_r. apply : H5. 
  move : H9. move/Forall2_forall=>[] _ Hf9. suff : upaco2 co_allprojF bot2 b a. intros. inversion x;try done. 
  apply Hf9. apply/In2_swap.  apply : In3_In2_l. apply : H5. 
  uis H4. 
  move : H14. move/List.Forall_forall=> Hf14. suff : upaco1 non_zeroF bot1 b. intros. by pclearbot. 
  apply Hf14. apply/In2_In_r. apply/In3_In2_l. apply : H5.
  have : In b gs. apply : In2_In_r. apply : In3_In2_l. eauto. intros. 
  move : (@linear_branch _ _ Hlinear). move/List.Forall_forall=>Hfl. apply Hfl. done. move/Forall3_Forall2_mid. move/Forall2_exists.
  move=> [] ds Hfds. Check pmap.
  have : Forall2 (fun (d : env) e => d.[? p0] = Some e) ds (pmap (fun (d : env) => d.[? p0]) ds).
  apply/Forall2_forall. rewrite size_pmap. split. rewrite -count_predT. Search _ (count _ _ = count _ _). Check count.  apply/eq_in_count.

  Check count.
Search _ (size (pmap _ _)). 
  
 (List.Forall_forall (linear_branch Hlinear)).
  apply Hf9. apply/In2_swap.  apply : In3_In2_l. apply : H5. 
  
  move : 
  have : exists ds, Forall2
          (fun g d => co_allproj g d) gs' ds.  
  admit.


  exists (Δ0.[p0 <- SEBranch Sd c  es0].[p1 <- SEBranch Rd c es1]). split.
 * pfold.  econstructor. 2: { apply H10. } apply/Forall2_forall.  split. apply  :size_Forall2. apply : H9. move=> []. intros. Check Forall2_forall. apply  eauto.
  have : Forall (fun g => (forall Δ, exists Δ', co_allproj g Δ' /\ EnvStep Δ l0 Δ')) gs'. 
  apply/List.Forall_forall. intros. move : H0. move/[dup]. move=>Hfor. move/Forall2_forall=>Hf. 
  apply (@In_nth _ _ _ SGEnd) in H5. destruct H5,H0.  rewrite H0. 
  apply : Hf. apply : (@In2_nth2 _ _ gs gs' SGEnd SGEnd). rewrite (size_Forall2 Hfor). done. apply : size_Forall2. apply : Hfor. move : H8. move/List.Forall_forall=>Hf'. suff: upaco1 non_reflF bot1 (nth SGEnd gs x0). intros.  pclearbot. done. 
 apply : Hf'.  apply : In_nth2. rewrite (size_Forall2 Hfor). done. 
 move : H9. move/Forall2_forall=>Hf. suff: upaco2 co_allprojF bot2 (nth SGEnd gs x0) Δ. intros.  pclearbot. inversion x1. done. done. 
 apply : Hf.  apply : In_nth2. rewrite (size_Forall2 Hfor). done. 
intros.
  move : H0. move/Forall2_forall=>Hf.
  apply Forall2_forall in H0.
  punfold H4. inversion H4. subst. pclearbot. 
   move : (H0 _ H9 H5 H8 (linear_sgmsg Hlinear)) => [] Δ' [] Hp' Step'.
 clear H0. simpl in H1,H7. clear H2. clear H8. clear H13. (*Setup*)
   move : (EnvStepdom Step')=> Hdom. 
   
   have : p0 \in Δ'. rewrite inE -Hdom.  apply : in_dom. eauto. 
   have : p1 \in Δ'. rewrite inE -Hdom.  apply : in_dom. eauto. intros. 
   move : (in_fnd x). move : (in_fnd x0). intros. (*Show Δ' is defined for p0 and p1*)
   exists (Δ'.[p0 <- SEMsg Sd c u Δ'.[x0]].[p1 <- SEMsg Rd c u Δ'.[x]]). split;auto. (*auto handles projection goal*)
   destruct (p0 \notin l0) eqn:Heqn.
   * rewrite -(EnvStep_same Step' Heqn) in in_fnd. rewrite -(EnvStep_same Step' H1) in in_fnd0.
     rewrite in_fnd in H15. rewrite in_fnd0 in H16. inversion H15. inversion H16. subst. 
     apply EnvStep_weaken;auto.
     apply EnvStep_weaken;auto.
   *  move : (negbFE Heqn). rewrite in_label. move/orP=>Hor. 
      intros. subst.  rewrite -(EnvStep_same Step' H1) in in_fnd0. rewrite in_fnd0 in H16. inversion H16.
       apply EnvStep_weaken;auto.  apply : EnvStep_async;eauto; try solve [ apply : non_refl_label; eauto; inversion H4; pclearbot; done].
      *** have : step (SGMsg (Action p0 p1 c) u g1) l0 (SGMsg (Action p0 p1 c) u g2) by auto.  move=>Hstep. 
          have : non_zero (SGMsg (Action p0 p1 c) u g1). pfold. done. intros.
          move : (step_tr Hstep x1)=>[] s [] Htr Hf. have : exists s', s = (Action p0 p1 c)::s'. inversion Htr. destruct s;done. subst. destruct (split_list aa).
       **** subst. destruct s; last (simpl in H0; inversion H0; destruct s;done). inversion H0. have : p1 \in l0. 
            rewrite /in_mem /= /pred_of_label /to_action -H6. 
            rewrite /= eqxx orbC. done. intros. rewrite x2 in H1. done. 
       **** destruct H2,H2. subst. rewrite -cat_cons in H0. apply last_eq in H0. destruct H0. exists x2. rewrite H0. done. 
     
       ****  move=>[]s' Hs'. rewrite Hs' in Htr. rewrite -[_ ++ _]cat0s in Htr. apply Hlinear in Htr as Htr'.
             destruct (c == (action_to_ch l0.1)) eqn:Heqnc; last by (move : Heqnc=> /eqP).
             have : same_ch (Action p0 p1 c) l0.1. rewrite (eqP Heqnc). destruct (l0.1). by rewrite /same_ch /= eqxx.
             move/Htr'=> [] Hindep Houtdep. intros. rewrite Hs' in Hf. move : (ch_diff Hlinear Htr Hf). 
             move/List.Forall_forall=>Hf'. suff : ~~(same_ch (Action p0 p1 c) l0.1). rewrite /same_ch /=. move/eqP. 
             move => Hn Hn'. rewrite Hn' in Hn. destruct l0. simpl in Hn. destruct a. simpl in Hn. done.
             apply : Hf'. simpl. auto. destruct (p0 \in l0) eqn:Heqb. done. done. 

intros.
Admitted.

























(*Not used from this point on*)

Definition is_full_proj (d : env) g (P : ptcp -> Prop) := 
(forall p e, P p -> co_proj g p e -> d.[? p] = Some e) /\ (forall p, ~ P p -> d.[? p] = None).

Inductive rec_red : seType -> (dir * ch * (value + nat)) -> seType -> Prop :=
| rr_msg c v e0  : rec_red (SEMsg Rd c v e0) (c, inl v) e0
| rr_eb n es c : n < size es -> rec_red (SEBranch c es) (c, inr n) (nth SEEnd es n).
Hint Constructors rec_red.

Inductive send_red : seType ->  (ch * (value + nat))  -> seType -> Prop :=
| sr_msg c v e0  : send_red (SEMsg Sd c v e0) (c, inl v) e0
| sr_msg0 c c' v e0 e0' l ann : send_red e0 l e0' ->  c <> c' -> send_red (SEMsg Sd c v e0) (c', ann) (SEMsg Sd c v e0')
| sr_eb n es c  : n < size es -> send_red (SEBranch Sd c es) (c, inr n) (nth SEEnd es n)
| sr_eb0 es0 es1 c c' ann : Forall2 (fun e0 e1 => send_red e0 (c',ann) e1) es0 es1 -> c <> c' ->  send_red (SEBranch Sd c es0) (c',ann) (SEBranch Sd c es1).
Hint Constructors send_red.

(*Remove d'*)
Inductive ctx_red : env -> (action * (value + nat)) -> env -> Prop :=
| ctx_red_comm (d : env)  p0 p1 c e0 e0' e1 e1' ann : 
                 d.[? p0] = Some e0 -> d'.[? p0] = Some e0' ->  
                 d.[? p1] = Some e1 -> d'.[? p1] = Some e1'  -> 
                 send_red e0 (c, ann) e0' -> rec_red e1 (c,ann) e1' -> 
                 (forall p, p \notin [:: p0;p1] ->  d.[? p] = d'.[? p]) ->
                 ctx_red d (Action p0 p1 c, ann) d'.



Lemma end_no_ptcp : forall p,  ~ part_of SGEnd p.
Proof.
intros. move => H. inversion H.
Qed.





(

Lemma ptcp_in_action : forall p a,  p \in ptcp_of_act a = in_action p a.
Proof.
intros. case : a. intros. by  rewrite /= !inE.
Qed.*)


Lemma msg_cont_proj : forall a p u g e, (ptcp_from a) <> (ptcp_to a) -> co_proj (SGMsg a u g) p e -> exists e', (if p == (ptcp_from a) then e = SEMsg Sd (action_ch a) u e' else if p == (ptcp_to a) then e = SEMsg Rd (action_ch a) u e' else e = e')  /\ co_proj g p e'.
Proof.
intros.  punfold H0. inversion H0;subst.    
- rewrite /= eqxx. inversion H6. exists e0. split. done. auto. done.
- rewrite eqxx.  case : (eqVneq p p2) H6 H. move => ->. done. intros. inversion H6. eauto. done. 
- exists e. destruct a. simpl in H6. move : H6. move/negP.  rewrite negb_or. move/andP=>[]. rewrite -!eqbF_neg. move/eqP=>-> /eqP=> ->. 
  inversion H7. eauto. done.
- exists SEEnd. have : ~ in_action p a. move => H2. apply H1. auto. 
  destruct a. simpl. move/negP. rewrite negb_or. move /andP=>[].  rewrite -!eqbF_neg. move /eqP=>-> /eqP ->. 
  split;auto. pfold. apply cp_notin. move => H2. apply H1.  apply po_msg2. auto.  
Qed.

Lemma msg_cont_other : forall p p1 p2 c0 u g0 e_big, p1 <> p2 -> p \notin [:: p1; p2] -> co_proj (SGMsg (Action p1 p2 c0) u g0) p e_big ->  co_proj g0 p e_big.
Proof.
intros. have : ptcp_from (Action p2 p3 c0) <> ptcp_to (Action p2 p3 c0). done. intros.
move : (msg_cont_proj x H1)=> [] e'. move : H0. rewrite /= !inE negb_or. move/andP=>[]. rewrite -!eqbF_neg. repeat move/eqP=>->.
by move=> [] ->.
Qed.

Lemma part_of_from : forall p p2 c0 u g0 , part_of (SGMsg (Action p p2 c0) u g0) p.
Proof.
intros. constructor. by rewrite /= eqxx. 
Qed.


Lemma part_of_to : forall p p2 c0 u g0 , part_of (SGMsg (Action p p2 c0) u g0) p2.
Proof.
intros. constructor. by rewrite /= eqxx orbC. 
Qed.

Hint Resolve part_of_from part_of_to.


(*Fixpoint all_ind_g (P : action -> bool) g := 
match g with 
| GEnd => true 
| GMsg a u g0 => P a && all_ind_g P g0
| GBranch a gs => P a && all (all_ind_g P) gs 
| GRec g => all_ind_g P g
| GVar _ => true 
end.

Inductive all_g (R : (action -> Prop) -> sgType -> Prop) (P0 : action -> Prop) : sgType -> Prop :=
| all_end : all_g R P0 SGEnd
| all_msg a u g0 : R P0 g0 -> P0 a -> all_g R P0 (SGMsg a u g0)
| all_branch a gs : Forall (R P0) gs -> all_g R P0 (SGBranch a gs).*)





Lemma part_of_or : forall g p, (part_of g p) \/ (~ part_of g p).
Proof. 
Admitted.


Lemma non_refl_msg : forall p p2 c0 u g0, paco1 non_refl bot1 (SGMsg (Action p p2 c0) u g0) -> p <> p2.
Proof.
intros. punfold H. inversion H. subst. simpl in H2. done.
Qed.


Lemma sg_to_se : forall g l g' d d',  step g l g'  -> 
Coherent g -> is_full_proj d g (fun p => part_of g p) -> 
 is_full_proj d' g' (fun p => part_of g p) -> ctx_red d (label_change l) d'.
Proof.
move => g l g' d d'. elim/step_ind; intros; rewrite /=.
- unfold Coherent in H. destruct H,H2. case : a H H0 H1 H2 H3.  intros. move : (H2 p)  (H2 p2)=> [] ef Hf [] et Ht.
  have : ptcp_from (Action p p2 c0) <> (ptcp_to (Action p p2 c0)). punfold H3.  inversion H3. by simpl in*. intros. 
  move : (msg_cont_proj x Hf). rewrite /= eqxx. move => [] ef' [] Hef' Hprojef'.
  move : (msg_cont_proj x Ht). rewrite /= eqxx. have : p2 == p = false. simpl in x.  apply/eqP. 
  move => HH. apply x. subst. done. move=>->. move => [] et' [] Het' Hprojet. unfold is_full_proj in *.
  destruct H0,H1.  
  eapply ctx_red_comm with (e0:= ef)(e1:=et)(e0':= ef')(e1':=et');subst;auto.  
  rewrite /=.  intros.  move : (part_of_or (SGMsg (Action p p2 c0) u g0) p3)=>[ HH | HH].
 * move : (H2 p3)=> [] e_big eProj. erewrite H0. erewrite H1. f_equal. done. 
   apply : msg_cont_other. 2: { apply : H6. }. 
   apply : non_refl_msg. apply : H3.  apply eProj. done.  done.
 * intros.  rewrite H4 //= H5 //=. 
- unfold Coherent in H0. destruct H0, H3. case : a H H0 H1 H2 H3 H4.  intros. move : (H3 p)  (H3 p2)=> [] ef Hf [] et Ht.
  have : ptcp_from (Action p p2 c0) <> (ptcp_to (Action p p2 c0)). punfold H4.  inversion H4. by simpl in*. intros. 
  move : (msg_cont_proj x Hf). rewrite /= eqxx. move => [] ef' [] Hef' Hprojef'.
  move : (msg_cont_proj x Ht). rewrite /= eqxx. have : p2 == p = false. simpl in x.  apply/eqP. 
  move => HH. apply x. subst. done. move=>->. move => [] et' [] Het' Hprojet. unfold is_full_proj in *.
  destruct H0,H1.  
  eapply ctx_red_comm with (e0:= ef)(e1:=et)(e0':= ef')(e1':=et');subst;auto.  
  rewrite /=.  intros.  move : (part_of_or (SGMsg (Action p p2 c0) u g0) p3)=>[ HH | HH].
 * move : (H2 p3)=> [] e_big eProj. erewrite H0. erewrite H1. f_equal. done. 
   apply : msg_cont_other. 2: { apply : H6. }. 
   apply : non_refl_msg. apply : H3.  apply eProj. done.  done.
 * intros.  rewrite H4 //= H5 //=. 
Admitted.


Lemma Unroll_contractive : forall g gs, GUnroll g gs -> contractive g.
Proof.
move => g gs. unfold GUnroll. intros. punfold SH. UnUnU move : H. elim/SUnravel_ind2. induction H;auto. elim.

Lemma step_goal : forall g  gs gs' l,  step gs l gs'  -> GUnroll g gs -> exists g', GUnroll g' gs' /\ stepi g l g'.
Proof.
move => g g' gs gs'. elim. 
- intros. unfold GUnroll in H. punfold H. remember (mu_height g). elim : n  g Heqn H. 
 * intros. inversion H;subst. exists g1. split.  pfold. done. done. done. 
 * intros. inversion H0;subst. exists g1. split. done. done. 
  simpl in Heqn. inversion Heqn. pclearbot. punfold H1. rewrite -(@mu_height_subst g1 (GRec g1) 0) in H3.  move : (H _ H3 H1)=> [] g'' []. intros. exists g''. split. done.  apply GRI_rec. done.  Print contractive_i. done.
  intros. subst. pclearbot. apply H2. induction H. 
 * 
unfold GUnroll.  elim. 
- intros. punfold H. inversion H;subst. 
 * H0 H1. intros. induction H.  elim : H. 
- intros.
unfold GUnroll. intros. split. intros. induction H1. 
-
punfold H. elim : H.
- intros. inversion H.
- intros.
Lemma step_spec : forall gs l gs', step gs l gs' -> exists g g', GUnroll g gs /\ GUnroll g' gs' /\ step gs l gs'.


Lemma stepi_spec : forall g l g', stepi g l g' -> exists gs gs', GUnroll g gs /\ GUnroll g' gs' /\ step gs l gs'.
Proof.
move => g l g'.  elim. 
- intros. rewrite /GUnroll in H,H0.  punfold H. inversion H. subst. punfold H0.  apply/unroll_uniq. apply : H5. apply : H0. done. inversion H5;subst. 
intros. elim : H.
- intros.
(*Error in endpoint type, used mysort instead of value*)


Print ptcp.
Check obind. Check ESelect. Check EReceive. Check ERec. Check nth. Check map.
Fixpoint project n (g : gType) {struct g} :  endpoint :=
match g with 
| GEnd => EEnd
| GMsg (Action (Ptcp n0) (Ptcp n1) c) u g0 => if n0 == n then ESend c u (project n g0)
                                             else if n1 == n then EReceive c u (project n g0)
                                             else project n g0
| GBranch (Action (Ptcp n0) (Ptcp n1) c) gs =>if n0 == n then ESelect c (map (project n) gs)
                                             else if n1 == n then EBranch c (map (project  n) gs)
                                             else match gs with | nil => EEnd | g'::_ => project n g' end
| GVar n => EVar n
| GRec g0 => match project n g0 with 
            | EEnd => EEnd 
            | e0 => ERec e0
            end
end.
Locate flat_map.


Definition pid g := undup (ptcps_of_g g).
 Check filter.

Definition same_projection_aux n gs := exists e, Forall (fun g => project n g = e) gs.


Fixpoint Forall' {A : Type} (P : A -> Prop) l : Prop  :=
match l with 
| nil => True 
| a::l' => P a /\ (Forall' P l')
end.


Fixpoint same_proj g {struct g} :=
let fix proj_aux gs :=  
match gs with 
| nil => True 
| a::l' => same_proj a /\ (proj_aux l')
end in
match g with 
| GMsg _ _ g0 => same_proj g0
| GBranch a gs => (forall n, n \notin (ptcps_of_act a) -> exists e,  Forall' (fun g => project n g = e) gs) /\ proj_aux gs
| GRec g0 => same_proj g0
| _ => True
end.

Fixpoint acts_of_g g := 
match g with 
| GMsg a _ g0 => a::(acts_of_g g0)
| GBranch a gs => a::(flatten (map acts_of_g gs))
| GRec g => acts_of_g g 
| _ => nil
end.

Definition no_refl_action g := forall a, a \in (acts_of_g g) -> ptcp_from a != ptcp_to a.

Definition coherent g := no_refl_action g /\ same_proj g /\ (exists sg, GUnroll g sg /\ Linear sg). (*Maybe more requirements, boundness/contractiveness? No, that is implicit in the fact that g can be unrolled to sg*)

(*Next steps continue p.23*)

(*Not guarded co-recursive call, consequence of deletion in projection*)
(*CoFixpoint project (sg : sgType) (n : nat) :  seType :=
match sg with 
| SGEnd => SEEnd
| SGMsg (Action (Ptcp n0) (Ptcp n1) c) u g0 => if n0 == n then (SEMsg Sd c u (project g0 n))
                                              else if n1 == n then (SERec c u (project g0 n))
                                              else project g0 n
| _ => SBot
end.*)






















(*represent local type semantics using sets of local types and sets of queues*)


(*
Definition project2_forall (A B: Type) (R : A -> B -> Type) (l0 : seq A) (l1 : seq B) (H : Forall2 R l0 l1) :=
match H with
| Forall2_nil=> nil
| Forall2_cons _ G _ GS _ _ => G::GS
end.


Fixpoint G_of_step sg l sg'  (H : step sg l sg') : sgType  := 
match H with 
| GR1 a u _ => SGMsg a u SGEnd
| GR2 a n _ _ _ => SGBranch a nil
| GR3 a u _ _ _ H' _ => SGMsg a u (G_of_step H')
| GR4 a _ gs _ H' _  => SGBranch a (project2_forall H')
end.

Check stepG_ind.
 



Fixpoint trace_of_step sg l sg'  (H : step sg l sg') : seq (seq label) := 
match H with 
| GR1 a u _ => [::[::LU a u]]
| GR2 a n _ _ _ => [::[::LN a n]]
| GR3 a u _ _ _ H' _ => map (cons (LU a u)) (trace_of_step H')
| GR4 a _ gs _ _ _ _ _ H' _  => flatten (mkseq (fun i => map (cons (LN a i)) (trace_of_step (H' i))) (size gs))
end.

Fixpoint reduce (ls : seq label) (sg : sgType)  {struct ls} : option sgType :=
match sg,ls with 
| _,nil => Some sg
| SGMsg a u sg', (LU a' u')::nil => if (a == a') && (u == u') then Some sg' else None
| SGBranch a sgs, (LN a' n)::nil => if (a == a') then nth_error sgs n else None
| SGMsg a u sg', (LU a' u')::ls' => if (a == a') && (u == u') then match reduce ls' sg' with
                                                                  | Some sg'' => Some (SGMsg a u sg'')
                                                                  | None => None
                                                                 end
                                                             else None
| SGBranch a sgs, (LN a' n)::ls' => if a == a' then match nth_error sgs n with 
                                                   | Some sg' => match reduce ls' sg' with
                                                                 | Some sg'' => Some (SGBranch a (set_nth SGEnd sgs n sg''))
                                                                 | None => None
                                                                 end
                                                   |  None => None
                                                   end
                                              else None
| _,_ => None
end.
Check foldr.
Definition rreduce lls sg := foldr (fun t r => obind (reduce t) r  ) (Some sg) lls.

(*Fixpoint repeat_reduce lls sg :=
match lls with 
 | nil => Some sg
 | ls::lls' => match reduce ls sg with 
             | Some sg' => repeat_reduce lls' sg' 
             | None => None 
             end
end.*)

Definition wf_actions ls :=
match ls with
| nil => true 
| l::ls' => let receivers := map ptcp_to (belast l ls')
          in all (fun r => ~~(in_action r (last l ls'))) receivers
end.

Lemma wf_actions_cons : forall aa a,  ~~(in_action (ptcp_to a) (last a aa)) ->  wf_actions aa -> wf_actions (a::aa).
Proof.
elim. 
- move => a. rewrite /=. done. 
- move => a l IH a0.  rewrite /=. intros. apply/andP. split. done. done. 
Qed.


Definition wf_labels ls := wf_actions (map act_of_label ls).

Lemma wf_labels_cons : forall l0 l1 ls,  ptcp_to (act_of_label l0) \notin last l1 ls ->  wf_labels (l1::ls) -> wf_labels (l0::l1::ls).
Proof. Admitted.


Lemma step_reduce_aux : forall lls a u g , rreduce (map (fun ls => (LU a u) :: ls) lls) (SGMsg a u g) = omap (SGMsg a u) (rreduce lls g).
Proof. Admitted.

Lemma step_reduce_branch : forall lls a gs n d, n < size gs -> rreduce (map (cons (LN a n)) lls) (SGBranch a gs) = omap (fun g' => SGBranch a (set_nth d gs n g')) (rreduce lls (nth d gs n)).
Proof. Admitted.


Lemma nth_error_zip : forall (gs gs' : seq sgType) (P : sgType -> sgType -> Prop), (forall i g g',
       nth_error gs i = Some g ->
       nth_error gs' i = Some g' -> P g g')  -> Forall2 P gs gs'.
Proof. Admitted.

Lemma repeat_reduce_app :  forall lls0 lls1 sg, rreduce (lls0 ++ lls1) sg = obind (rreduce lls1) (rreduce lls0 sg).
Proof. Admitted.

Lemma step_reduce : forall sg l sg' (H : step sg l sg'), rreduce (trace_of_step H) sg = Some sg'.
Proof. 
move => sg l sg'. elim.
- intros. by rewrite /= !eqxx /=. 
- intros. by rewrite /= !eqxx /= e. 
- move => a u l0 g1 g2 s H i. rewrite /=.
 by rewrite step_reduce_aux H. 
- move => a l0 gs gs' d d' Heq Hstepd IHd Hstep IH H. rewrite /= /mkseq. 

  suff: (rreduce [seq LN a i :: y | i <- iota 0 (size gs), y <- trace_of_step (Hstep i)] (SGBranch a gs) = Some (SGBranch a gs')). 

 rewrite step_reduce_branch.
  elim : gs Heq Hstep IH. 
 * case : gs'; last done. move => _ Hstep Hrec. rewrite /=. done. 
 * move => a1 l1 IH. case : gs' IH ;first done.
   move => a2 l2 IH. case. intros.  rewrite /=. 
   rewrite repeat_reduce_app. rewrite step_reduce_branch.  
   move : (IH0 0). rewrite /=. move => ->. rewrite /=.
 move : (nth_error_zip IH). 
  clear IH. rewrite {1}/reduce_prop.  elim : gs gs' Heq Hstep. 
 * case; last done. rewrite /=. move => _ H. 
   rewrite /reduce_prop. move => _. exists nil. rewrite /=. split;auto. split;auto.
   move => ls. rewrite in_nil. done.
 * move => sg0 sgs0 IH []. rewrite /=.  done.
   move => sg1 sgs1. rewrite /=. case. move => Heq Hstep [] Hred_top Hred_rest. 
   rewrite /reduce_prop.
   intros.  move => Print List.Forall. rewrite /List.Forall.
 elim :  Search nth_error.


Definition reduce_prop l sg sg' := exists lls, repeat_reduce lls sg = Some sg' /\ all wf_labels lls /\ (forall ls, ls \in lls -> exists l' ls', ls = l'::ls' /\ last l' ls' = l).

Lemma step_reduce : forall sg l sg', step sg l sg' -> reduce_prop l sg sg'.
Proof. 
move => sg l sg'. elim.
- intros. exists ([::[::(LU a u)]]). rewrite /= !eqxx /=. split;auto. split;auto.
  move => ls. rewrite inE. move/eqP => [] ->. exists (LU a u). exists nil. auto.
- intros. exists ([::[::(LN a n)]]). rewrite /= eqxx /=. rewrite H. split; auto. split;auto.
  move => ls.  rewrite inE. move/eqP => [] ->. exists (LN a n). exists nil. auto.
- move => g1 l0 g2 a u H [] lls [] H1 [] H2 H3 H4. 
  exists (map (fun ls => (LU a u)::ls) lls). split.
 * rewrite step_reduce_aux. rewrite H1. done.   
 * split. 
  ** apply/allP. move => a_ls Hin. move : (mapP Hin)=> [] ls Hin2. 
     case : a_ls Hin. done. move => a0 ls' Hin. case. move => -> ->. 
     case : ls Hin2. done. move => a1 l1 Hin2. apply wf_labels_cons. rewrite /=. 
     move : (H3 _ Hin2) => [] l' [] ls'' [] [] -> -> ->. done. 
     apply/(allP H2). done.
  ** move => ls /mapP. move => [] ls' Hin'. case : (H3 _ Hin') => x [] ls'' [] ->. 
     exists (LU a u). exists (x::ls''). split;auto. 
- move => a l0 gs gs' Heq Hstep IH Hrec. move : (nth_error_zip IH). 
  clear IH. rewrite {1}/reduce_prop.  elim : gs gs' Heq Hstep. 
 * case; last done. rewrite /=. move => _ H. 
   rewrite /reduce_prop. move => _. exists nil. rewrite /=. split;auto. split;auto.
   move => ls. rewrite in_nil. done.
 * move => sg0 sgs0 IH []. rewrite /=.  done.
   move => sg1 sgs1. rewrite /=. case. move => Heq Hstep [] Hred_top Hred_rest. 
   rewrite /reduce_prop.
   intros.  move => Print List.Forall. rewrite /List.Forall.
 elim :  Search nth_error.


Lemma step_reduce : forall sg l sg', step sg l sg' -> exists lls, repeat_reduce lls sg = Some sg' /\ all wf_labels lls /\ (forall ls, ls \in lls -> exists l' ls', ls = l'::ls' /\ last l' ls' = l).  
Proof. 
move => sg l sg'. elim.
- intros. exists ([::[::(LU a u)]]). rewrite /= !eqxx /=. split;auto. split;auto.
  move => ls. rewrite inE. move/eqP => [] ->. exists (LU a u). exists nil. auto.
- intros. exists ([::[::(LN a n)]]). rewrite /= eqxx /=. rewrite H. split; auto. split;auto.
  move => ls.  rewrite inE. move/eqP => [] ->. exists (LN a n). exists nil. auto.
- move => g1 l0 g2 a u H [] lls [] H1 [] H2 H3 H4. 
  exists (map (fun ls => (LU a u)::ls) lls). split.
 * rewrite step_reduce_aux. rewrite H1. done.   
 * split. 
  ** apply/allP. move => a_ls Hin. move : (mapP Hin)=> [] ls Hin2. 
     case : a_ls Hin. done. move => a0 ls' Hin. case. move => -> ->. 
     case : ls Hin2. done. move => a1 l1 Hin2. apply wf_labels_cons. rewrite /=. 
     move : (H3 _ Hin2) => [] l' [] ls'' [] [] -> -> ->. done. 
     apply/(allP H2). done.
  ** move => ls /mapP. move => [] ls' Hin'. case : (H3 _ Hin') => x [] ls'' [] ->. 
     exists (LU a u). exists (x::ls''). split;auto. 
- move => a l0 gs gs' g g' Hstep IH Hrec. move : (nth_error_zip IH). 
 elim :  Search nth_error.


Lemma linear_reduce : forall sg ls sg', Linear sg -> reduce sg ls = Some sg' -> wf_labels ls -> Linear sg'.
Proof. Admitted.

Lemma linear_repeat_reduce_cons : forall l sg sg' a,  repeat_reduce (a :: l) sg = Some sg' -> exists sg'', reduce sg a = Some sg'' /\ repeat_reduce l sg'' = Some sg'.
Proof.
move => l sg sg' a.  rewrite /=. destruct (reduce sg a). intros. exists s. auto.
done. 
Qed.

Lemma linear_repeat_reduce : forall lls sg sg', Linear sg -> repeat_reduce sg lls = Some sg' -> all wf_labels lls -> Linear sg'.
Proof. 
elim. 
- rewrite /=. intros. injection H0. move=><-. done. 
- intros. move : (linear_repeat_reduce_cons H1)=> [] x []. intros. move : H2.  rewrite /=. move/andP=>[]. intros. move : (linear_reduce H0 a0 a1). intros. apply :H. apply linear_reduce0. apply b. apply b0. 
Qed.

Lemma linear_step : forall sg l sg', step sg l sg' -> Linear sg -> Linear sg'.
Proof. 
intros.  move : (step_reduce H) =>[] x [H2 H3]. apply/linear_repeat_reduce.  apply H0. apply H2. 
apply H3. 
Qed.







Fixpoint end_list sgs :=
match sgs with 
| nil => true 
| GEnd::sgs' => end_list sgs'
| _::sgs' => false
end.

Fixpoint reduce (sg : sgType) (g : gType) {struct g} :=
let fix reduce_list sgs gs {struct gs} := 
match sgs,gs with 
 | nil,nil => Some nil
 | sg::sgs',g::gs' =>  obind (fun sgs'' => omap (fun sg' => sg'::sgs'' )  (reduce sg g)) (reduce_list sgs' gs')
 | _,_ => None 
end
in
match sg , g with 
| _,GEnd => Some sg
| SGMsg a u sg, GMsg a' u' GEnd => if (a == a') && (u == u') then Some sg else None
| SGMsg a u sg, GMsg a' u' g' => if (a == a') && (u == u') then omap (fun sg' => SGMsg a u sg') (reduce sg g') else None
| SGBranch a sgs, GBranch a' gs  => if a == a' then 
                                    if end_list gs then nth_error sgs (size gs)
                                                   else omap (fun sgs' => SGBranch a sgs') (reduce_list sgs gs) 
                                  else None
| _,_ => None
end.

(*receiver constranint boolean predicate on labels
 main lemma. if there is a normal reduction, there exists indcutive global types with receiver constraint s.t we can do the same reduction. By linearity and receiver constraint on this label, we know its leaves aren't used in any in/output chains. Next steps?
 A sub type relation. The bigger type contains all paths that are in the smaller type
 Define next as a partial function, next g a i, nexts g ais

 How do I connect all this to acturaly show the reduced G is linear?
 we can do the same red*)



(*Change ≺ to sequence of labels. Normal reduction implies a sequence of computation reductions that each have receiver constraint. Suffices to show that such a computation reduction preserves chains. Only affected chains are prefixes of ≺ sequence. If reduction sequence = ≺ sequence, the channel condition doesn't hold. If reduction sequence is a prefix, there exists a bitmask such that ≺ sequence such that chains are preserved *)
Lemma red_lin : forall g g_l g', Linear g -> reduce g g_l = Some g' -> Linear g'.
Proof. Admitted.





(*Besides well formedness we can also define input dependency and output dependency on rose trees
 and transform the tricky statement about k <> k' in the proof to there not existing any input or output dependency
 in the well formed rose tree that was used to reduce with because of the receiver criteria*)
Inductive wf_r (A : Type) : rose A -> A -> Prop :=
| wf_r0 a : wf_r (Rose a nil) a
| wf_r1 rs a1 a : (forall r, In r rs -> wf_r r a1) ->  wf_r (Rose a rs) a1.

Check nth_error.

Inductive reduce : sgType -> rose label -> sgType -> Prop :=
| SGMsg0 a u g0 : reduce (SGMsg a u g0) (Rose (LU a u) nil) g0
| SGMsg1 a u g0 g0' r' : reduce g0 r' g0' -> reduce (SGMsg a u g0) (Rose (LU a u) ([::r'])) (SGMsg a u g0')
| SGBranch0 a n g0 gs g: List.nth_error gs n = Some g -> reduce (SGBranch a gs) (Rose (LN a n) nil) g0
| SGBranch1 a a' rs gs  gs' n g r g' : (forall r, In r rs -> wf_r r a')  ->  (forall i, nth_error gs i = Some g -> nth_error rs i = Some r -> nth_error gs' i = Some g' -> reduce g r g' ) -> reduce (SGBranch a gs) (Rose (LN a n) rs) (SGBranch a gs').



Fixpoint reduce (g : sgType) (r : rose label) :=
match g,r with 
| SGMsg a u g0, Rose (LU a' u') nil => if a == a' && u == u' then Some g0 else None
| SGMsg a u g0, Rose (LU a' u') ([r']) => if a == a' && u == u' then omap (fun g' => SGMsg a u g') (reduce g0 r')
| SGBranch a gs, Rose (LN a' n) nil => if a == a' then List.nth_error gs n
| SGBranch a gs, Rose (LN a' n) rs => if a == a' && leq (size gs) (size rs) then 

*)


(*fix async definitions*)
(*Inductive EnvStep2 : env -> label -> env -> Prop := 
| envstep2_msg (Δ: env) p0 p1 e0 e1 c v : Δ.[? p0] = Some e0 -> Δ.[? p1] = Some e1 -> EnvStep2 Δ.[p0 <- SEMsg Sd c v e0].[p1 <- SEMsg Rd c v e1] (to_label (inl v) p0 p1 c) Δ
| envstep2_msg_async (Δ Δ': env) p0 p1 e0 e1 e0' e1' c v a : Δ.[? p0] = Some e0  ->  Δ.[? p1] = Some e1 ->  Δ'.[? p0] = Some e0' -> Δ'.[? p1] = Some e1' -> ~~(in_action p1 a) -> EnvStep2 Δ (LU a v) Δ' -> action_ch a <> c ->  EnvStep2 Δ.[p0 <- SEMsg Sd c v e0].[p1 <- SEMsg Rd c v e1] (LU a v) Δ'.[p0 <- SEMsg Sd c v e0'].[p1 <- SEMsg Rd c v e1']
| envstep2_branch (Δ : env) (Δs : seq env) p0 p1 es0 es1 c n : n < size Δs -> 
                                                               Forall2 (fun (d : env) e => d.[? p0] = Some e) Δs es0 -> 
                                                               Forall2 (fun (d : env) e => d.[? p1] = Some e) Δs es1 -> 
                                                               Forall (fun d => d.[~ p0].[~ p1] = Δ) Δs ->
                                                               EnvStep2 Δ.[p0 <- SEBranch Sd c es0].[p1 <- SEBranch Rd c es1] (to_label (inr n) p0 p1 c) 
                                                                       (nth [fmap] Δs n).
| envstep2_branch_async (Δ : env) (Δs : seq env) p0 p1 es0 es1 c n : n < size Δs -> 
                                                               Forall2 (fun (d : env) e => d.[? p0] = Some e) Δs es0 -> 
                                                               Forall2 (fun (d : env) e => d.[? p1] = Some e) Δs es1 -> 
                                                               Forall (fun d => d.[~ p0].[~ p1] = Δ) Δs ->
                                                               Forall2 (fun d0 d1 => EnvStep2 d0 (LN a n) d1) Δs Δs' ->
                                                               Forall2 (fun (d : env) e => d.[? p0] = Some e) Δs' es0' -> 
                                                               Forall (fun d => d.[~ p0].[~ p1] = Δ') Δs' ->
                                                               EnvStep2 Δ.[p0 <- SEBranch Sd c es0].[p1 <- SEBranch Rd c es1] (LN a n)
                                                                        Δ'.[p0 <- SEBranch Sd c es0'].[p1 <- SEBranch Rd c es1]. *)



(*Inductive Ecomm : env -> label -> env -> Prop := 
| Ecomm_rule p0 p1 (Δ : env) e0 e1 e0' e1' c vn : Estep e0 (Sd,c,vn) e0' -> Estep e1 (Rd,c,vn) e1' ->
                                                  Ecomm Δ.[ p0 <- e0].[p1 <- e1] (to_label vn p0 p1 c) ((Δ.[p0 <- e0']).[p1 <- e1']).*)


(*Definition get (Δ : env) (p : ptcp) := 
if Δ.[? p] is Some e then  e else SEEnd. 

Definition gets (Δs : seq env) (p : ptcp) := map (fun Δ => get Δ p ) Δs.


(*Bake property into inductive definition even though it should be provable, not obious how because of coinduction*)
Definition no_end (d : env) := forall p e, d.[? p] = Some e -> e <> SEEnd.*)




(*Lemma allproj_no_ends : forall g d, co_allproj g d -> no_end d.
Proof.
intros. punfold H. induction H; rewrite /no_end;intros.  rewrite fnd_fmap0 in H. done. 
move : H1.
rewrite fnd_set. destruct (p == p1) eqn:Heqn. case. intros. subst. done.
rewrite fnd_set. destruct (p == p0) eqn:Heqn1. case. move=> <-. done. move : H. rewrite /no_end. intros. eauto. 
move : H2.
rewrite fnd_set. destruct (p == p1) eqn:Heqn. case. intros. subst. done.
rewrite fnd_set. destruct (p == p0) eqn:Heqn1. case. move=> <-. done. move : H. rewrite /no_end. intros. eauto. 
Qed.*)



