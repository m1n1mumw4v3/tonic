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
    case pharmacokinetic
    case pharmacodynamic
    case nutrientDepletion = "nutrient_depletion"
    case additive
}

enum DBSeverityLevel: String, Codable {
    case minor
    case moderate
    case major
    case contraindicated
}

enum DBInteractionAction: String, Codable {
    case avoid
    case spaceDoses = "space_doses"
    case monitorLevels = "monitor_levels"
    case adjustDose = "adjust_dose"
    case informProvider = "inform_provider"
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
    let slug: String
    let category: DBSupplementCategory
    let commonDosageRange: String
    let recommendedDosageMg: Double
    let dosageUnit: String
    let timingOfDay: DBTimingOfDay
    let foodTiming: DBFoodTiming
    let evidenceClassification: DBEvidenceClassification
    let formAndBioavailability: String
    let dosageRationale: String
    let expectedTimeline: String
    let whatToLookFor: String
    let notes: String
    let availabilityTier: DBAvailabilityTier?
    let costTier: DBCostTier?
    let onsetMinDays: Int?
    let onsetMaxDays: Int?
    let onsetDescription: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, category
        case commonDosageRange = "common_dosage_range"
        case recommendedDosageMg = "recommended_dosage_mg"
        case dosageUnit = "dosage_unit"
        case timingOfDay = "timing_of_day"
        case foodTiming = "food_timing"
        case evidenceClassification = "evidence_classification"
        case formAndBioavailability = "form_and_bioavailability"
        case dosageRationale = "dosage_rationale"
        case expectedTimeline = "expected_timeline"
        case whatToLookFor = "what_to_look_for"
        case notes
        case availabilityTier = "availability_tier"
        case costTier = "cost_tier"
        case onsetMinDays = "onset_min_days"
        case onsetMaxDays = "onset_max_days"
        case onsetDescription = "onset_description"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Convert to the legacy Supplement type for compatibility during migration
    func toSupplement(benefits: [String] = [], contraindications: [String] = [], drugInteractions: [String] = []) -> Supplement {
        let timing: SupplementTiming
        if foodTiming == .withFood {
            timing = .withFood
        } else if foodTiming == .withoutFood {
            timing = .emptyStomach
        } else {
            timing = timingOfDay.toSupplementTiming
        }

        return Supplement(
            id: id,
            name: name,
            category: category.rawValue,
            commonDosageRange: commonDosageRange,
            recommendedDosageMg: recommendedDosageMg,
            recommendedTiming: timing,
            benefits: benefits,
            contraindications: contraindications,
            drugInteractions: drugInteractions,
            notes: notes,
            dosageRationale: dosageRationale,
            expectedTimeline: expectedTimeline,
            whatToLookFor: whatToLookFor,
            formAndBioavailability: formAndBioavailability,
            evidenceLevel: evidenceClassification.toEvidenceLevel
        )
    }
}

struct DBSupplementGoalMap: Codable, Identifiable {
    let id: UUID
    let supplementId: UUID
    let healthGoal: String
    let evidenceWeight: DBEvidenceWeight
    let evidenceClassification: DBEvidenceClassification?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case healthGoal = "health_goal"
        case evidenceWeight = "evidence_weight"
        case evidenceClassification = "evidence_classification"
    }
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
    let drugName: String
    let drugClass: String?
    let interactionType: DBInteractionType
    let severity: DBSeverityLevel
    let action: DBInteractionAction
    let explanation: String
    let supplementName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementId = "supplement_id"
        case drugName = "drug_name"
        case drugClass = "drug_class"
        case interactionType = "interaction_type"
        case severity, action, explanation
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
    let supplementAId: UUID
    let supplementBId: UUID
    let mechanism: String
    let directionality: DBSynergyDirectionality
    let evidence: DBSynergyEvidence
    let supplementAName: String?
    let supplementBName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case supplementAId = "supplement_a_id"
        case supplementBId = "supplement_b_id"
        case mechanism, directionality, evidence
        case supplementAName = "supplement_a_name"
        case supplementBName = "supplement_b_name"
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
