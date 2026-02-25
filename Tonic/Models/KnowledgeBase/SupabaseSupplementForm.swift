import Foundation

struct SupabaseSupplementForm: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let formName: String
    let bioavailability: String?
    let availability: String?
    let isRecommended: Bool?
    let costTier: String?
    let notes: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, bioavailability, availability, notes
        case supplementId = "supplement_id"
        case formName = "form_name"
        case isRecommended = "is_recommended"
        case costTier = "cost_tier"
        case createdAt = "created_at"
    }
}
