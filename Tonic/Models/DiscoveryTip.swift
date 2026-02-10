import SwiftUI

struct DiscoveryTip: Identifiable {
    let id = UUID()
    let category: DiscoveryTipCategory
    let title: String
    let body: String
    let accentColor: Color
    let supplementName: String?

    init(category: DiscoveryTipCategory, title: String, body: String, accentColor: Color, supplementName: String? = nil) {
        self.category = category
        self.title = title
        self.body = body
        self.accentColor = accentColor
        self.supplementName = supplementName
    }
}

enum DiscoveryTipCategory {
    case didYouKnow
    case habitTip
    case supplementFact

    var label: String {
        switch self {
        case .didYouKnow: return "DID YOU KNOW"
        case .habitTip: return "HABIT TIP"
        case .supplementFact: return "YOUR PLAN"
        }
    }
}
