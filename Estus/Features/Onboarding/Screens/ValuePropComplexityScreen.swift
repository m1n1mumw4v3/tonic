import SwiftUI

struct ValuePropComplexityScreen: View {
    let onContinue: () -> Void

    @State private var countUpValue: Int = 0
    @State private var showHeadline = false
    @State private var showPoints: [Bool] = [false, false, false]

    private let targetCount = 90_000

    private let supportingPoints = [
        "Every brand claims theirs is the best. Most can't back it up.",
        "Even when the science is real, the wrong form, wrong dose, or wrong timing means you're flushing money down the drain.",
        "You shouldn't need a biochemistry degree to confidently take care of your health."
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: DesignTokens.spacing24)

                // Hero: supplement cloud
                SupplementCloudView()
                    .frame(height: 220)
                    .padding(.bottom, DesignTokens.spacing16)

                // Headline
                VStack(alignment: .leading, spacing: DesignTokens.spacing20) {
                    // Stat
                    Text("\(formattedCount)+")
                        .font(.custom("Geist-SemiBold", size: 56))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .padding(.bottom, -20)

                    HeadlineText(
                        text: "supplements on the market",
                        fontSize: 22
                    )
                    .opacity(showHeadline ? 1 : 0)
                    .offset(y: showHeadline ? 0 : 12)

                    // Supporting points
                    VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
                        ForEach(Array(supportingPoints.enumerated()), id: \.0) { index, point in
                            Text(point)
                                .font(.custom("Geist-Regular", size: 14))
                                .foregroundStyle(DesignTokens.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .opacity(showPoints[index] ? 1 : 0)
                                .offset(y: showPoints[index] ? 0 : 8)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                // CTA
                CTAButton(title: "Continue", style: .primary, action: onContinue)
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onAppear {
            // Count up animation
            animateCount()

            // Headline
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showHeadline = true
                }
            }

            // Points stagger
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.15) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showPoints[i] = true
                    }
                }
            }

            // TODO: PostHog — value_prop_screen_viewed (screen: "complexity")
        }
    }

    private var formattedCount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: countUpValue)) ?? "\(countUpValue)"
    }

    private func animateCount() {
        let duration: Double = 1.0
        let steps = 30
        let interval = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                let progress = easeOutCurve(Double(step) / Double(steps))
                countUpValue = Int(Double(targetCount) * progress)
            }
        }
    }

    private func easeOutCurve(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }
}

#Preview {
    ValuePropComplexityScreen(onContinue: {})
}
