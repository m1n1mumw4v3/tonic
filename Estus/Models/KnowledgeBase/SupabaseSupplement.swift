import Foundation

struct SupabaseSupplement: Codable, Identifiable {
    let id: UUID
    let name: String
    let commonNames: [String]?
    let category: String
    let primaryAction: String?
    let defaultForm: String?
    let defaultDose: String?
    let doseRangeLow: String?
    let doseRangeHigh: String?
    let upperTolerableLimit: String?
    let toxicityThreshold: String?
    let timeOfDay: String?
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
        case doseRangeLow = "dose_range_low"
        case doseRangeHigh = "dose_range_high"
        case upperTolerableLimit = "upper_tolerable_limit"
        case toxicityThreshold = "toxicity_threshold"
        case timeOfDay = "time_of_day"
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
}
