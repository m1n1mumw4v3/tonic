import Foundation

struct SupabaseContraindication: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let condition: String
    let severity: String?
    let rationale: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, condition, severity, rationale
        case supplementId = "supplement_id"
        case createdAt = "created_at"
    }
}
