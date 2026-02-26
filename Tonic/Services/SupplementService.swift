import Foundation
import Supabase

actor SupplementService {
    private let client: SupabaseClient

    init(client: SupabaseClient? = nil) {
        if let client {
            self.client = client
        } else {
            self.client = SupabaseClient(
                supabaseURL: AppConfiguration.supabaseURL,
                supabaseKey: AppConfiguration.supabaseAnonKey
            )
        }
    }

    // MARK: - Catalog Loading (cached data)

    struct CatalogData {
        let supplements: [DBSupplement]
        let goalMaps: [DBSupplementGoalMap]
        let synergies: [DBSynergisticPairing]
    }

    func loadCatalog() async throws -> CatalogData {
        async let supplements: [DBSupplement] = client
            .from("supplements")
            .select()
            .execute()
            .value

        async let goalMaps: [DBSupplementGoalMap] = client
            .from("supplement_goal_map")
            .select()
            .execute()
            .value

        async let synergies: [DBSynergisticPairing] = client
            .from("synergistic_pairings")
            .select("*, supplement_a:supplements!supplement_a_id(name), supplement_b:supplements!supplement_b_id(name)")
            .execute()
            .value

        return try await CatalogData(
            supplements: supplements,
            goalMaps: goalMaps,
            synergies: synergies
        )
    }

    // MARK: - Safety Data (always fresh)

    func fetchDrugInteractions(for supplementIds: [UUID]) async throws -> [DBDrugInteraction] {
        guard !supplementIds.isEmpty else { return [] }
        let ids = supplementIds.map(\.uuidString)
        return try await client
            .from("drug_interactions")
            .select("*, supplement:supplements!supplement_id(name)")
            .in("supplement_id", values: ids)
            .execute()
            .value
    }

    func fetchContraindications(for supplementIds: [UUID]) async throws -> [DBContraindication] {
        guard !supplementIds.isEmpty else { return [] }
        let ids = supplementIds.map(\.uuidString)
        return try await client
            .from("contraindications")
            .select("*, supplement:supplements!supplement_id(name)")
            .in("supplement_id", values: ids)
            .execute()
            .value
    }

    func fetchSafetyData(for supplementIds: [UUID]) async throws -> (interactions: [DBDrugInteraction], contraindications: [DBContraindication]) {
        async let interactions = fetchDrugInteractions(for: supplementIds)
        async let contraindications = fetchContraindications(for: supplementIds)
        return try await (interactions: interactions, contraindications: contraindications)
    }

    // MARK: - Supplement Detail (full record with all related data)

    struct SupplementDetail {
        let supplement: DBSupplement
        let goalMaps: [DBSupplementGoalMap]
        let mechanisms: [DBSupplementMechanism]
        let forms: [DBSupplementForm]
        let interactions: [DBDrugInteraction]
        let contraindications: [DBContraindication]
        let labInterferences: [DBLabTestInterference]
        let caveats: [DBHonestCaveat]
        let sources: [DBSupplementSource]
    }

    func fetchSupplementDetail(id: UUID) async throws -> SupplementDetail {
        let idString = id.uuidString

        async let supplement: DBSupplement = client
            .from("supplements")
            .select()
            .eq("id", value: idString)
            .single()
            .execute()
            .value

        async let goalMaps: [DBSupplementGoalMap] = client
            .from("supplement_goal_map")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        async let mechanisms: [DBSupplementMechanism] = client
            .from("supplement_mechanisms")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        async let forms: [DBSupplementForm] = client
            .from("supplement_forms")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        async let interactions: [DBDrugInteraction] = client
            .from("drug_interactions")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        async let contraindications: [DBContraindication] = client
            .from("contraindications")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        async let labInterferences: [DBLabTestInterference] = client
            .from("lab_test_interferences")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        async let caveats: [DBHonestCaveat] = client
            .from("honest_caveats")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        async let sources: [DBSupplementSource] = client
            .from("supplement_sources")
            .select()
            .eq("supplement_id", value: idString)
            .execute()
            .value

        return try await SupplementDetail(
            supplement: supplement,
            goalMaps: goalMaps,
            mechanisms: mechanisms,
            forms: forms,
            interactions: interactions,
            contraindications: contraindications,
            labInterferences: labInterferences,
            caveats: caveats,
            sources: sources
        )
    }
}
