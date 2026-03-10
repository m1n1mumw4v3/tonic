import SwiftUI

struct MedicalDisclaimerScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
                    SpectrumBar(height: 3)

                    HeadlineText(text: "Medical Disclaimer")

                    Text("Estus provides general wellness and supplement information for educational purposes only. It is not intended as medical advice, diagnosis, or treatment.\n\nAlways consult a qualified healthcare provider before starting any new supplement, especially if you are pregnant, nursing, taking medication, or have a medical condition.\n\nSupplement recommendations are generated algorithmically based on your stated goals and preferences. They do not account for your complete medical history. Individual results may vary.\n\nEstus is not responsible for any adverse effects resulting from the use of information provided through this app.")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, DesignTokens.spacing24)
            }
            .safeAreaInset(edge: .bottom) {
                CTAButton(title: "Acknowledge & Continue", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing12)
                    .padding(.bottom, DesignTokens.spacing16)
                    .background(DesignTokens.bgDeepest)
            }
        }
    }
}

#Preview {
    MedicalDisclaimerScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
