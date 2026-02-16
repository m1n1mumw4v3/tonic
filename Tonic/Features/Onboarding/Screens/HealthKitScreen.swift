import SwiftUI

struct HealthKitScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var headlineHeight: CGFloat = 48

    private let dataPoints: [(icon: String, label: String, color: Color)] = [
        ("bed.double.fill", "Sleep duration & quality", DesignTokens.accentSleep),
        ("heart.fill", "Heart rate", DesignTokens.accentHeart),
        ("waveform.path.ecg", "Heart rate variability (HRV)", DesignTokens.accentLongevity),
        ("figure.walk", "Daily steps", DesignTokens.accentGut),
        ("figure.run", "Workouts & activity", DesignTokens.accentMuscle)
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.spacing32) {
                        Spacer()
                            .frame(height: DesignTokens.spacing8)

                        // Header
                        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                            HStack(alignment: .center, spacing: DesignTokens.spacing12) {
                                Image("AppleHealthIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: headlineHeight, height: headlineHeight)
                                    .clipShape(RoundedRectangle(cornerRadius: headlineHeight * 0.22))

                                HeadlineText(text: "Connect Your Apple Health Account")
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear.preference(key: HeadlineHeightKey.self, value: geo.size.height)
                                        }
                                    )
                            }
                            .onPreferenceChange(HeadlineHeightKey.self) { headlineHeight = $0 }

                            Text("Ample can read your Apple health data to personalize recommendations even further.")
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
                                        .foregroundStyle(point.color)
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
                    }
                }

                Spacer()

                // CTAs
                VStack(spacing: DesignTokens.spacing8) {
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
                            .frame(height: DesignTokens.spacing32)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing8)
            }
        }
    }
}

private struct HeadlineHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    HealthKitScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
