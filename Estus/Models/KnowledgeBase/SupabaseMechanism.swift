import Foundation

struct SupabaseMechanism: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let mechanismKey: String
    let mechanismName: String
    let pathway: String?
    let goalRelevance: String?
    let keyDetail: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, pathway
        case supplementId = "supplement_id"
        case mechanismKey = "mechanism_key"
        case mechanismName = "mechanism_name"
        case goalRelevance = "goal_relevance"
        case keyDetail = "key_detail"
        case createdAt = "created_at"
    }
}
