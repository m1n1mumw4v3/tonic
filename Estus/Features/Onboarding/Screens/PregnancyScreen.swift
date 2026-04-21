import SwiftUI

struct PregnancyScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var selectedNone = false

    private var hasPositiveSelection: Bool {
        viewModel.isPregnant
            || viewModel.isBreastfeeding
            || viewModel.isPerimenopausal
            || viewModel.isOnHormonalBirthControl
            || viewModel.isOnHRT
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: DesignTokens.spacing12) {
                optionCard(label: "Pregnant or trying to conceive", isSelected: viewModel.isPregnant) {
                    HapticManager.selection()
                    selectedNone = false
                    viewModel.isPregnant.toggle()
                }

                optionCard(label: "Breastfeeding", isSelected: viewModel.isBreastfeeding) {
                    HapticManager.selection()
                    selectedNone = false
                    viewModel.isBreastfeeding.toggle()
                }

                optionCard(label: "Perimenopause or menopause", isSelected: viewModel.isPerimenopausal) {
                    HapticManager.selection()
                    selectedNone = false
                    viewModel.isPerimenopausal.toggle()
                }

                optionCard(label: "On hormonal birth control", isSelected: viewModel.isOnHormonalBirthControl) {
                    HapticManager.selection()
                    selectedNone = false
                    viewModel.isOnHormonalBirthControl.toggle()
                }

                optionCard(label: "On hormone replacement therapy", isSelected: viewModel.isOnHRT) {
                    HapticManager.selection()
                    selectedNone = false
                    viewModel.isOnHRT.toggle()
                }

                optionCard(label: "None of the above", isSelected: selectedNone) {
                    HapticManager.selection()
                    selectedNone = true
                    viewModel.isPregnant = false
                    viewModel.isBreastfeeding = false
                    viewModel.isPerimenopausal = false
                    viewModel.isOnHormonalBirthControl = false
                    viewModel.isOnHRT = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onContinue()
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacing24)

            VStack {
                HeadlineText(text: "Do any of these apply to you?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                if hasPositiveSelection {
                    CTAButton(title: "Continue", style: .primary, action: onContinue)
                        .padding(.horizontal, DesignTokens.spacing24)
                        .padding(.bottom, DesignTokens.spacing24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: hasPositiveSelection)
        }
    }

    @ViewBuilder
    private func optionCard(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
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
    PregnancyScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
