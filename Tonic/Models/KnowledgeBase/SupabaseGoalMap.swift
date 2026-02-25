import Foundation

struct SupabaseGoalMap: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let goal: String
    let weight: String
    let classification: String?
    let mechanismKey: String?
    let rationale: String?
    let keySources: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, goal, weight, classification, rationale
        case supplementId = "supplement_id"
        case mechanismKey = "mechanism_key"
        case keySources = "key_sources"
        case createdAt = "created_at"
    }
}
