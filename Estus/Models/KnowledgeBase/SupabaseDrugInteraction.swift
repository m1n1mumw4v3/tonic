import Foundation

struct SupabaseDrugInteraction: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let drugOrClass: String
    let interactionType: String?
    let severity: String?
    let mechanism: String?
    let action: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, severity, mechanism, action
        case supplementId = "supplement_id"
        case drugOrClass = "drug_or_class"
        case interactionType = "interaction_type"
        case createdAt = "created_at"
    }
}
