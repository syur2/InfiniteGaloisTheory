/-
Copyright (c) 2024 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jujian Zhang, Nailin Guan, Yuyang Zhao, Yongle Hu
-/
import InfiniteGaloisTheory.ProFinite.Basic

/-!

# A profinite Group is projective limit of finite groups


## Main definitions and results

* `limitOfFiniteGrp`: direct limit of finite groups is a profinite group

-/

suppress_compilation

universe u v

open CategoryTheory Topology

section limit

universe w w'

variable {J : Type v} [Category.{w, v} J] (F : J ⥤ FiniteGrp.{max v w'})

attribute [local instance] ConcreteCategory.instFunLike ConcreteCategory.hasCoeToSort

instance (j : J) : TopologicalSpace (F.obj j) := ⊥

instance (j : J) : DiscreteTopology (F.obj j) := ⟨rfl⟩

instance (j : J) : TopologicalGroup (F.obj j) := {}

namespace FiniteGrp

/-Concretely constructing the limit of topological group-/

def limit : Subgroup (Π j : J, F.obj j) where
  carrier := {x | ∀ ⦃i j : J⦄ (π : i ⟶ j), F.map π (x i) = x j}
  mul_mem' hx hy _ _ π := by simp only [Pi.mul_apply, map_mul, hx π, hy π]
  one_mem' := by simp
  inv_mem' h _ _ π := by simp [h π]

@[simp]
lemma mem_limit (x : Π j : J, F.obj j) : x ∈ limit F ↔ ∀ ⦃i j : J⦄ (π : i ⟶ j), F.map π (x i) = x j :=
  Iff.rfl

instance : CompactSpace (limit F) := ClosedEmbedding.compactSpace (f := (limit F).subtype)
  { induced := rfl
    inj := Subgroup.subtype_injective _
    isClosed_range := by
      classical
      let S ⦃i j : J⦄ (π : i ⟶ j) : Set (Π j : J, F.obj j) := {x | F.map π (x i) = x j}
      have hS ⦃i j : J⦄ (π : i ⟶ j) : IsClosed (S π) := by
        simp only [S]
        rw [← isOpen_compl_iff, isOpen_pi_iff]
        rintro x (hx : ¬ _)
        simp only [Set.mem_setOf_eq] at hx
        refine ⟨{i, j}, fun i => {x i}, ?_⟩
        simp only [Finset.mem_singleton, isOpen_discrete, Set.mem_singleton_iff, and_self,
          implies_true, Finset.coe_singleton, Set.singleton_pi, true_and]
        intro y hy
        simp only [Finset.coe_insert, Finset.coe_singleton, Set.insert_pi, Set.singleton_pi,
          Set.mem_inter_iff, Set.mem_preimage, Function.eval, Set.mem_singleton_iff,
          Set.mem_compl_iff, Set.mem_setOf_eq] at hy ⊢
        rwa [hy.1, hy.2]
      have eq : Set.range (limit F).subtype = ⋂ (i : J) (j : J) (π : i ⟶ j), S π := by
        ext x
        simp only [Subgroup.coeSubtype, Subtype.range_coe_subtype, SetLike.mem_coe, mem_limit,
          Set.mem_setOf_eq, Set.mem_iInter]
        tauto
      rw [eq]
      exact isClosed_iInter fun i => isClosed_iInter fun j => isClosed_iInter fun π => hS π }

end FiniteGrp

namespace ProfiniteGrp

def ofFiniteGrpLimit : ProfiniteGrp := .of (FiniteGrp.limit F)

/-- verify that the limit constructed above satisfies the universal property-/
@[simps]
def ofFiniteGrpLimitCone : Limits.Cone (F ⋙ forget₂ FiniteGrp ProfiniteGrp) where
  pt := ofFiniteGrpLimit F
  π :=
  { app := fun j => {
      toFun := fun x => x.1 j
      map_one' := rfl
      map_mul' := fun x y => rfl
      continuous_toFun := by
        dsimp
        have triv : Continuous fun x : ((Functor.const J).obj (ofFiniteGrpLimit F)).obj j ↦ x.1 :=
          continuous_iff_le_induced.mpr fun U a => a
        have : Continuous fun (x1 : (j : J) → F.obj j) ↦ x1 j := continuous_apply j
        exact this.comp triv
    }
    naturality := by
      intro i j f
      simp only [Functor.const_obj_obj, Functor.comp_obj,
        Functor.const_obj_map, Category.id_comp, Functor.comp_map]
      congr
      exact funext fun x ↦ (x.2 f).symm
  }

@[simps]
def ofFiniteGrpLimitConeIsLimit : Limits.IsLimit (ofFiniteGrpLimitCone F) where
  lift cone := {
    toFun := fun pt ↦
      { val := fun j => (cone.π.1 j) pt
        property := fun i j πij ↦ by
          have := cone.π.2 πij
          simp only [Functor.const_obj_obj, Functor.comp_obj, Functor.const_obj_map,
            Category.id_comp, Functor.comp_map] at this
          simp [this]
          rfl }
    map_one' := by
      apply SetCoe.ext
      simp only [Functor.const_obj_obj, Functor.comp_obj, OneMemClass.coe_one, Pi.one_apply,
        OneHom.toFun_eq_coe, OneHom.coe_mk, id_eq, Functor.const_obj_map, Functor.comp_map,
        MonoidHom.toOneHom_coe, MonoidHom.coe_mk, eq_mpr_eq_cast, cast_eq, map_one]
      rfl
    map_mul' := fun x y => by
      apply SetCoe.ext
      simp only [Functor.const_obj_obj, Functor.comp_obj, OneMemClass.coe_one, Pi.one_apply,
        OneHom.toFun_eq_coe, OneHom.coe_mk, id_eq, Functor.const_obj_map, Functor.comp_map,
        MonoidHom.toOneHom_coe, MonoidHom.coe_mk, eq_mpr_eq_cast, cast_eq, map_mul]
      rfl
    continuous_toFun := by
      dsimp
      apply continuous_induced_rng.mpr
      show  Continuous (fun pt ↦ (fun j ↦ (cone.π.app j) pt))
      apply continuous_pi
      intro j
      exact (cone.π.1 j).continuous_toFun
  }
  fac cone j := by
    dsimp
    ext pt
    simp only [comp_apply]
    rfl
  uniq := by
    dsimp
    intro cone g hyp
    ext pt
    refine Subtype.ext <| funext fun j => ?_
    change _ = cone.π.app _ _
    rw [←hyp j]
    rfl

instance : Limits.HasLimit (F ⋙ forget₂ FiniteGrp ProfiniteGrp) where
  exists_limit := Nonempty.intro
    { cone := ofFiniteGrpLimitCone F
      isLimit := ofFiniteGrpLimitConeIsLimit F
    }

end ProfiniteGrp

end limit

namespace ProfiniteGrp

section

abbrev OpenNormalSubgroup (G : ProfiniteGrp) := {H : Subgroup G // H.Normal ∧ IsOpen (H : Set G)}

def diagramOfProfiniteGrp (P : ProfiniteGrp) :
  OpenNormalSubgroup P ⥤ FiniteGrp := {
    obj := fun ⟨H, _, hH⟩ =>
      letI : Finite (P ⧸ H) := finite_quotient_of_open_subgroup H hH
      FiniteGrp.of (P ⧸ H)
    map := fun {H K} fHK =>
      let ⟨H, _, _⟩ := H
      let ⟨K, _, _⟩ := K
      QuotientGroup.map H K (.id _) $ Subgroup.comap_id K ▸ leOfHom fHK
    map_id := fun ⟨x, _, _⟩ => by
      simp only [QuotientGroup.map_id, id_apply]; rfl
    map_comp := fun {X Y Z} f g =>
      let ⟨x, _, _⟩ := X
      let ⟨y, _, _⟩ := Y
      let ⟨z, _, _⟩ := Z
      (QuotientGroup.map_comp_map x y z (.id _) (.id _) (Subgroup.comap_id y ▸ leOfHom f)
        (Subgroup.comap_id z ▸ leOfHom g)).symm
  }

def canonicalMap (P : ProfiniteGrp.{u}) : P ⟶ ofFiniteGrpLimit (diagramOfProfiniteGrp P) where
  toFun := fun p => {
    val := fun ⟨H, _, _⟩ => QuotientGroup.mk p
    property := fun ⟨A, _, _⟩ ⟨B, _, _⟩ _ => rfl
  }
  map_one' := Subtype.val_inj.mp (by ext ⟨H, _, _⟩; rfl)
  map_mul' := fun x y => Subtype.val_inj.mp (by ext ⟨H, _, _⟩; rfl)
  continuous_toFun := by
    dsimp
    apply continuous_induced_rng.mpr
    apply continuous_pi
    intro ⟨H, hH, hHO⟩
    dsimp
    apply Continuous.mk
    intro s _
    rw [← (Set.biUnion_preimage_singleton QuotientGroup.mk s)]
    apply isOpen_iUnion; intro i
    apply isOpen_iUnion; intro ih
    rw [QuotientGroup.preimage_mk_eq_coset]
    exact IsOpen.leftCoset hHO (Quotient.out' i)

theorem denseCanonicalMap (P : ProfiniteGrp.{u}) : Dense $ Set.range (canonicalMap P) :=
  dense_iff_inter_open.mpr
    fun U hUO hUNonempty => (by
      let uDefault := hUNonempty.some
      let uDefaultSpec : uDefault ∈ U := hUNonempty.some_mem
      rcases hUO with ⟨s, hsO, hsv⟩
      let uMemPiOpen := isOpen_pi_iff.mp hsO
      simp_rw [← hsv] at uDefaultSpec
      rw [Set.mem_preimage] at uDefaultSpec
      specialize uMemPiOpen _ uDefaultSpec
      rcases uMemPiOpen with ⟨J, fJ, h_ok_and_in_s⟩
      let subg: J → Subgroup P := fun ⟨j, _⟩ => j.val
      haveI subgNormal: ∀ j : J, (subg j).Normal := fun ⟨j, _⟩ => j.prop.1
      let M := iInf subg
      haveI hM : M.Normal := Subgroup.normal_iInf_normal subgNormal
      haveI hMOpen : IsOpen (M : Set P) := by
        rw [Subgroup.coe_iInf]
        exact isOpen_iInter_of_finite fun ⟨i, _⟩ => i.prop.2
      let m : P.OpenNormalSubgroup := ⟨M, hM, hMOpen⟩
      rcases uDefault with ⟨spc, hspc⟩
      have : Function.Surjective (QuotientGroup.mk' M) := QuotientGroup.mk'_surjective M
      rcases this (spc m) with ⟨origin, horigin⟩
      let map_origin := (canonicalMap P).toFun origin
      use map_origin
      constructor
      · have : map_origin.val ∈ J.toSet.pi fJ := fun a a_in_J => by
          let M_to_Na : m ⟶ a := (iInf_le subg ⟨a, a_in_J⟩).hom
          rw [← (P.canonicalMap.toFun origin).property M_to_Na]
          show (P.diagramOfProfiniteGrp.map M_to_Na) (QuotientGroup.mk' M origin) ∈ _
          rw [horigin, hspc M_to_Na]
          exact (h_ok_and_in_s.1 a a_in_J).2
        exact hsv ▸ h_ok_and_in_s.2 this
      exact ⟨origin, rfl⟩
    )

theorem surjectiveCanonicalMap (P : ProfiniteGrp.{u}) : Function.Surjective (canonicalMap P) := by
  have : IsClosedMap P.canonicalMap := P.canonicalMap.continuous_toFun.isClosedMap
  haveI compact_s: IsCompact (Set.univ : Set P) := CompactSpace.isCompact_univ
  have : IsClosed (P.canonicalMap '' Set.univ) := this _ $ IsCompact.isClosed compact_s
  have dense_map := Dense.closure_eq $ denseCanonicalMap P
  apply closure_eq_iff_isClosed.mpr at this
  rw [Set.image_univ] at this
  rw [dense_map] at this
  exact Set.range_iff_surjective.mp (id this.symm)

end

section

namespace ProfiniteGrp
open scoped Pointwise

theorem exist_open_symm_subnhds {G : ProfiniteGrp} {W : Set G}
(WClopen : IsClopen W) (einW : 1 ∈ W) :∃ V : Set G, IsOpen V ∧ V = V⁻¹ ∧ 1 ∈ V ∧ V ⊆ W ∧ W * V ⊆ W :=sorry

def open_subgroup_subnhds {G : ProfiniteGrp} {W : Set G}
(WClopen : IsClopen W) (einW : 1 ∈ W) : Subgroup G :=sorry

theorem open_subgroup_subnhds_spec {G : ProfiniteGrp} {W : Set G}
(WClopen : IsClopen W) (einW : 1 ∈ W) :
IsOpen ((open_subgroup_subnhds WClopen einW) : Set G) ∧
((open_subgroup_subnhds WClopen einW) : Set G) ⊆ W :=sorry

def OpenNormalSubgroup_subnhds {G : ProfiniteGrp} {U : Set G}
(UOpen : IsClopen U) (einU : 1 ∈ U) : OpenNormalSubgroup G :=sorry

theorem OpenNormalSubgroup_subnhds_spec {G : ProfiniteGrp} {U : Set G}
(UOpen : IsClopen U) (einU : 1 ∈ U) : ((OpenNormalSubgroup_subnhds UOpen einU) : Set G) ⊆ U :=sorry


end ProfiniteGrp
