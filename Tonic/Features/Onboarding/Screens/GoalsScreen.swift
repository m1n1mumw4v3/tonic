import SwiftUI

struct GoalsScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacing12),
        GridItem(.flexible(), spacing: DesignTokens.spacing12)
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // Header
                        VStack(spacing: DesignTokens.spacing8) {
                            HeadlineText(text: "What are your top health goals?")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Select all that apply")
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, DesignTokens.spacing24)

                        // Goals grid
                        LazyVGrid(columns: columns, spacing: DesignTokens.spacing12) {
                            ForEach(HealthGoal.allCases) { goal in
                                goalCard(for: goal)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing24)
                }

                // CTA
                CTAButton(title: "Continue", style: .primary, action: onContinue)
                    .opacity(viewModel.hasSelectedGoals ? 1.0 : 0.4)
                    .disabled(!viewModel.hasSelectedGoals)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
            }
        }
    }

    // MARK: - Goal Card

    private func accentColor(for goal: HealthGoal) -> Color {
        switch goal {
        case .sleep:           return DesignTokens.accentSleep
        case .energy:          return DesignTokens.accentEnergy
        case .focus:           return DesignTokens.accentClarity
        case .stressAnxiety:   return DesignTokens.accentMood
        case .gutHealth:       return DesignTokens.accentGut
        case .immunity:        return DesignTokens.info
        case .fitnessRecovery: return DesignTokens.positive
        case .skinHairNails:   return DesignTokens.negative
        case .longevity:       return DesignTokens.accentLongevity
        }
    }

    @ViewBuilder
    private func goalCard(for goal: HealthGoal) -> some View {
        let isSelected = viewModel.healthGoals.contains(goal)
        let accent = accentColor(for: goal)

        Button {
            HapticManager.selection()
            if isSelected {
                viewModel.healthGoals.remove(goal)
            } else {
                viewModel.healthGoals.insert(goal)
            }
        } label: {
            VStack(spacing: DesignTokens.spacing8) {
                HStack {
                    Image(systemName: goal.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? accent : DesignTokens.textSecondary)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? accent : DesignTokens.textTertiary)
                }

                Text(goal.label)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.spacing12)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background(isSelected ? DesignTokens.bgElevated : DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(
                        isSelected ? accent : DesignTokens.borderDefault,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }
}

#Preview {
    GoalsScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
