import SwiftUI

struct NameScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: DesignTokens.spacing32) {
                // Header
                HeadlineText(text: "What's your first name?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                // Text field
                TextField("", text: Bindable(viewModel).firstName, prompt: Text("First name").foregroundStyle(DesignTokens.textSecondary))
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(DesignTokens.spacing16)
                    .background(DesignTokens.bgSurface)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                isFieldFocused ? DesignTokens.onboardingSelected : DesignTokens.borderDefault,
                                lineWidth: 1
                            )
                    )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isFieldFocused)
                    .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                // CTA
                CTAButton(title: "Continue", style: .primary, action: onContinue)
                    .opacity(viewModel.isNameValid ? 1.0 : 0.4)
                    .disabled(!viewModel.isNameValid)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onAppear {
            isFieldFocused = true
        }
    }
}

#Preview {
    NameScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
