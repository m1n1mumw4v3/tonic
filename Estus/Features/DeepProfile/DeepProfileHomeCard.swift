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

    /// Includes onboarding profile as 1 completed module.
    private var profileCompleted: Int {
        service.completedCount + 1
    }

    private var profileTotal: Int {
        service.totalCount + 1
    }

    private var profileProgress: CGFloat {
        CGFloat(profileCompleted) / CGFloat(profileTotal)
    }

    var body: some View {
        Button {
            HapticManager.impact(.light)
            showHub = true
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                // Module icon strip
                moduleIconStrip

                // Title row
                HStack(spacing: DesignTokens.spacing8) {
                    Image(systemName: isComplete ? "checkmark.circle" : "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.positive)

                    Text(isComplete ? "Profile Complete" : "Deep Dive Surveys")
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                }

                // Subtitle
                Text(subtitleText)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Progress bar
                if !isComplete {
                    VStack(spacing: DesignTokens.spacing4) {
                        SpectrumBar(height: 4, progress: profileProgress)

                        HStack {
                            Spacer()
                            Text("\(profileCompleted)/\(profileTotal)")
                                .font(DesignTokens.smallMono)
                                .foregroundStyle(DesignTokens.textTertiary)
                        }
                    }
                }

                // CTA
                if !isComplete {
                    CTAButton(title: "Enhance Your Profile", style: .secondary) {}
                        .allowsHitTesting(false)
                }
            }
            .padding(DesignTokens.spacing16)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
            .shadow(color: DesignTokens.cardShadowColor, radius: DesignTokens.cardShadowRadius, x: 0, y: DesignTokens.cardShadowY)
        }
        .buttonStyle(CardPressStyle())
        .sheet(isPresented: $showHub) {
            DeepProfileHubSheet()
                .environment(appState)
        }
    }

    // MARK: - Module Icon Strip

    private var allModuleItems: [(icon: String, color: Color, completed: Bool)] {
        var items: [(icon: String, color: Color, completed: Bool)] = [
            (icon: "person.fill", color: DesignTokens.accentEnergy, completed: true)
        ]
        for moduleType in DeepProfileModuleType.allCases {
            items.append((
                icon: moduleType.icon,
                color: moduleType.accentColor,
                completed: service.isModuleCompleted(moduleType)
            ))
        }
        return items
    }

    private var moduleIconStrip: some View {
        let items = allModuleItems
        let topRow = Array(items.prefix(5))
        let bottomRow = Array(items.dropFirst(5))

        return VStack(spacing: DesignTokens.spacing8) {
            iconRow(topRow)
            iconRow(bottomRow)
        }
        .padding(.bottom, 4)
    }

    private func iconRow(_ items: [(icon: String, color: Color, completed: Bool)]) -> some View {
        HStack(spacing: DesignTokens.spacing8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                moduleIcon(icon: item.icon, color: item.color, completed: item.completed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moduleIcon(icon: String, color: Color, completed: Bool) -> some View {
        let iconSize: CGFloat = (UIScreen.main.bounds.width - 2 * DesignTokens.screenMargin - 2 * DesignTokens.spacing16 - 4 * DesignTokens.spacing8) / 5

        return ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill((completed ? color : DesignTokens.textTertiary).opacity(0.15))
                .frame(width: iconSize, height: iconSize)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: iconSize * 0.42))
                        .foregroundStyle(completed ? color : DesignTokens.textTertiary)
                )

            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.positive)
                    .background(
                        Circle()
                            .fill(DesignTokens.bgSurface)
                            .frame(width: 14, height: 14)
                    )
                    .offset(x: 3, y: 3)
            }
        }
    }

    // MARK: - Subtitle

    private var subtitleText: String {
        if isComplete {
            return "Your profile is fully complete."
        }
        return "Complete deep dive surveys to strengthen the personalization of your supplement plan."
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
