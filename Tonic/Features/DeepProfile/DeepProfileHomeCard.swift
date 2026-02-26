import SwiftUI

struct DeepProfileHomeCard: View {
    @Environment(AppState.self) private var appState
    @State private var showHub = false

    private var service: DeepProfileService {
        appState.deepProfileService
    }

    private var isComplete: Bool {
        service.isComplete
    }

    var body: some View {
        Button {
            HapticManager.impact(.light)
            showHub = true
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Green accent bar
                DesignTokens.positive
                    .frame(height: 2)

                VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                    // Module icon strip
                    moduleIconStrip

                    // Title row
                    HStack(spacing: DesignTokens.spacing8) {
                        Image(systemName: isComplete ? "checkmark.circle" : "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(DesignTokens.positive)

                        Text(isComplete ? "Profile Complete" : "Enhance Your Profile")
                            .font(DesignTokens.titleFont)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }

                    // Subtitle
                    Text(subtitleText)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Inline CTA
                    if !isComplete {
                        HStack(spacing: DesignTokens.spacing4) {
                            Text(service.hasStarted ? "Continue" : "Get Started")
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.positive)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DesignTokens.positive)
                        }
                    }
                }
                .padding(DesignTokens.spacing16)
            }
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(CardPressStyle())
        .sheet(isPresented: $showHub) {
            DeepProfileHubSheet()
                .environment(appState)
        }
    }

    // MARK: - Module Icon Strip

    private var moduleIconStrip: some View {
        HStack(spacing: DesignTokens.spacing8) {
            // General profile icon (always complete)
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(DesignTokens.accentEnergy.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DesignTokens.accentEnergy)
                    )

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignTokens.positive)
                    .background(
                        Circle()
                            .fill(DesignTokens.bgSurface)
                            .frame(width: 12, height: 12)
                    )
                    .offset(x: 2, y: 2)
            }

            ForEach(DeepProfileModuleType.allCases) { moduleType in
                let completed = service.isModuleCompleted(moduleType)

                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill((completed ? moduleType.accentColor : DesignTokens.textTertiary).opacity(0.15))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: moduleType.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(completed ? moduleType.accentColor : DesignTokens.textTertiary)
                        )

                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignTokens.positive)
                            .background(
                                Circle()
                                    .fill(DesignTokens.bgSurface)
                                    .frame(width: 12, height: 12)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
            }
        }
    }

    // MARK: - Subtitle

    private var subtitleText: String {
        if isComplete {
            return "Your profile is fully complete."
        } else if let next = service.nextIncompleteModule {
            return next.benefitCopy
        }
        return "Complete targeted health modules to fine-tune your supplement plan."
    }
}

// MARK: - Hub Sheet Wrapper

struct DeepProfileHubSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DeepProfileHub()
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(DesignTokens.bgDeepest)
    }
}
