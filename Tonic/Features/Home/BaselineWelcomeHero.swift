import SwiftUI

struct BaselineWelcomeHero: View {
    let user: UserProfile
    let onCheckIn: () -> Void

    @State private var showHeader = false
    @State private var showRing = false
    @State private var showCTA = false

    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var body: some View {
        VStack(spacing: DesignTokens.spacing16) {
            // Decorative spectrum bar + header
            if showHeader || reduceMotion {
                SpectrumBar(height: 2)

                Text("YOUR BASELINE WELLBEING SCORE")
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            // Wellbeing ring with baseline scores
            if showRing || reduceMotion {
                WellbeingScoreRing(
                    sleepScore: user.baselineSleep,
                    energyScore: user.baselineEnergy,
                    clarityScore: user.baselineClarity,
                    moodScore: user.baselineMood,
                    gutScore: user.baselineGut
                )
            }

            // CTA section
            if showCTA || reduceMotion {
                VStack(spacing: DesignTokens.spacing12) {
                    Text("See how today compares")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    CTAButton(
                        title: "Start Your First Check-in",
                        style: .primary,
                        action: onCheckIn,
                        spectrumBorder: true
                    )
                }
            }
        }
        .cardStyle()
        .onAppear {
            if reduceMotion {
                return
            }
            withAnimation(.easeOut(duration: 0.3)) {
                showHeader = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showRing = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showCTA = true
                }
            }
        }
    }
}

#Preview {
    let user = UserProfile(
        firstName: "Matt",
        baselineSleep: 5,
        baselineEnergy: 6,
        baselineClarity: 5,
        baselineMood: 7,
        baselineGut: 5
    )
    return BaselineWelcomeHero(user: user, onCheckIn: {})
        .padding()
        .background(DesignTokens.bgDeepest)
}
