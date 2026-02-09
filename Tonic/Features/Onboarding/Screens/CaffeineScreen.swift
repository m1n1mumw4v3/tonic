import SwiftUI

struct CaffeineScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private var isNone: Bool {
        viewModel.coffeeCupsDaily == 0 && viewModel.teaCupsDaily == 0
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "How much caffeine\ndo you drink daily?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                VStack(spacing: 0) {
                    // Coffee stepper
                    stepperRow(
                        label: "Coffee",
                        count: viewModel.coffeeCupsDaily,
                        onDecrement: {
                            HapticManager.selection()
                            viewModel.coffeeCupsDaily = max(0, viewModel.coffeeCupsDaily - 1)
                        },
                        onIncrement: {
                            HapticManager.selection()
                            viewModel.coffeeCupsDaily += 1
                        }
                    )

                    Spacer().frame(height: DesignTokens.spacing12)

                    // Tea stepper
                    stepperRow(
                        label: "Tea",
                        count: viewModel.teaCupsDaily,
                        onDecrement: {
                            HapticManager.selection()
                            viewModel.teaCupsDaily = max(0, viewModel.teaCupsDaily - 1)
                        },
                        onIncrement: {
                            HapticManager.selection()
                            viewModel.teaCupsDaily += 1
                        }
                    )

                    // Divider
                    Rectangle()
                        .fill(DesignTokens.borderDefault)
                        .frame(height: 1)
                        .padding(.vertical, DesignTokens.spacing12)

                    // None option
                    noneCard
                }
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                CTAButton(title: "Next", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
            }
        }
    }

    // MARK: - None Card

    private var noneCard: some View {
        Button {
            HapticManager.selection()
            viewModel.coffeeCupsDaily = 0
            viewModel.teaCupsDaily = 0
        } label: {
            Text("None")
                .font(DesignTokens.bodyFont)
                .foregroundStyle(isNone ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 56)
                .padding(.horizontal, DesignTokens.spacing16)
                .background(isNone ? DesignTokens.bgElevated : DesignTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(
                            isNone ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                            lineWidth: 1
                        )
                )
        }
    }

    // MARK: - Stepper Row

    @ViewBuilder
    private func stepperRow(
        label: String,
        count: Int,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)

            Spacer()

            HStack(spacing: DesignTokens.spacing16) {
                // Decrement button
                Button(action: onDecrement) {
                    Text("\u{2013}")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(count > 0 ? DesignTokens.textPrimary : DesignTokens.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(DesignTokens.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                                .stroke(DesignTokens.borderDefault, lineWidth: 1)
                        )
                }
                .disabled(count == 0)

                // Count + unit
                VStack(spacing: 2) {
                    Text("\(count)")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                    Text("Cups")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                .frame(width: 40)

                // Increment button
                Button(action: onIncrement) {
                    Text("+")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(DesignTokens.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                                .stroke(DesignTokens.borderDefault, lineWidth: 1)
                        )
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, DesignTokens.spacing16)
    }
}

#Preview {
    CaffeineScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
