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
                            text: "Ample takes the guesswork out of feeling your best.",
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
                            .padding(.bottom, -24)
                            .opacity(showPhone ? 1 : 0)
                            .offset(y: showPhone ? 0 : 20)
                            .zIndex(0)

                        // Steps card
                        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                            // Section header
                            Text("HOW IT WORKS")
                                .font(.custom("GeistMono-Medium", size: 11))
                                .tracking(1.2)
                                .foregroundStyle(Color.white.opacity(0.6))

                            // Timeline steps
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(steps.enumerated()), id: \.0) { index, step in
                                    HStack(alignment: .top, spacing: DesignTokens.spacing12) {
                                        // Number circle + connector
                                        ZStack(alignment: .top) {
                                            // Connector line drawn first, behind the circle
                                            if index < steps.count - 1 {
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.25))
                                                    .frame(width: 1.5)
                                                    .frame(maxHeight: .infinity)
                                                    .padding(.top, 20) // start below circle center
                                            }

                                            // Opaque background to mask the connector line
                                            Circle()
                                                .fill(Color(hex: "8C7E6A"))
                                                .frame(width: 24, height: 24)

                                            Circle()
                                                .fill(Color.white.opacity(0.15))
                                                .frame(width: 24, height: 24)

                                            Text(step.number)
                                                .font(.custom("GeistMono-Medium", size: 12))
                                                .foregroundStyle(Color.white)
                                                .frame(width: 24, height: 24)
                                        }
                                        .frame(width: 24)

                                        // Title + description
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(step.title)
                                                .font(.custom("Geist-Medium", size: 14))
                                                .foregroundStyle(Color.white)

                                            Text(step.description)
                                                .font(.custom("Geist-Regular", size: 13))
                                                .foregroundStyle(Color.white.opacity(0.7))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.top, 2)
                                        .padding(.bottom, index < steps.count - 1 ? DesignTokens.spacing12 : 0)
                                    }
                                    .opacity(showSteps[index] ? 1 : 0)
                                    .offset(y: showSteps[index] ? 0 : 8)
                                }
                            }
                        }
                        .padding(DesignTokens.spacing16)
                        .background(Color(hex: "8C7E6A"))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, DesignTokens.spacing24)
                        .padding(.bottom, DesignTokens.spacing16)
                        .zIndex(1)
                    }
                }

                // CTA pinned outside scroll
                CTAButton(title: "Let's Design Your Plan", style: .primary, action: onContinue)
                .padding(.horizontal, DesignTokens.spacing24)

                // Affiliate disclosure
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .padding(.top, 1)

                    Text("Ample may earn a commission on partner purchases. Recommendations are always based on your profile.")
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
        VStack(spacing: 0) {
            // Dynamic Island
            Capsule()
                .fill(Color.black)
                .frame(width: 76, height: 22)
                .padding(.top, 10)

            // Status bar
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
            .padding(.top, 6)

            // Plan header
            Text("YOUR PLAN")
                .font(.custom("GeistMono-Medium", size: 9))
                .tracking(1.2)
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 6)

            // Goal chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    mockGoalChip(icon: "moon.fill", label: "Sleep", color: DesignTokens.accentSleep)
                    mockGoalChip(icon: "bolt.fill", label: "Energy", color: DesignTokens.accentEnergy)
                    mockGoalChip(icon: "brain.head.profile", label: "Focus", color: DesignTokens.accentClarity)
                    mockGoalChip(icon: "figure.mind.and.body", label: "Stress", color: DesignTokens.accentMood)
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 10)

            // Mock supplement cards
            VStack(spacing: 6) {
                mockSupplementRow(name: "Magnesium Glycinate", dosage: "400 mg", timing: "Bedtime", accent: DesignTokens.accentSleep)
                mockSupplementRow(name: "Ashwagandha KSM-66", dosage: "600 mg", timing: "Morning", accent: DesignTokens.accentMood)
                mockSupplementRow(name: "Omega-3 Fish Oil", dosage: "1000 mg", timing: "With Food", accent: DesignTokens.accentClarity)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(
            DesignTokens.bgElevated
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28))
        )
        .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
        .overlay(
            SolutionPhoneFrameShape(cornerRadius: 28)
                .stroke(DesignTokens.textTertiary.opacity(0.4), lineWidth: 2)
        )
        .overlay(
            // Inner top highlight for depth
            UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0)],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .padding(2)
        )
    }

    private func mockSupplementRow(name: String, dosage: String, timing: String, accent: Color) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accent)
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.custom("Geist-Medium", size: 11))
                    .foregroundStyle(DesignTokens.textPrimary)

                HStack(spacing: 4) {
                    Text(dosage)
                        .font(.custom("GeistMono-Medium", size: 9))
                        .foregroundStyle(DesignTokens.info)

                    Text("·")
                        .font(.system(size: 8))
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text(timing)
                        .font(.custom("GeistMono-Medium", size: 9))
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 2) {
                Text("More")
                    .font(.custom("Geist-Regular", size: 9))
                Image(systemName: "chevron.right")
                    .font(.system(size: 7, weight: .semibold))
            }
            .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DesignTokens.bgDeepest)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func mockGoalChip(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.custom("GeistMono-Medium", size: 9))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.18))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 0.5))
    }
}

// MARK: - Phone Frame Shape (open bottom)

private struct SolutionPhoneFrameShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

#Preview {
    ValuePropSolutionScreen(onContinue: {})
}
