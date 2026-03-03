import Foundation
import Supabase

struct SupabaseKBFetcher {
    private let client: SupabaseClient

    init(client: SupabaseClient = AppConfiguration.supabaseClient) {
        self.client = client
    }

    func fetchAll() async throws -> KnowledgeBaseSnapshot {
        async let supplements: [SupabaseSupplement] = fetch("supplements")
        async let goalMaps: [SupabaseGoalMap] = fetch("supplement_goal_map")
        async let drugInteractions: [SupabaseDrugInteraction] = fetch("drug_interactions")
        async let signals: [SupabasePersonalizationSignal] = fetch("personalization_signals")
        async let forms: [SupabaseSupplementForm] = fetch("supplement_forms")
        async let contraindications: [SupabaseContraindication] = fetch("contraindications")
        async let synergies: [SupabaseSynergyPairing] = fetch("synergistic_pairings")
        async let caveats: [SupabaseCaveat] = fetch("honest_caveats")
        async let mechanisms: [SupabaseMechanism] = fetch("supplement_mechanisms")
        async let labInterferences: [SupabaseLabInterference] = fetch("lab_test_interference")
        async let sources: [SupabaseSource] = fetch("supplement_sources")

        return try await KnowledgeBaseSnapshot(
            supplements: supplements,
            goalMaps: goalMaps,
            drugInteractions: drugInteractions,
            personalizationSignals: signals,
            supplementForms: forms,
            contraindications: contraindications,
            synergyPairings: synergies,
            caveats: caveats,
            mechanisms: mechanisms,
            labInterferences: labInterferences,
            sources: sources
        )
    }

    private func fetch<T: Decodable>(_ table: String) async throws -> [T] {
        try await client.from(table).select().execute().value
    }
}
