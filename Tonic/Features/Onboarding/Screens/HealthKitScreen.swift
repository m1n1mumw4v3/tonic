import SwiftUI

struct HealthKitScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private let dataPoints: [(icon: String, label: String)] = [
        ("bed.double.fill", "Sleep duration & quality"),
        ("heart.fill", "Heart rate"),
        ("waveform.path.ecg", "Heart rate variability (HRV)"),
        ("figure.walk", "Daily steps"),
        ("figure.run", "Workouts & activity")
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing32) {
                    Spacer()
                        .frame(height: DesignTokens.spacing8)

                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                        HeadlineText(text: "Connect Apple Health\nfor richer insights")

                        Text("Tonic can read your health data to personalize recommendations even further.")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, DesignTokens.spacing24)

                    // Data points list
                    VStack(spacing: 0) {
                        ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                            HStack(spacing: DesignTokens.spacing16) {
                                Image(systemName: point.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(DesignTokens.accentClarity)
                                    .frame(width: 28, alignment: .center)

                                Text(point.label)
                                    .font(DesignTokens.bodyFont)
                                    .foregroundStyle(DesignTokens.textPrimary)

                                Spacer()
                            }
                            .padding(.vertical, DesignTokens.spacing12)
                            .padding(.horizontal, DesignTokens.spacing16)

                            if index < dataPoints.count - 1 {
                                Divider()
                                    .background(DesignTokens.borderSubtle)
                                    .padding(.leading, DesignTokens.spacing16 + 28 + DesignTokens.spacing16)
                            }
                        }
                    }
                    .background(DesignTokens.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                            .stroke(DesignTokens.borderDefault, lineWidth: 1)
                    )
                    .padding(.horizontal, DesignTokens.spacing24)

                    // Privacy assurance
                    HStack(alignment: .top, spacing: DesignTokens.spacing8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.positive)
                            .padding(.top, 2)

                        Text("Your data stays on-device and is never shared. You can disconnect at any time in Settings.")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textTertiary)
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, DesignTokens.spacing24)

                    Spacer()
                        .frame(height: DesignTokens.spacing16)

                    // CTAs
                    VStack(spacing: DesignTokens.spacing4) {
                        CTAButton(title: "Connect Apple Health", style: .primary) {
                            viewModel.healthKitEnabled = true
                            onContinue()
                        }

                        Button {
                            onContinue()
                        } label: {
                            Text("Skip for now")
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignTokens.spacing12)
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
                }
            }
        }
    }
}

#Preview {
    HealthKitScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
