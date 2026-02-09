import Foundation

struct SupplementPlan: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var createdAt: Date = Date()
    var isActive: Bool = true
    var version: Int = 1
    var aiReasoning: String?
    var supplements: [PlanSupplement] = []
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
    var goalOverlapScore: Int = 0
    var isIncluded: Bool = true
    var researchNote: String?

    static func == (lhs: PlanSupplement, rhs: PlanSupplement) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
        case .core: return "Works across multiple goals"
        case .targeted: return "Focused on a specific goal"
        case .supporting: return "Rounds out your plan"
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
}

enum SupplementFrequency: String, Codable {
    case daily
    case everyOtherDay = "every_other_day"
    case weekly
    case asNeeded = "as_needed"
}
