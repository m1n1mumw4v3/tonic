import Foundation

struct SupplementPlan: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var createdAt: Date = Date()
    var isActive: Bool = true
    var version: Int = 1
    var aiReasoning: String?
    var supplements: [PlanSupplement] = []

    enum CodingKeys: String, CodingKey {
        case id, userId, createdAt, isActive, version, aiReasoning, supplements
    }
}

extension SupplementPlan {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        aiReasoning = try container.decodeIfPresent(String.self, forKey: .aiReasoning)
        // Lossy decode: skip individual supplements that fail instead of losing the whole plan
        if container.contains(.supplements) {
            var supplementsContainer = try container.nestedUnkeyedContainer(forKey: .supplements)
            var decoded: [PlanSupplement] = []
            while !supplementsContainer.isAtEnd {
                do {
                    let supplement = try supplementsContainer.decode(PlanSupplement.self)
                    decoded.append(supplement)
                } catch {
                    // Skip this supplement but continue decoding the rest
                    _ = try? supplementsContainer.decode(AnyCodable.self)
                    print("⚠️ [Restore] Skipped undecodable supplement: \(error)")
                }
            }
            supplements = decoded
        } else {
            supplements = []
        }
    }
}

/// Throwaway type to advance the decoder past an undecodable element.
private struct AnyCodable: Decodable {
    init(from decoder: Decoder) throws {
        _ = try decoder.singleValueContainer()
    }
}

struct PlanSupplement: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var planId: UUID?
    var supplementId: UUID?
    var name: String
    var dosage: String
    var dosageMg: Double?
    var timing: SupplementTiming
    var frequency: SupplementFrequency = .daily
    var reasoning: String?
    var category: String = ""
    var sortOrder: Int = 0
    var isTaken: Bool = false

    // Plan reveal fields
    var tier: SupplementTier = .supporting
    var matchedGoals: [String] = []
    var tierScore: Int = 0
    var isIncluded: Bool = true
    var isRemoved: Bool = false
    var researchNote: String?

    // Enriched information fields
    var whyInYourPlan: String?
    var dosageRationale: String?
    var expectedTimeline: String?
    var whatToLookFor: String?
    var formAndBioavailability: String?
    var interactionNote: String?
    var evidenceDisplay: String?
    var evidenceLevel: EvidenceLevel?
    var interactionWarnings: [InteractionWarning]?
    var formUpgradeNote: String?

    enum CodingKeys: String, CodingKey {
        case id, planId, supplementId, name, dosage, dosageMg, timing, frequency
        case reasoning, category, sortOrder, isTaken, tier, matchedGoals
        case tierScore = "goalOverlapScore"
        case isIncluded, isRemoved, researchNote
        case whyInYourPlan, dosageRationale, expectedTimeline
        case whatToLookFor, formAndBioavailability, interactionNote
        case evidenceDisplay, evidenceLevel, interactionWarnings
        case formUpgradeNote
    }

    static func == (lhs: PlanSupplement, rhs: PlanSupplement) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Resilient Decoder

extension PlanSupplement {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        planId = try container.decodeIfPresent(UUID.self, forKey: .planId)
        supplementId = try container.decodeIfPresent(UUID.self, forKey: .supplementId)
        name = try container.decode(String.self, forKey: .name)
        dosage = try container.decode(String.self, forKey: .dosage)
        dosageMg = try container.decodeIfPresent(Double.self, forKey: .dosageMg)
        timing = try container.decode(SupplementTiming.self, forKey: .timing)
        frequency = try container.decodeIfPresent(SupplementFrequency.self, forKey: .frequency) ?? .daily
        reasoning = try container.decodeIfPresent(String.self, forKey: .reasoning)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        isTaken = try container.decodeIfPresent(Bool.self, forKey: .isTaken) ?? false
        tier = try container.decodeIfPresent(SupplementTier.self, forKey: .tier) ?? .supporting
        matchedGoals = try container.decodeIfPresent([String].self, forKey: .matchedGoals) ?? []
        tierScore = try container.decodeIfPresent(Int.self, forKey: .tierScore) ?? 0
        isIncluded = try container.decodeIfPresent(Bool.self, forKey: .isIncluded) ?? true
        isRemoved = try container.decodeIfPresent(Bool.self, forKey: .isRemoved) ?? false
        researchNote = try container.decodeIfPresent(String.self, forKey: .researchNote)
        whyInYourPlan = try container.decodeIfPresent(String.self, forKey: .whyInYourPlan)
        dosageRationale = try container.decodeIfPresent(String.self, forKey: .dosageRationale)
        expectedTimeline = try container.decodeIfPresent(String.self, forKey: .expectedTimeline)
        whatToLookFor = try container.decodeIfPresent(String.self, forKey: .whatToLookFor)
        formAndBioavailability = try container.decodeIfPresent(String.self, forKey: .formAndBioavailability)
        interactionNote = try container.decodeIfPresent(String.self, forKey: .interactionNote)
        evidenceDisplay = try container.decodeIfPresent(String.self, forKey: .evidenceDisplay)
        evidenceLevel = try container.decodeIfPresent(EvidenceLevel.self, forKey: .evidenceLevel)
        interactionWarnings = try container.decodeIfPresent([InteractionWarning].self, forKey: .interactionWarnings)
        formUpgradeNote = try container.decodeIfPresent(String.self, forKey: .formUpgradeNote)
    }
}

enum SupplementTier: String, Codable, CaseIterable, Identifiable {
    case core
    case targeted
    case supporting

    var id: String { rawValue }

    var label: String {
        switch self {
        case .core: return "CORE"
        case .targeted: return "TARGETED"
        case .supporting: return "SUPPORTING"
        }
    }

    var description: String {
        switch self {
        case .core: return "Highest impact for your profile"
        case .targeted: return "Strong support for your goals"
        case .supporting: return "Complementary additions"
        }
    }

    var icon: String {
        switch self {
        case .core: return "star.fill"
        case .targeted: return "scope"
        case .supporting: return "plus.circle"
        }
    }

    var sortOrder: Int {
        switch self {
        case .core: return 0
        case .targeted: return 1
        case .supporting: return 2
        }
    }
}

enum SupplementTiming: String, Codable, CaseIterable, Identifiable {
    case morning
    case afternoon
    case evening
    case bedtime
    case withFood = "with_food"
    case emptyStomach = "empty_stomach"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .bedtime: return "Bedtime"
        case .withFood: return "With Food"
        case .emptyStomach: return "Empty Stomach"
        }
    }

    var sortOrder: Int {
        switch self {
        case .emptyStomach: return 0
        case .morning: return 1
        case .withFood: return 2
        case .afternoon: return 3
        case .evening: return 4
        case .bedtime: return 5
        }
    }

    var isFoodRelated: Bool {
        switch self {
        case .withFood, .emptyStomach: return true
        default: return false
        }
    }
}

enum SupplementFrequency: String, Codable {
    case daily
    case everyOtherDay = "every_other_day"
    case weekly
    case asNeeded = "as_needed"
}

struct InteractionWarning: Codable, Identifiable {
    let id: UUID
    let drugOrClass: String
    let interactionType: String
    let severity: String
    let mechanism: String
    let action: String
}
