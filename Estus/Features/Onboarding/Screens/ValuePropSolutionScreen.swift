import SwiftUI

struct ValuePropSolutionScreen: View {
    let onContinue: () -> Void

    @State private var showHeadline = false
    @State private var showSteps: [Bool] = [false, false, false]
    @State private var showPhone = false

    private let steps: [(number: String, title: String, description: String)] = [
        ("1", "Complete Your Profile",   "Share your health, goals & lifestyle"),
        ("2", "Receive a Personalized Plan",  "Receive specific supplement recommendations, tailored doses, and more"),
        ("3", "Track & Refine",  "Log how you feel, we adapt over time"),
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: DesignTokens.spacing24)

                        // Headline
                        HeadlineText(
                            text: "Estus takes the guesswork out of feeling your best.",
                            fontSize: 22
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignTokens.spacing24)
                        .padding(.bottom, DesignTokens.spacing16)
                        .opacity(showHeadline ? 1 : 0)
                        .offset(y: showHeadline ? 0 : 12)

                        // Phone mockup
                        phoneMockup
                            .padding(.horizontal, DesignTokens.spacing32)
                            .padding(.top, DesignTokens.spacing16)
                            .padding(.bottom, -24)
                            .opacity(showPhone ? 1 : 0)
                            .offset(y: showPhone ? 0 : 20)
                            .zIndex(0)

                        // Steps card
                        VStack(alignment: .leading, spacing: DesignTokens.spacing20) {
                            // Section header
                            Text("How it works")
                                .font(.custom("Geist-Regular", size: 16))
                                .foregroundStyle(DesignTokens.textPrimary)

                            // Timeline steps
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(steps.enumerated()), id: \.0) { index, step in
                                    HStack(alignment: .top, spacing: DesignTokens.spacing12) {
                                        // Number circle + connector
                                        ZStack(alignment: .top) {
                                            // Connector line drawn first, behind the circle
                                            if index < steps.count - 1 {
                                                Rectangle()
                                                    .fill(DesignTokens.borderDefault)
                                                    .frame(width: 1.5)
                                                    .frame(maxHeight: .infinity)
                                                    .padding(.top, 20) // start below circle center
                                            }

                                            // Opaque background to mask the connector line
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle()
                                                        .stroke(DesignTokens.accentMood, lineWidth: 1)
                                                )

                                            Text(step.number)
                                                .font(.custom("GeistMono-Medium", size: 12))
                                                .foregroundStyle(DesignTokens.accentMood)
                                                .frame(width: 24, height: 24)
                                        }
                                        .frame(width: 24)

                                        // Title + description
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(step.title)
                                                .font(.custom("Geist-Regular", size: 14))
                                                .foregroundStyle(DesignTokens.textPrimary)

                                            Text(step.description)
                                                .font(.custom("Geist-Regular", size: 13))
                                                .foregroundStyle(DesignTokens.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.top, 2)
                                        .padding(.bottom, index < steps.count - 1 ? DesignTokens.spacing20 : 0)
                                    }
                                    .opacity(showSteps[index] ? 1 : 0)
                                    .offset(y: showSteps[index] ? 0 : 8)
                                }
                            }
                        }
                        .padding(DesignTokens.spacing16)
                        .background(DesignTokens.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                                .stroke(DesignTokens.borderDefault, lineWidth: 1)
                        )
                        .padding(.horizontal, DesignTokens.spacing24)
                        .padding(.bottom, DesignTokens.spacing16)
                        .zIndex(1)
                    }
                }

                // CTA pinned outside scroll
                CTAButton(title: "Let's Design Your Plan", style: .primary, action: onContinue)
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.top, DesignTokens.spacing16)

                // Affiliate disclosure
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .padding(.top, 1)

                    Text("Estus may earn a commission on partner purchases. Recommendations are always based on your profile.")
                        .font(.custom("Geist-Regular", size: 11))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.top, DesignTokens.spacing8)
                .padding(.bottom, DesignTokens.spacing24)
            }
        }
        .onAppear {
            // Headline fades in first
            withAnimation(.easeOut(duration: 0.5)) {
                showHeadline = true
            }

            // Phone mockup fades in after headline
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showPhone = true
                }
            }

            // Steps stagger
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + Double(i) * 0.15) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSteps[i] = true
                    }
                }
            }

            // TODO: PostHog — value_prop_screen_viewed (screen: "solution")
        }
    }

    // MARK: - Phone Mockup

    private var phoneMockup: some View {
        let bezelWidth: CGFloat = 6
        let outerRadius: CGFloat = 44
        let innerRadius = outerRadius - bezelWidth

        return VStack(spacing: 0) {
            // Status bar — clears the floating dynamic island
            HStack {
                Text("9:41")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.textSecondary)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "cellularbars")
                        .font(.system(size: 12))
                    Image(systemName: "wifi")
                        .font(.system(size: 12))
                    Image(systemName: "battery.75percent")
                        .font(.system(size: 14))
                }
                .foregroundStyle(DesignTokens.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)

            Image("PlanRevealMockup")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
            .background(DesignTokens.bgDeepest)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: innerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: innerRadius,
                    style: .continuous
                )
            )
            .padding(.horizontal, bezelWidth)
            .padding(.top, bezelWidth)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: outerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: outerRadius,
                    style: .continuous
                )
                .fill(Color.black)
            )
            .overlay(alignment: .top) {
                // Dynamic Island floats over the screen
                Capsule()
                    .fill(Color.black)
                    .frame(width: 100, height: 28)
                    .padding(.top, bezelWidth + 8)
            }
            .overlay(
                // Subtle top highlight on the bezel for depth
                UnevenRoundedRectangle(
                    topLeadingRadius: outerRadius,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: outerRadius,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0)],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
            )
            .shadow(color: .black.opacity(0.18), radius: 28, y: 10)
    }
}

#Preview {
    ValuePropSolutionScreen(onContinue: {})
}
