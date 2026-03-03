import Foundation

struct KnowledgeBaseSnapshot: Codable {
    let supplements: [SupabaseSupplement]
    let goalMaps: [SupabaseGoalMap]
    let drugInteractions: [SupabaseDrugInteraction]
    let personalizationSignals: [SupabasePersonalizationSignal]
    let supplementForms: [SupabaseSupplementForm]
    let contraindications: [SupabaseContraindication]
    let synergyPairings: [SupabaseSynergyPairing]
    let caveats: [SupabaseCaveat]
    let mechanisms: [SupabaseMechanism]
    let labInterferences: [SupabaseLabInterference]
    let sources: [SupabaseSource]
}
