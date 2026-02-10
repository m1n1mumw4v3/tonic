import SwiftUI

struct DiscoveryCarousel: View {
    let tips: [DiscoveryTip]
    @State private var currentPage: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            // Section header
            Text("DISCOVER YOUR PLAN")
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            // Horizontal carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: DesignTokens.spacing12) {
                    ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                        DiscoveryCard(tip: tip)
                            .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: Binding(
                get: { currentPage },
                set: { newValue in
                    if let newValue { currentPage = newValue }
                }
            ))
            .contentMargins(.horizontal, 0, for: .scrollContent)

            // Page dots
            if tips.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<tips.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? DesignTokens.info : DesignTokens.textTertiary)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    let tips = [
        DiscoveryTip(
            category: .didYouKnow,
            title: "Magnesium Glycinate",
            body: "Magnesium is involved in 300+ enzymatic reactions in your body.",
            accentColor: DesignTokens.accentSleep,
            supplementName: "Magnesium Glycinate"
        ),
        DiscoveryTip(
            category: .habitTip,
            title: "Consistency Beats Perfection",
            body: "21 days of consistency builds lasting habits. Don't worry about being perfect — just keep showing up.",
            accentColor: DesignTokens.positive
        ),
        DiscoveryTip(
            category: .supplementFact,
            title: "Omega-3 Tip",
            body: "Take with a meal containing fat for better absorption.",
            accentColor: DesignTokens.accentClarity,
            supplementName: "Omega-3 (EPA/DHA)"
        ),
    ]

    return DiscoveryCarousel(tips: tips)
        .padding(.horizontal, DesignTokens.spacing16)
        .background(DesignTokens.bgDeepest)
}
