import SwiftUI

struct TimelineSummaryCard: View {
    let summary: TimelineSummaryData

    var body: some View {
        HStack(spacing: DesignTokens.spacing12) {
            CompactProgressRing(
                progress: summary.totalSupplements > 0
                    ? Double(summary.supplementsInOnsetOrLater) / Double(summary.totalSupplements)
                    : 0,
                size: 40,
                lineWidth: 3.5,
                label: "\(summary.supplementsInOnsetOrLater)/\(summary.totalSupplements)"
            )

            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                Text("\(summary.supplementsInOnsetOrLater) supplement\(summary.supplementsInOnsetOrLater == 1 ? "" : "s") in Onset or later")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)

                Text(summary.summaryText)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: 16) {
        TimelineSummaryCard(summary: TimelineSummaryData(
            supplementsInOnsetOrLater: 3,
            totalSupplements: 6,
            summaryText: "L-Theanine reached Onset this week. Omega-3 has the longest road ahead."
        ))

        TimelineSummaryCard(summary: TimelineSummaryData(
            supplementsInOnsetOrLater: 0,
            totalSupplements: 5,
            summaryText: "All supplements are in their early phases. Consistency is key right now."
        ))
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}
