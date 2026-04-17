import SwiftUI

struct AlcoholScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: DesignTokens.spacing12) {
                ForEach(AlcoholIntake.allCases) { option in
                    optionCard(for: option)
                }
            }
            .padding(.horizontal, DesignTokens.spacing24)

            VStack {
                HeadlineText(text: "How much alcohol\ndo you drink weekly?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func optionCard(for option: AlcoholIntake) -> some View {
        let isSelected = viewModel.alcoholWeekly == option

        Button {
            HapticManager.selection()
            viewModel.alcoholWeekly = option
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onContinue()
            }
        } label: {
            Text(option.label)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 56)
                .padding(.leading, 26)
                .padding(.trailing, DesignTokens.spacing16)
                .background(DesignTokens.bgSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? DesignTokens.onboardingSelected : DesignTokens.borderDefault, lineWidth: isSelected ? 1.5 : 1)
                )
        }
    }
}

#Preview {
    AlcoholScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
