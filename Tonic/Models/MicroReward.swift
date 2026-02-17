import SwiftUI

// MARK: - Micro-Reward Content

enum MicroRewardContent {
    case timeline(SupplementMilestone)
    case adherence(AdherenceInsight)
    case tip(SupplementTip)
}

// MARK: - Supplement Milestone (Priority 1)

struct SupplementMilestone {
    let supplementName: String
    let dayCount: Int
    let onsetMin: Int
    let onsetMax: Int
    let message: String
    let accentColor: Color
}

// MARK: - Adherence Insight (Priority 2)

struct AdherenceInsight {
    let message: String
    let adherencePercent: Int
    let accentColor: Color
}

// MARK: - Supplement Tip (Priority 3)

struct SupplementTip {
    let supplementName: String?
    let message: String
    let accentColor: Color
}
