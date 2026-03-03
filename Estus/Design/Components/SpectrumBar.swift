import SwiftUI

struct SpectrumBar: View {
    var height: CGFloat = 3
    var progress: CGFloat = 1.0 // 0.0 to 1.0

    private let colors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentMood,
        DesignTokens.accentGut
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(DesignTokens.bgElevated)
                    .frame(height: height)

                // Gradient fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: height)
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        SpectrumBar(progress: 0.3)
        SpectrumBar(progress: 0.6)
        SpectrumBar(progress: 1.0)
        SpectrumBar(height: 6, progress: 1.0)
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}
