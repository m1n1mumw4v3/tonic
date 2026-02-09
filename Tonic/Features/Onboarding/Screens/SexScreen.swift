import SwiftUI

struct SexScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "What's your biological sex?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                VStack(spacing: DesignTokens.spacing12) {
                    ForEach(Sex.allCases) { option in
                        sexCard(for: option)
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
    private func sexCard(for option: Sex) -> some View {
        let isSelected = viewModel.sex == option

        Button {
            HapticManager.selection()
            viewModel.sex = option
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
    SexScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
