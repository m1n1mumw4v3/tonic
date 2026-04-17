import SwiftUI

struct GoalsScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var showMaxError = false

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

                            Text("Please select up to \(HealthGoal.maxSelection).")
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

                // Error + CTA
                VStack(spacing: DesignTokens.spacing12) {
                    if showMaxError {
                        Text("You can select up to \(HealthGoal.maxSelection) goals for a focused plan.")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.negative)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    CTAButton(title: "Continue", style: .primary, action: onContinue)
                        .opacity(viewModel.hasSelectedGoals ? 1.0 : 0.4)
                        .disabled(!viewModel.hasSelectedGoals)
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onChange(of: viewModel.healthGoals.count) {
            if !viewModel.isAtGoalLimit {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMaxError = false
                }
            }
        }
    }

    // MARK: - Goal Card

    @ViewBuilder
    private func goalCard(for goal: HealthGoal) -> some View {
        let isSelected = viewModel.healthGoals.contains(goal)
        let accent = goal.accentColor

        Button {
            if isSelected {
                viewModel.healthGoals.remove(goal)
                HapticManager.selection()
            } else if viewModel.isAtGoalLimit {
                HapticManager.notification(.warning)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMaxError = true
                }
            } else {
                viewModel.healthGoals.insert(goal)
                HapticManager.selection()
            }
        } label: {
            VStack(spacing: DesignTokens.spacing4) {
                Image(systemName: goal.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? accent : DesignTokens.textSecondary)

                Text(goal.label)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DesignTokens.spacing12)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(isSelected ? accent : DesignTokens.borderDefault, lineWidth: isSelected ? 1.5 : 1)
            )
            .opacity(!isSelected && viewModel.isAtGoalLimit ? 0.4 : 1.0)
        }
    }
}

#Preview {
    GoalsScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
