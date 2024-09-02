/-
Copyright (c) 2024 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jujian Zhang, Nailin Guan, Yuyang Zhao, Yongle Hu
-/
import InfiniteGaloisTheory.ProFinite.Defs

/-!

# Basic properties of Profinite Groups

-/

suppress_compilation

universe u v

open CategoryTheory Topology

namespace ProfiniteGrp

def ofHomeoMulEquivProfiniteGrp {G : ProfiniteGrp.{u}} {H : Type v} [TopologicalSpace H] [Group H]
    [TopologicalGroup H] (e : ContinuousMulEquiv G H) : ProfiniteGrp.{v} :=
  letI : CompactSpace H := Homeomorph.compactSpace e.toHomeomorph
  letI : TotallyDisconnectedSpace G := Profinite.instTotallyDisconnectedSpaceαTopologicalSpaceToTop
  letI : TotallyDisconnectedSpace H := Homeomorph.TotallyDisconnectedSpace e.toHomeomorph
  .of H

def ofClosedSubgroup {G : ProfiniteGrp}
    (H : Subgroup G) (hH : IsClosed (H : Set G)) : ProfiniteGrp :=
  letI : CompactSpace H := ClosedEmbedding.compactSpace (f := H.subtype)
    { induced := rfl
      inj := H.subtype_injective
      isClosed_range := by simpa }
  of H

open scoped Pointwise

def finite_quotient_of_open_subgroup {G : ProfiniteGrp}
    (H : Subgroup G) (hH : IsOpen (H : Set G)) : Finite (G ⧸ H) := by
  obtain h := @CompactSpace.isCompact_univ G _ _
  rw [isCompact_iff_finite_subcover] at h
  have : (Set.univ : Set G) ⊆ ⋃ (i : G), i • (H : Set G) :=
    fun g _ => Set.mem_iUnion_of_mem g ⟨1, ⟨one_mem H, by simp⟩⟩
  specialize h (fun x : G => x • (H : Set G)) (IsOpen.smul hH) this
  obtain ⟨t, ht⟩ := h
  let f : t → (G ⧸ H) := fun ⟨x, _⟩ => QuotientGroup.mk x
  apply Finite.of_surjective f
  intro x
  have : x.out' ∈ ⋃ i ∈ t, i • (H : Set G) := ht trivial
  simp only [Set.mem_iUnion] at this
  choose i hi hii using this
  use ⟨i, hi⟩
  rw [mem_leftCoset_iff] at hii
  have : i⁻¹ * Quotient.out' x ∈ H := hii
  rw [← @QuotientGroup.eq _ _ H i x.out'] at this
  show Quotient.mk'' i = x
  rw [Eq.symm (QuotientGroup.out_eq' x)]
  exact this

def finiteIndex_of_open_subgroup {G : ProfiniteGrp}
    (H : Subgroup G) (hH : IsOpen (H : Set G)) : H.FiniteIndex :=
  haveI : Finite (G ⧸ H) := finite_quotient_of_open_subgroup H hH
  Subgroup.finiteIndex_of_finite_quotient H

end ProfiniteGrp

section ProfiniteGrp

namespace ProfiniteGrp

theorem exist_open_compact_subnhds {G : ProfiniteGrp} {U : Set G} (UOpen : IsOpen U) (einU : 1 ∈ U) :∃ W : Set G, IsOpen W ∧ IsCompact W ∧ 1 ∈ W ∧ W ⊆ U:= by

  let N := { s : Set G // IsClopen s ∧ 1 ∈ s }
  have inter : connectedComponent (1 : G) = ⋂ s : N, s := connectedComponent_eq_iInter_isClopen (1 : G)
  have cover : Uᶜ ⊆ ⋃ s : N, (s : Set G)ᶜ := by
    rw[← Set.compl_iInter,Set.compl_subset_compl,← inter,connectedComponent_eq_singleton,Set.singleton_subset_iff]
    apply einU
  have scomplOpen: ∀ (s : N), IsOpen (s : Set G)ᶜ := by
    rintro ⟨s,sClopen,_⟩
    rw[isOpen_compl_iff]
    apply IsClopen.isClosed sClopen
  have UcomplCompact : IsCompact Uᶜ :=  IsClosed.isCompact (isClosed_compl_iff.mpr UOpen)
  rcases IsCompact.elim_finite_subcover UcomplCompact _ scomplOpen cover with ⟨fin,fincover⟩
  use ⋂ s ∈ fin, s
  constructor
  · have t : ∀ s ∈ fin, IsOpen (s : Set G) := by
      rintro ⟨s,sClopen,_⟩ _
      apply IsClopen.isOpen sClopen
    apply isOpen_biInter_finset t
  constructor
  · apply IsClosed.isCompact
    apply isClosed_biInter
    rintro ⟨s,sClopen,_⟩ _
    apply IsClopen.isClosed sClopen
  constructor
  · simp only [Set.mem_iInter]
    rintro ⟨s,_,eins⟩ _
    apply eins
  · simp only [← Set.compl_iInter,Set.compl_subset_compl] at fincover
    exact fincover


end ProfiniteGrp
