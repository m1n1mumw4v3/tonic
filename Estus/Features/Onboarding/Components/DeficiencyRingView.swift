import SwiftUI

struct DeficiencyRingView: View {
    var percentage: CGFloat = 92
    var size: CGFloat = 180
    var animated: Bool = true

    @State private var animationProgress: CGFloat = 0

    private let strokeWidth: CGFloat = 12
    private let gapFraction: CGFloat = 0.005

    private var negativeFraction: CGFloat { percentage / 100 }
    private var positiveFraction: CGFloat { 1 - negativeFraction }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(DesignTokens.bgElevated, lineWidth: strokeWidth)
                .frame(width: size, height: size)

            // Negative (red) segment — 92%
            Circle()
                .trim(
                    from: 0,
                    to: negativeFraction * animationProgress
                )
                .stroke(
                    DesignTokens.negative,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center label
            VStack(spacing: -4) {
                Text("\(Int(percentage))%")
                    .font(.custom("Geist-Regular", size: 44))
                    .foregroundStyle(DesignTokens.textPrimary)

                Text("Deficient")
                    .font(.custom("Geist-Regular", size: 14))
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
        .onAppear {
            guard animated else {
                animationProgress = 1.0
                return
            }

            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
}

#Preview {
    DeficiencyRingView()
        .padding()
        .background(DesignTokens.bgDeepest)
}
