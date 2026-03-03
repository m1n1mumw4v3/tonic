import Foundation

struct SupabasePersonalizationSignal: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let profileField: String
    let condition: String
    let effect: String?
    let magnitude: String?
    let source: String?
    let rationale: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, condition, effect, magnitude, source, rationale
        case supplementId = "supplement_id"
        case profileField = "profile_field"
        case createdAt = "created_at"
    }
}
