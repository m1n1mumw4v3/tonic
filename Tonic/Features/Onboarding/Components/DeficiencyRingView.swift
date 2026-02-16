import SwiftUI

struct DeficiencyRingView: View {
    var percentage: CGFloat = 92
    var size: CGFloat = 180
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animationProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var isBreathing = false

    private let strokeWidth: CGFloat = 12
    private let gapFraction: CGFloat = 0.005

    private var negativeFraction: CGFloat { percentage / 100 }
    private var positiveFraction: CGFloat { 1 - negativeFraction }

    private var displayedPercentage: Int {
        Int(percentage * animationProgress)
    }

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
                    to: (negativeFraction - gapFraction) * animationProgress
                )
                .stroke(
                    DesignTokens.negative,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Positive (green) segment — 8%
            Circle()
                .trim(
                    from: (negativeFraction + gapFraction) * animationProgress,
                    to: animationProgress
                )
                .stroke(
                    DesignTokens.accentGut,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center label
            VStack(spacing: 2) {
                Text("\(displayedPercentage)%")
                    .font(.custom("GeistMono-Medium", size: 44))
                    .foregroundStyle(DesignTokens.textPrimary)

                Text("DEFICIENT")
                    .font(.custom("GeistMono-Regular", size: 10))
                    .tracking(1.2)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
        .scaleEffect(pulseScale)
        .scaleEffect(isBreathing ? 1.02 : 1.0)
        .animation(
            isBreathing
                ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                : .default,
            value: isBreathing
        )
        .onAppear {
            guard animated else {
                animationProgress = 1.0
                return
            }

            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = 1.0
            }

            // Pulse on completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    pulseScale = 1.03
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        pulseScale = 1.0
                    }
                }
            }

            // Start breathing after entrance animation settles
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
                    isBreathing = true
                }
            }
        }
    }
}

#Preview {
    DeficiencyRingView()
        .padding()
        .background(DesignTokens.bgDeepest)
}
