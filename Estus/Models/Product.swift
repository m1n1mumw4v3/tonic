import Foundation
import SwiftUI

// MARK: - Certification Type

enum CertificationType: String, Codable, CaseIterable {
    case nsfCertifiedForSport = "nsf_certified_for_sport"
    case nsfContentsClaim = "nsf_contents_claim"
    case uspVerified = "usp_verified"
    case informedSport = "informed_sport"
    case informedIngredient = "informed_ingredient"
    case bannedSubstancesControlled = "banned_substances_controlled"
    case cgmpCertified = "cgmp_certified"
    case isoCertified = "iso_certified"
    case usdaOrganic = "usda_organic"
    case nonGmoVerified = "non_gmo_verified"
    case glutenFreeCertified = "gluten_free_certified"
    case veganCertified = "vegan_certified"
    case independentCoa = "independent_coa"
    case estusTested = "estus_tested"
    case unknown = "unknown"

    var label: String {
        switch self {
        case .nsfCertifiedForSport: return "NSF Sport"
        case .nsfContentsClaim: return "NSF Contents"
        case .uspVerified: return "USP"
        case .informedSport: return "Informed Sport"
        case .informedIngredient: return "Informed Ingredient"
        case .bannedSubstancesControlled: return "Banned Substance Controlled"
        case .cgmpCertified: return "cGMP"
        case .isoCertified: return "ISO"
        case .usdaOrganic: return "USDA Organic"
        case .nonGmoVerified: return "Non-GMO"
        case .glutenFreeCertified: return "Gluten-Free"
        case .veganCertified: return "Vegan"
        case .independentCoa: return "Independent COA"
        case .estusTested: return "Estus Tested"
        case .unknown: return "Certified"
        }
    }

    var icon: String {
        switch self {
        case .nsfCertifiedForSport, .nsfContentsClaim: return "checkmark.seal.fill"
        case .uspVerified: return "checkmark.seal.fill"
        case .informedSport: return "figure.run"
        case .informedIngredient: return "leaf.fill"
        case .bannedSubstancesControlled: return "checkmark.shield.fill"
        case .cgmpCertified: return "building.2.fill"
        case .isoCertified: return "building.2.fill"
        case .usdaOrganic: return "leaf.fill"
        case .nonGmoVerified: return "leaf.fill"
        case .glutenFreeCertified: return "xmark.circle.fill"
        case .veganCertified: return "leaf.fill"
        case .independentCoa: return "doc.text.magnifyingglass"
        case .estusTested: return "star.fill"
        case .unknown: return "checkmark.seal.fill"
        }
    }

    var description: String {
        switch self {
        case .nsfCertifiedForSport:
            return "One of the most rigorous certifications, verifying products are free of banned substances and contaminants for competitive athletes."
        case .nsfContentsClaim:
            return "Verifies that the product contains what's listed on the label, meeting NSF purity and accuracy standards."
        case .uspVerified:
            return "The U.S. Pharmacopeia mark confirms the product contains the declared ingredients at the correct potency and purity."
        case .informedSport:
            return "A globally recognized testing program that screens supplements for banned substances in sport."
        case .informedIngredient:
            return "Verifies that raw ingredient suppliers meet quality and banned-substance testing requirements."
        case .bannedSubstancesControlled:
            return "The product has been tested and verified to be free of substances prohibited in competitive sport."
        case .cgmpCertified:
            return "Manufactured in a facility following Current Good Manufacturing Practices, ensuring consistent quality and safety."
        case .isoCertified:
            return "The manufacturing facility meets international standards for quality management systems."
        case .usdaOrganic:
            return "Certified organic by the USDA, meaning ingredients are grown without synthetic pesticides or fertilizers."
        case .nonGmoVerified:
            return "Verified by the Non-GMO Project to be free of genetically modified organisms."
        case .glutenFreeCertified:
            return "Independently tested and verified to contain no gluten, safe for those with celiac disease or gluten sensitivity."
        case .veganCertified:
            return "Certified to contain no animal-derived ingredients or byproducts."
        case .independentCoa:
            return "An independent lab has verified the product's contents, potency, and purity through a Certificate of Analysis."
        case .estusTested:
            return "Independently evaluated by Estus for ingredient quality, dose accuracy, and label transparency."
        case .unknown:
            return "This product holds a verified certification."
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = CertificationType(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Database Models

struct DBProduct: Codable, Identifiable {
    let id: UUID
    let name: String
    let brand: String
    let format: String?
    let servingsPerContainer: Int?
    let imageUrl: String?
    let isEstusApproved: Bool
    let isActive: Bool
    let asin: String?
    let productUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, brand, format, asin
        case servingsPerContainer = "servings_per_container"
        case imageUrl = "image_url"
        case isEstusApproved = "is_estus_approved"
        case isActive = "is_active"
        case productUrl = "product_url"
    }
}

struct DBProductSupplementMap: Codable {
    let id: UUID
    let productId: UUID
    let supplementId: UUID
    let isPrimary: Bool
    let dosePerServing: Double?
    let doseUnit: String?
    let doseDescription: String?
    let formDelivered: String?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case supplementId = "supplement_id"
        case isPrimary = "is_primary"
        case dosePerServing = "dose_per_serving"
        case doseUnit = "dose_unit"
        case doseDescription = "dose_description"
        case formDelivered = "form_delivered"
    }
}

struct DBProductScore: Codable {
    let productId: UUID
    let estusScore: Double
    let testingScore: Double?
    let formQualityScore: Double?
    let doseAccuracyScore: Double?
    let ingredientCleanlinessScore: Double?
    let valueScore: Double?
    let testingNotes: String?
    let formNotes: String?
    let doseNotes: String?
    let ingredientNotes: String?
    let valueNotes: String?
    let pickRank: Int?
    let pickLabel: String?

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case estusScore = "estus_score"
        case testingScore = "testing_score"
        case formQualityScore = "form_quality_score"
        case doseAccuracyScore = "dose_accuracy_score"
        case ingredientCleanlinessScore = "ingredient_cleanliness_score"
        case valueScore = "value_score"
        case testingNotes = "testing_notes"
        case formNotes = "form_notes"
        case doseNotes = "dose_notes"
        case ingredientNotes = "ingredient_notes"
        case valueNotes = "value_notes"
        case pickRank = "pick_rank"
        case pickLabel = "pick_label"
    }
}

struct DBProductPricing: Codable, Identifiable {
    let id: UUID
    let productId: UUID
    let currency: String
    let amazonPrice: Double?
    let amazonPricePerServing: Double?
    let amazonUrl: String?
    let mfrPrice: Double?
    let mfrPricePerServing: Double?
    let mfrUrl: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case currency
        case amazonPrice = "amazon_price"
        case amazonPricePerServing = "amazon_price_per_serving"
        case amazonUrl = "amazon_url"
        case mfrPrice = "mfr_price"
        case mfrPricePerServing = "mfr_price_per_serving"
        case mfrUrl = "mfr_url"
        case isActive = "is_active"
    }
}

struct DBProductCertification: Codable, Identifiable {
    let id: UUID
    let productId: UUID
    let certificationType: CertificationType
    let certifyingBody: String?
    let verifiedByEstus: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case certificationType = "certification_type"
        case certifyingBody = "certifying_body"
        case verifiedByEstus = "verified_by_estus"
    }
}

// MARK: - Composite View Model

struct RankedProduct: Identifiable {
    var id: UUID { product.id }
    let product: DBProduct
    let score: DBProductScore
    let pricing: DBProductPricing?
    let certifications: [DBProductCertification]

    /// Best available price (Amazon preferred, then manufacturer)
    var bestPrice: Double? {
        pricing?.amazonPrice ?? pricing?.mfrPrice
    }

    /// Best available price per serving
    var bestPricePerServing: Double? {
        pricing?.amazonPricePerServing ?? pricing?.mfrPricePerServing
    }
}

// MARK: - Score Helpers

extension DBProductScore {
    var scoreLabel: String {
        switch estusScore {
        case 9.0...: return "EXCELLENT"
        case 8.0..<9.0: return "GREAT"
        case 7.0..<8.0: return "GOOD"
        case 6.0..<7.0: return "FAIR"
        default: return "FAIR"
        }
    }

    var scoreColor: Color {
        switch estusScore {
        case 9.0...: return DesignTokens.positive
        case 8.0..<9.0: return DesignTokens.positive
        case 7.0..<8.0: return DesignTokens.info
        default: return DesignTokens.textTertiary
        }
    }

    /// Returns (label, score, notes, color) tuples for the 5 category breakdowns
    var categoryBreakdowns: [(label: String, score: Double?, notes: String?)] {
        [
            ("Testing & Transparency", testingScore, testingNotes),
            ("Form Quality", formQualityScore, formNotes),
            ("Dose Accuracy", doseAccuracyScore, doseNotes),
            ("Ingredient Cleanliness", ingredientCleanlinessScore, ingredientNotes),
            ("Value", valueScore, valueNotes),
        ]
    }
}

extension Double {
    var categoryScoreLabel: String {
        switch self {
        case 9.0...: return "EXCELLENT"
        case 8.0..<9.0: return "HIGH"
        case 7.0..<8.0: return "GOOD"
        case 6.0..<7.0: return "FAIR"
        default: return "LOW"
        }
    }

    var categoryScoreColor: Color {
        switch self {
        case 9.0...: return DesignTokens.positive
        case 8.0..<9.0: return DesignTokens.positive
        case 7.0..<8.0: return DesignTokens.info
        default: return DesignTokens.textTertiary
        }
    }
}
