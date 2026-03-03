import Foundation

struct SupabaseLabInterference: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let testName: String
    let effect: String?
    let mechanism: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, effect, mechanism
        case supplementId = "supplement_id"
        case testName = "test_name"
        case createdAt = "created_at"
    }
}
