import SwiftUI

struct GoalsScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var showMaxError = false

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacing4),
        GridItem(.flexible(), spacing: DesignTokens.spacing4)
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // Header
                        VStack(spacing: DesignTokens.spacing8) {
                            HeadlineText(text: "What are your health goals?")
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("Select up to \(HealthGoal.maxSelection) goals.")
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, DesignTokens.spacing24)

                        // Goals grid
                        LazyVGrid(columns: columns, spacing: DesignTokens.spacing4) {
                            ForEach(HealthGoal.allCases) { goal in
                                goalCard(for: goal)
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing24)
                }

                // Error + CTA
                VStack(spacing: DesignTokens.spacing12) {
                    if showMaxError {
                        Text("You can select up to \(HealthGoal.maxSelection) goals for a focused plan.")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.negative)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    CTAButton(title: "Continue", style: .primary, action: onContinue)
                        .opacity(viewModel.hasSelectedGoals ? 1.0 : 0.4)
                        .disabled(!viewModel.hasSelectedGoals)
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onChange(of: viewModel.healthGoals.count) {
            if !viewModel.isAtGoalLimit {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMaxError = false
                }
            }
        }
    }

    // MARK: - Goal Card

    @ViewBuilder
    private func goalCard(for goal: HealthGoal) -> some View {
        let isSelected = viewModel.healthGoals.contains(goal)
        let accent = goal.accentColor

        Button {
            if isSelected {
                viewModel.healthGoals.remove(goal)
                HapticManager.selection()
            } else if viewModel.isAtGoalLimit {
                HapticManager.notification(.warning)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMaxError = true
                }
            } else {
                viewModel.healthGoals.insert(goal)
                HapticManager.selection()
            }
        } label: {
            VStack(spacing: DesignTokens.spacing4) {
                Image(systemName: goal.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? accent : DesignTokens.textSecondary)

                TightLineLabel(
                    text: goal.label,
                    font: UIFont(name: "Geist-Regular", size: 16) ?? .systemFont(ofSize: 16),
                    color: UIColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary),
                    lineHeightMultiple: 0.85
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, DesignTokens.spacing12)
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 52))
            .overlay(
                RoundedRectangle(cornerRadius: 52)
                    .stroke(isSelected ? accent : DesignTokens.borderDefault, lineWidth: isSelected ? 1.5 : 1)
            )
            .opacity(!isSelected && viewModel.isAtGoalLimit ? 0.4 : 1.0)
        }
    }

}

private final class AutoWrappingLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        if preferredMaxLayoutWidth != bounds.width {
            preferredMaxLayoutWidth = bounds.width
            setNeedsUpdateConstraints()
        }
    }
}

private struct TightLineLabel: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor
    let lineHeightMultiple: CGFloat

    func makeUIView(context: Context) -> AutoWrappingLabel {
        let label = AutoWrappingLabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }

    func updateUIView(_ label: AutoWrappingLabel, context: Context) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = lineHeightMultiple
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: AutoWrappingLabel, context: Context) -> CGSize? {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        let fit = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: proposal.width ?? fit.width, height: fit.height)
    }
}

#Preview {
    GoalsScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
