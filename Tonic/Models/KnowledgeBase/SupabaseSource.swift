import Foundation

struct SupabaseSource: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let citation: String
    let sectionReferenced: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, citation
        case supplementId = "supplement_id"
        case sectionReferenced = "section_referenced"
        case createdAt = "created_at"
    }
}
