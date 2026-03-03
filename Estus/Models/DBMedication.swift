import Foundation

struct DBMedication: Codable, Identifiable {
    let id: UUID
    let genericName: String
    let brandNames: [String]?
    let drugClass: String?
    let displayCategory: String
    let displayName: String
    let interactionKeys: [String]
    let isCommon: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case genericName = "generic_name"
        case brandNames = "brand_names"
        case drugClass = "drug_class"
        case displayCategory = "display_category"
        case displayName = "display_name"
        case interactionKeys = "interaction_keys"
        case isCommon = "is_common"
        case sortOrder = "sort_order"
    }
}
