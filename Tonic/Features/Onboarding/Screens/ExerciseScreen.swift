import SwiftUI

struct ExerciseScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "How often do you exercise?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                VStack(spacing: DesignTokens.spacing12) {
                    ForEach(ExerciseFrequency.allCases) { option in
                        optionCard(for: option)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                CTAButton(title: "Next", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
            }
        }
    }

    @ViewBuilder
    private func optionCard(for option: ExerciseFrequency) -> some View {
        let isSelected = viewModel.exerciseFrequency == option

        Button {
            HapticManager.selection()
            viewModel.exerciseFrequency = option
        } label: {
            Text(option.label)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 56)
                .padding(.horizontal, DesignTokens.spacing16)
                .background(isSelected ? DesignTokens.bgElevated : DesignTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(
                            isSelected ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                            lineWidth: 1
                        )
                )
        }
    }
}

#Preview {
    ExerciseScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
