import Foundation

// MARK: - Postgres Enum Mirrors

enum DBEvidenceWeight: String, Codable {
    case one = "1"
    case two = "2"
    case three = "3"

    var intValue: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        case .three: return 3
        }
    }
}

enum DBEvidenceClassification: String, Codable {
    case extensiveResearch = "extensive_research"
    case clinicalResearch = "clinical_research"
    case emergingResearch = "emerging_research"

    var toEvidenceLevel: EvidenceLevel {
        switch self {
        case .extensiveResearch: return .strong
        case .clinicalResearch: return .moderate
        case .emergingResearch: return .emerging
        }
    }
}

enum DBSupplementCategory: String, Codable {
    case mineral
    case vitamin
    case fattyAcid = "fatty_acid"
    case adaptogen
    case aminoAcid = "amino_acid"
    case probiotic
    case coenzyme
    case protein
    case mushroom
    case hormone
    case plantExtract = "plant_extract"
    case fruitExtract = "fruit_extract"
    case botanical
}

enum DBInteractionType: String, Codable {
    case reducesEfficacy = "reduces_efficacy"
    case increasesEffect = "increases_effect"
    case increasesToxicity = "increases_toxicity"
    case absorptionInterference = "absorption_interference"
}

enum DBSeverityLevel: String, Codable {
    case low
    case moderate
    case high
}

enum DBInteractionAction: String, Codable {
    case avoid
    case adjustDose = "adjust_dose"
    case monitor
    case separateTiming = "separate_timing"
}

enum DBContraindicationSeverity: String, Codable {
    case absolute
    case relative
}

enum DBPersonalizationEffect: String, Codable {
    case increase
    case decrease
    case substitute
    case addNote = "add_note"
}

enum DBPersonalizationMagnitude: String, Codable {
    case minor
    case moderate
    case major
}

enum DBSignalSource: String, Codable {
    case onboardingProfile = "onboarding_profile"
    case deepProfile = "deep_profile"
    case checkInTrend = "check_in_trend"
    case labResult = "lab_result"
}

enum DBAvailabilityTier: String, Codable {
    case commonRetail = "common_retail"
    case specialtyRetail = "specialty_retail"
    case onlineOnly = "online_only"
}

enum DBCostTier: String, Codable {
    case budget
    case midRange = "mid_range"
    case premium
}

enum DBTimingOfDay: String, Codable {
    case morning
    case evening
    case either
    case split

    var toSupplementTiming: SupplementTiming {
        switch self {
        case .morning: return .morning
        case .evening: return .evening
        case .either: return .morning
        case .split: return .morning
        }
    }
}

enum DBFoodTiming: String, Codable {
    case withFood = "with_food"
    case withoutFood = "without_food"
    case either
}

enum DBSynergyDirectionality: String, Codable {
    case bidirectional
    case unidirectional
}

enum DBSynergyEvidence: String, Codable {
    case established
    case emerging
    case traditional
}

enum DBCaveatType: String, Codable {
    case absorption
    case labInterference = "lab_interference"
    case populationSpecific = "population_specific"
    case qualityConcern = "quality_concern"
    case tolerability
}

enum DBSynthesisConfidence: String, Codable {
    case high
    case moderate
    case low
}

// MARK: - Database Table Structs

struct DBSupplement: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let commonNames: [String]?
    let primaryAction: String?
    let defaultForm: String?
    let defaultDose: String?
    let displayDose: String?
    let doseRangeLow: String?
    let doseRangeHigh: String?
    let upperTolerableLimit: String?
    let toxicityThreshold: String?
    let timingOfDay: String?
    let withFood: String?
    let timingRationale: String?
    let timingRelativeNotes: String?
    let synthesisConfidence: String?
    let conflictingEvidenceNotes: String?
    let lastReviewed: String?
    let reviewTrigger: String?
    let createdAt: String?
    let updatedAt: String?
    let onsetRangeLow: String?
    let onsetRangeHigh: String?
    let onsetMinDays: Int?
    let onsetMaxDays: Int?
    let onsetDescription: String?

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case commonNames = "common_names"
        case primaryAction = "primary_action"
        case defaultForm = "default_form"
        case defaultDose = "default_dose"
        case displayDose = "display_dose"
        case doseRangeLow = "dose_range_low"
        case doseRangeHigh = "dose_range_high"
        case upperTolerableLimit = "upper_tolerable_limit"
        case toxicityThreshold = "toxicity_threshold"
        case timingOfDay = "time_of_day"
        case withFood = "with_food"
        case timingRationale = "timing_rationale"
        case timingRelativeNotes = "timing_relative_notes"
        case synthesisConfidence = "synthesis_confidence"
        case conflictingEvidenceNotes = "conflicting_evidence_notes"
        case lastReviewed = "last_reviewed"
        case reviewTrigger = "review_trigger"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case onsetRangeLow = "onset_range_low"
        case onsetRangeHigh = "onset_range_high"
        case onsetMinDays = "onset_min_days"
        case onsetMaxDays = "onset_max_days"
        case onsetDescription = "onset_description"
    }

    // MARK: - Derived Properties

    /// Category as the typed enum, falling back to .botanical
    var categoryEnum: DBSupplementCategory {
        DBSupplementCategory(rawValue: category) ?? .botanical
    }

    /// Dosage range string built from DB fields
    var dosageRange: String {
        if let low = doseRangeLow, let high = doseRangeHigh {
            return "\(low)–\(high)"
        }
        return defaultDose ?? ""
    }

    /// Best-effort numeric dosage parsed from defaultDose (e.g. "400 mg" → 400)
    var dosageMg: Double {
        guard let dose = defaultDose else { return 0 }
        let digits = dose.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Double(digits) ?? 0
    }

    /// Map synthesis_confidence to the app's evidence level
    var evidenceLevel: EvidenceLevel {
        switch synthesisConfidence?.lowercased() {
        case "high": return .strong
        case "moderate": return .moderate
        default: return .emerging
        }
    }

    /// Map timing fields to app's SupplementTiming
    var timing: SupplementTiming {
        if withFood == "with_food" { return .withFood }
        if withFood == "without_food" { return .emptyStomach }
        switch timingOfDay?.lowercased() {
        case "evening": return .evening
        default: return .morning
        }
    }

    /// Convert to the app's Supplement type
    func toSupplement(benefits: [String] = [], contraindications: [String] = [], drugInteractions: [String] = []) -> Supplement {
        let timeline: String = {
            if let desc = onsetDescription { return desc }
            if let min = onsetMinDays, let max = onsetMaxDays {
                return "Effects typically appear within \(min)–\(max) days"
            }
            return ""
        }()

        return Supplement(
            id: id,
            name: name,
            commonNames: commonNames ?? [],
            category: categoryEnum.rawValue,
            commonDosageRange: dosageRange,
            recommendedDosageMg: dosageMg,
            displayDose: displayDose,
            recommendedTiming: timing,
            benefits: benefits,
            contraindications: contraindications,
            drugInteractions: drugInteractions,
            notes: primaryAction ?? "",
            dosageRationale: timingRationale ?? "",
            expectedTimeline: timeline,
            whatToLookFor: defaultForm ?? "",
            formAndBioavailability: defaultForm ?? "",
            evidenceLevel: evidenceLevel
        )
    }
}

struct DBSupplementGoalMap: Codable, Identifiable {
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

    /// Weight as Int (defaults to 1)
    var weightInt: Int { Int(weight) ?? 1 }
}

struct DBSupplementMechanism: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let healthGoal: String
    let mechanism: String
    let synthesisConfidence: DBSynthesisConfidence?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case healthGoal = "health_goal"
        case mechanism
        case synthesisConfidence = "synthesis_confidence"
    }
}

struct DBPersonalizationSignal: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let signalSource: DBSignalSource
    let conditionKey: String
    let conditionValue: String
    let effect: DBPersonalizationEffect
    let magnitude: DBPersonalizationMagnitude?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case signalSource = "signal_source"
        case conditionKey = "condition_key"
        case conditionValue = "condition_value"
        case effect, magnitude, note
    }
}

struct DBSupplementForm: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let formName: String
    let bioavailabilityNote: String?
    let isRecommended: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case formName = "form_name"
        case bioavailabilityNote = "bioavailability_note"
        case isRecommended = "is_recommended"
    }
}

struct DBDrugInteraction: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let drugOrClass: String
    let interactionType: DBInteractionType
    let severity: DBSeverityLevel
    let action: DBInteractionAction
    let mechanism: String
    let supplementName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case drugOrClass = "drug_or_class"
        case interactionType = "interaction_type"
        case severity, action, mechanism
        case supplementName = "supplement_name"
    }
}

struct DBContraindication: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let conditionName: String
    let severity: DBContraindicationSeverity
    let explanation: String
    let supplementName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case conditionName = "condition_name"
        case severity, explanation
        case supplementName = "supplement_name"
    }
}

struct DBLabTestInterference: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let testName: String
    let interferenceType: String
    let note: String?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case testName = "test_name"
        case interferenceType = "interference_type"
        case note
    }
}

struct DBSynergisticPairing: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let partnerSupplementId: UUID?
    let partnerName: String
    let mechanism: String?
    let evidenceLevel: String?
    let directionality: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, mechanism, directionality
        case supplementId = "supplement_id"
        case partnerSupplementId = "partner_supplement_id"
        case partnerName = "partner_name"
        case evidenceLevel = "evidence_level"
        case createdAt = "created_at"
    }
}

struct DBHonestCaveat: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let caveatType: DBCaveatType
    let message: String

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case caveatType = "caveat_type"
        case message
    }
}

struct DBSupplementSource: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let citation: String
    let url: String?
    let year: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case citation, url, year
    }
}

// MARK: - HealthGoal ↔ DB Bridging

extension HealthGoal {
    /// Convert from DB health_goal enum string to Swift HealthGoal
    static func fromDB(_ dbGoal: String) -> HealthGoal? {
        HealthGoal(rawValue: dbGoal)
    }

    /// Convert to DB health_goal enum string
    var dbValue: String {
        rawValue
    }
}
