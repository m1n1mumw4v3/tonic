import SwiftUI

struct NameScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: DesignTokens.spacing32) {
                Spacer()
                    .frame(height: DesignTokens.spacing40)

                // Header
                HeadlineText(text: "What's your first name?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)

                // Text field
                TextField("", text: Bindable(viewModel).firstName, prompt: Text("First name").foregroundStyle(DesignTokens.textSecondary))
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .padding(DesignTokens.spacing16)
                    .background(DesignTokens.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                            .stroke(
                                isFieldFocused ? DesignTokens.accentClarity : DesignTokens.borderDefault,
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
