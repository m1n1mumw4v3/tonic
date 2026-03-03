import SwiftUI

struct ValuePropProblemScreen: View {
    let onContinue: () -> Void

    @State private var showHeadline = false
    @State private var showPoints: [Bool] = [false, false, false, false]
    @State private var showGlow = false

    private let symptoms: [(color: Color, label: String, attribution: String)] = [
        (DesignTokens.accentEnergy, "Hit a wall every afternoon?", "It could be a Vitamin D deficiency."),
        (DesignTokens.accentMood, "Anxious for no clear reason?", "B Vitamins help regulate your stress response."),
        (DesignTokens.accentSleep, "Tired but can't fall asleep?", "Magnesium deficiency is the most common cause."),
        (DesignTokens.accentClarity, "Catch every cold going around?", "Your immune system may need Zinc.")
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero ring with radial glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DesignTokens.negative.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .blur(radius: 40)
                        .opacity(showGlow ? 1 : 0)

                    DeficiencyRingView()
                        .frame(width: 160, height: 160)
                }
                .padding(.bottom, 8)

                // Headline
                VStack(alignment: .leading, spacing: DesignTokens.spacing32) {
                    (Text("Did you know: 92% of people are deficient in at least one essential vitamin or mineral. ")
                        .font(.custom("Geist-Light", size: 22))
                        .foregroundStyle(DesignTokens.textPrimary)
                    + Text("(Source: The Journal of Nutrition)")
                        .font(.custom("Geist-Regular", size: 11))
                        .foregroundStyle(DesignTokens.textTertiary))
                    .opacity(showHeadline ? 1 : 0)
                    .offset(y: showHeadline ? 0 : 12)

                    // Symptom cards
                    VStack(spacing: DesignTokens.spacing8) {
                        ForEach(Array(symptoms.enumerated()), id: \.0) { index, symptom in
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(symptom.color)
                                    .frame(width: 3)
                                    .padding(.vertical, 4)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(symptom.label)
                                        .font(DesignTokens.captionFont.bold())
                                        .foregroundStyle(DesignTokens.textPrimary)

                                    Text(symptom.attribution)
                                        .font(.custom("Geist-Regular", size: 12))
                                        .foregroundStyle(DesignTokens.textSecondary)
                                }
                                .padding(.leading, DesignTokens.spacing16)

                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, DesignTokens.spacing16)
                            .fixedSize(horizontal: false, vertical: true)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                                    .fill(DesignTokens.bgElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                                            .stroke(DesignTokens.borderSubtle, lineWidth: 1)
                                    )
                            )
                            .opacity(showPoints[index] ? 1 : 0)
                            .offset(y: showPoints[index] ? 0 : 8)
                        }
                    }

                }
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer(minLength: DesignTokens.spacing24)

                // CTA
                CTAButton(title: "Continue", style: .primary, action: onContinue)
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onAppear {
            // Glow fades in with ring fill
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.8)) {
                    showGlow = true
                }
            }

            // Headline slides up after ring starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showHeadline = true
                }
            }

            // Points stagger in
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.15) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showPoints[i] = true
                    }
                }
            }

            // TODO: PostHog — value_prop_screen_viewed (screen: "problem")
        }
    }
}

#Preview {
    ValuePropProblemScreen(onContinue: {})
}
