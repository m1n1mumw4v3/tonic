import SwiftUI

struct AgeScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "What's your age?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                ScrollWheelPicker(
                    selection: Bindable(viewModel).age,
                    items: Array(18...100),
                    label: { "\($0)" }
                )
                .overlay {
                    unitLabel("yrs")
                        .offset(x: 56)
                }
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                CTAButton(title: "Next", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
            }
        }
    }

    private func unitLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("GeistMono-Medium", size: 18))
            .foregroundStyle(DesignTokens.textPrimary)
    }
}

#Preview {
    AgeScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
