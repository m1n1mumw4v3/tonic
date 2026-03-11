import SwiftUI

struct PhaseCalloutRow: View {
    let icon: String
    let label: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 18, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                Text(label)
                    .font(DesignTokens.smallMono)
                    .tracking(0.8)
                    .foregroundStyle(DesignTokens.textSecondary)

                Text(text)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
    }
}

#Preview {
    VStack(spacing: 12) {
        PhaseCalloutRow(
            icon: "eye",
            label: "WHAT TO WATCH FOR",
            text: "A subtle calming sensation in the evenings. Some people notice relaxed muscles within the first few doses.",
            color: DesignTokens.accentSleep
        )

        PhaseCalloutRow(
            icon: "flag",
            label: "NEXT MILESTONE",
            text: "By day 3-4, you may notice easier sleep onset as GABA receptor activity begins to normalize.",
            color: DesignTokens.info
        )
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}
