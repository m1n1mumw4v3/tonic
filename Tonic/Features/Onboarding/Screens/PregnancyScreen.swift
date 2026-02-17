import SwiftUI

struct PregnancyScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var selectedNo = false

    private var hasPositiveSelection: Bool {
        viewModel.isPregnant || viewModel.isBreastfeeding
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "Are you currently pregnant or breastfeeding?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                VStack(spacing: DesignTokens.spacing12) {
                    optionCard(label: "No", isSelected: selectedNo) {
                        HapticManager.selection()
                        selectedNo = true
                        viewModel.isPregnant = false
                        viewModel.isBreastfeeding = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onContinue()
                        }
                    }

                    optionCard(label: "Pregnant", isSelected: viewModel.isPregnant) {
                        HapticManager.selection()
                        selectedNo = false
                        viewModel.isPregnant.toggle()
                    }

                    optionCard(label: "Breastfeeding", isSelected: viewModel.isBreastfeeding) {
                        HapticManager.selection()
                        selectedNo = false
                        viewModel.isBreastfeeding.toggle()
                    }
                }
                .padding(.horizontal, DesignTokens.spacing24)

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
                .padding(.horizontal, DesignTokens.spacing16)
                .background(isSelected ? DesignTokens.accentGut.opacity(0.15) : DesignTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(isSelected ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: isSelected ? 1.5 : 1)
                )
        }
    }
}

#Preview {
    PregnancyScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
