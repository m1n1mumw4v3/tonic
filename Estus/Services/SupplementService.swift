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
        let drugInteractions: [DBDrugInteraction]
        let personalizationSignals: [SupabasePersonalizationSignal]
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
            .select()
            .execute()
            .value

        async let drugInteractions: [DBDrugInteraction] = client
            .from("drug_interactions")
            .select("*, supplements!supplement_id(name)")
            .execute()
            .value

        async let personalizationSignals: [SupabasePersonalizationSignal] = client
            .from("personalization_signals")
            .select()
            .execute()
            .value

        return try await CatalogData(
            supplements: supplements,
            goalMaps: goalMaps,
            synergies: synergies,
            drugInteractions: drugInteractions,
            personalizationSignals: personalizationSignals
        )
    }

    // MARK: - Medications

    func fetchMedications() async throws -> [DBMedication] {
        try await client.from("medications").select().execute().value
    }

    func fetchAllDrugInteractions() async throws -> [DBDrugInteraction] {
        try await client
            .from("drug_interactions")
            .select("*, supplements!supplement_id(name)")
            .execute()
            .value
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

    // MARK: - Product Shopping

    func fetchProducts(forSupplementId id: UUID) async throws -> [RankedProduct] {
        let idString = id.uuidString

        // Step 1: Get product IDs from join table (only primary mappings to avoid combo dupes)
        let mappings: [DBProductSupplementMap] = try await client
            .from("product_supplement_map")
            .select()
            .eq("supplement_id", value: idString)
            .eq("is_primary", value: true)
            .execute()
            .value

        let mappedProductIds = mappings.map(\.productId.uuidString)
        guard !mappedProductIds.isEmpty else { return [] }

        // Step 2: Fetch products + related data in parallel
        async let products: [DBProduct] = client
            .from("products")
            .select()
            .in("id", values: mappedProductIds)
            .eq("is_active", value: true)
            .execute()
            .value

        async let scores: [DBProductScore] = client
            .from("product_scores")
            .select()
            .in("product_id", values: mappedProductIds)
            .execute()
            .value

        async let pricings: [DBProductPricing] = client
            .from("product_pricing")
            .select()
            .in("product_id", values: mappedProductIds)
            .eq("is_active", value: true)
            .execute()
            .value

        async let certifications: [DBProductCertification] = client
            .from("product_certifications")
            .select()
            .in("product_id", values: mappedProductIds)
            .execute()
            .value

        let (fetchedProducts, fetchedScores, fetchedPricings, fetchedCerts) = try await (products, scores, pricings, certifications)

        let scoreMap = Dictionary(fetchedScores.map { ($0.productId, $0) }, uniquingKeysWith: { first, _ in first })
        let pricingMap = Dictionary(fetchedPricings.map { ($0.productId, $0) }, uniquingKeysWith: { first, _ in first })
        let certMap = Dictionary(grouping: fetchedCerts, by: \.productId)

        return fetchedProducts.compactMap { product in
            guard let score = scoreMap[product.id] else { return nil }
            return RankedProduct(
                product: product,
                score: score,
                pricing: pricingMap[product.id],
                certifications: certMap[product.id] ?? []
            )
        }
        .sorted {
            let rank0 = $0.score.pickRank ?? Int.max
            let rank1 = $1.score.pickRank ?? Int.max
            if rank0 != rank1 { return rank0 < rank1 }
            return $0.score.estusScore > $1.score.estusScore
        }
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
