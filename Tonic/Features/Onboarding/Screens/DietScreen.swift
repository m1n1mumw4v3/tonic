import SwiftUI

struct DietScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacing12),
        GridItem(.flexible(), spacing: DesignTokens.spacing12)
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        HeadlineText(text: "What best describes how you eat?")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, DesignTokens.spacing24)

                        VStack(spacing: DesignTokens.spacing12) {
                            dietCard(for: .omnivore)

                            Rectangle()
                                .fill(DesignTokens.borderDefault)
                                .frame(height: 1)

                            LazyVGrid(columns: columns, spacing: DesignTokens.spacing12) {
                                ForEach(DietType.allCases.filter { $0 != .omnivore && $0 != .other }) { option in
                                    dietCard(for: option)
                                }
                            }

                            dietCard(for: .other)

                            if viewModel.dietType == .other {
                                TextField("", text: Bindable(viewModel).customDietText, prompt: Text("e.g. Whole30, Carnivore...").foregroundStyle(DesignTokens.textSecondary), axis: .vertical)
                                    .font(DesignTokens.bodyFont)
                                    .foregroundStyle(DesignTokens.textPrimary)
                                    .lineLimit(1...2)
                                    .padding(DesignTokens.spacing12)
                                    .background(DesignTokens.bgSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                            .stroke(DesignTokens.borderDefault, lineWidth: 1)
                                    )
                                    .focused($isTextFieldFocused)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing24)
                }

                if viewModel.dietType == .other {
                    CTAButton(title: "Next", style: .primary, action: onContinue)
                        .padding(.horizontal, DesignTokens.spacing24)
                        .padding(.bottom, DesignTokens.spacing48)
                }
            }
        }
    }

    @ViewBuilder
    private func dietCard(for option: DietType) -> some View {
        let isSelected = viewModel.dietType == option

        Button {
            HapticManager.selection()
            viewModel.dietType = option
            if option == .other {
                isTextFieldFocused = true
            } else {
                viewModel.customDietText = ""
                isTextFieldFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onContinue()
                }
            }
        } label: {
            Text(option.label)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignTokens.spacing12)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
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
    DietScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
