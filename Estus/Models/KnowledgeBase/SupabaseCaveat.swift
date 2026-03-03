import Foundation

struct SupabaseCaveat: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let caveatType: String
    let claim: String?
    let reality: String
    let persistenceReason: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, claim, reality
        case supplementId = "supplement_id"
        case caveatType = "caveat_type"
        case persistenceReason = "persistence_reason"
        case createdAt = "created_at"
    }
}
