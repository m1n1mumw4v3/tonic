import SwiftUI

struct CaffeineScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private var isNone: Bool {
        viewModel.coffeeCupsDaily == 0 && viewModel.teaCupsDaily == 0 && viewModel.energyDrinksDaily == 0
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

                VStack(spacing: DesignTokens.spacing12) {
                    // None option
                    noneCard

                    // Coffee stepper
                    stepperCard(
                        label: "Coffee",
                        count: viewModel.coffeeCupsDaily,
                        isActive: viewModel.coffeeCupsDaily > 0,
                        onDecrement: {
                            HapticManager.selection()
                            viewModel.coffeeCupsDaily = max(0, viewModel.coffeeCupsDaily - 1)
                        },
                        onIncrement: {
                            HapticManager.selection()
                            viewModel.coffeeCupsDaily += 1
                        }
                    )

                    // Tea stepper
                    stepperCard(
                        label: "Tea",
                        count: viewModel.teaCupsDaily,
                        isActive: viewModel.teaCupsDaily > 0,
                        onDecrement: {
                            HapticManager.selection()
                            viewModel.teaCupsDaily = max(0, viewModel.teaCupsDaily - 1)
                        },
                        onIncrement: {
                            HapticManager.selection()
                            viewModel.teaCupsDaily += 1
                        }
                    )

                    // Energy drink stepper
                    stepperCard(
                        label: "Energy Drink",
                        count: viewModel.energyDrinksDaily,
                        isActive: viewModel.energyDrinksDaily > 0,
                        onDecrement: {
                            HapticManager.selection()
                            viewModel.energyDrinksDaily = max(0, viewModel.energyDrinksDaily - 1)
                        },
                        onIncrement: {
                            HapticManager.selection()
                            viewModel.energyDrinksDaily += 1
                        }
                    )
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
            viewModel.energyDrinksDaily = 0
        } label: {
            Text("None")
                .font(DesignTokens.bodyFont)
                .foregroundStyle(isNone ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 56)
                .padding(.horizontal, DesignTokens.spacing16)
                .background(isNone ? DesignTokens.accentGut.opacity(0.15) : DesignTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(isNone ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: isNone ? 1.5 : 1)
                )
        }
    }

    // MARK: - Stepper Card

    @ViewBuilder
    private func stepperCard(
        label: String,
        count: Int,
        isActive: Bool,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(isActive ? DesignTokens.textPrimary : DesignTokens.textSecondary)

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
        .background(isActive ? DesignTokens.accentGut.opacity(0.15) : DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(isActive ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: isActive ? 1.5 : 1)
        )
    }
}

#Preview {
    CaffeineScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
