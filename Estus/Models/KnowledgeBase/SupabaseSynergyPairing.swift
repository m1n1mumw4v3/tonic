import Foundation

struct SupabaseSynergyPairing: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let partnerSupplementId: UUID?
    let partnerName: String
    let mechanism: String?
    let evidenceLevel: String?
    let directionality: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, mechanism
        case supplementId = "supplement_id"
        case partnerSupplementId = "partner_supplement_id"
        case partnerName = "partner_name"
        case evidenceLevel = "evidence_level"
        case directionality
        case createdAt = "created_at"
    }
}
