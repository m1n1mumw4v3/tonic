import SwiftUI

struct SexScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: DesignTokens.spacing12) {
                ForEach(Sex.allCases) { option in
                    sexCard(for: option)
                }
            }
            .padding(.horizontal, DesignTokens.spacing24)

            VStack {
                HeadlineText(text: "What sex were you assigned at birth?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func sexCard(for option: Sex) -> some View {
        let isSelected = viewModel.sex == option

        Button {
            HapticManager.selection()
            viewModel.sex = option
            if option == .male {
                viewModel.isPregnant = false
                viewModel.isBreastfeeding = false
            }
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
    SexScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
