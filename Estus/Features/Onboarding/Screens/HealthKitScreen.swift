import SwiftUI

struct HealthKitScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @Environment(AppState.self) private var appState
    @State private var headlineHeight: CGFloat = 48
    @State private var isConnecting: Bool = false
    @State private var showDeniedAlert: Bool = false
    @State private var showUnavailableAlert: Bool = false

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

                            Text("Estus can read your Apple health data to personalize recommendations even further.")
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
                    CTAButton(
                        title: isConnecting ? "Connecting..." : "Connect Apple Health",
                        style: .primary
                    ) {
                        Task { await connectHealthKit() }
                    }
                    .disabled(isConnecting)
                    .opacity(isConnecting ? 0.6 : 1.0)

                    Button {
                        onContinue()
                    } label: {
                        Text("Skip for now")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignTokens.spacing32)
                    }
                    .disabled(isConnecting)
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing8)
            }
        }
        .alert("Apple Health Unavailable", isPresented: $showUnavailableAlert) {
            Button("Continue") {
                onContinue()
            }
        } message: {
            Text("Apple Health is not available on this device. You can connect it later on a supported device.")
        }
        .alert("Apple Health Access", isPresented: $showDeniedAlert) {
            Button("Continue Without") {
                onContinue()
            }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Estus needs permission to read your health data. You can enable this in Settings > Privacy > Health.")
        }
    }

    private func connectHealthKit() async {
        guard HealthKitService.isAvailable else {
            showUnavailableAlert = true
            return
        }

        isConnecting = true
        defer { isConnecting = false }

        let authorized = await appState.healthKitService.requestAuthorization()

        guard authorized else {
            showDeniedAlert = true
            return
        }

        viewModel.healthKitEnabled = true

        let metrics = await appState.healthKitService.fetchAllMetrics()
        viewModel.healthMetrics = metrics

        // Auto-fill sex from HealthKit biological sex
        if let bioSex = metrics.biologicalSex {
            viewModel.sex = bioSex.toSex
            viewModel.healthKitProvidedSex = true
        }

        onContinue()
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
        .environment(AppState())
}
