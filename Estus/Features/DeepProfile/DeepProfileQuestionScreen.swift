import SwiftUI

struct DeepProfileQuestionScreen: View {
    let question: DeepProfileQuestion
    let accentColor: Color
    let viewModel: DeepProfileFlowViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.spacing24) {
                    // Question text
                    VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                        Text(question.text)
                            .font(DesignTokens.headlineFont)
                            .lineSpacing(-4)
                            .foregroundStyle(DesignTokens.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let subtext = question.subtext {
                            Text(subtext)
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, DesignTokens.spacing24)

                    // Input
                    inputView
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing24)
            }

            // Bottom actions
            bottomActions
        }
    }

    // MARK: - Input View

    @ViewBuilder
    private var inputView: some View {
        switch question.inputType {
        case .singleSelect(let options):
            singleSelectView(options: options)
        case .multiSelect(let options):
            multiSelectView(options: options)
        case .timeInput:
            timeInputView
        case .numericInput(let unit, let range):
            numericInputView(unit: unit, range: range)
        case .slider(let min, let max, let step):
            sliderInputView(min: min, max: max, step: step)
        }
    }

    // MARK: - Single Select

    private func singleSelectView(options: [SelectOption]) -> some View {
        VStack(spacing: DesignTokens.spacing12) {
            ForEach(options) { option in
                let isSelected = viewModel.selectedSingleValue(for: question.id) == option.value

                Button {
                    viewModel.selectSingleAnswer(option.value) {
                        onComplete()
                    }
                } label: {
                    Text(option.label)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 56)
                        .padding(.horizontal, DesignTokens.spacing16)
                        .background(isSelected ? DesignTokens.bgElevated : DesignTokens.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                .stroke(
                                    isSelected ? accentColor : DesignTokens.borderDefault,
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                }
            }
        }
    }

    // MARK: - Multi Select

    private func multiSelectView(options: [SelectOption]) -> some View {
        VStack(spacing: DesignTokens.spacing12) {
            ForEach(options) { option in
                let selectedValues = viewModel.selectedMultiValues(for: question.id)
                let isSelected = selectedValues.contains(option.value)

                Button {
                    viewModel.toggleMultiSelectAnswer(option.value)
                } label: {
                    HStack {
                        Text(option.label)
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)

                        Spacer()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(isSelected ? accentColor : DesignTokens.textTertiary)
                    }
                    .frame(height: 56)
                    .padding(.horizontal, DesignTokens.spacing16)
                    .background(isSelected ? DesignTokens.bgElevated : DesignTokens.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                            .stroke(
                                isSelected ? accentColor : DesignTokens.borderDefault,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                }
            }
        }
    }

    // MARK: - Time Input

    @ViewBuilder
    private var timeInputView: some View {
        let binding = Binding<Date>(
            get: {
                if let timeString = viewModel.selectedSingleValue(for: question.id) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    return formatter.date(from: timeString) ?? defaultTime
                }
                return defaultTime
            },
            set: { newDate in
                viewModel.setTimeAnswer(newDate)
            }
        )

        DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.light)
    }

    private var defaultTime: Date {
        Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    }

    // MARK: - Numeric Input

    private func numericInputView(unit: String, range: ClosedRange<Int>) -> some View {
        let currentValue = Int(viewModel.selectedSingleValue(for: question.id) ?? "") ?? range.lowerBound

        return VStack(spacing: DesignTokens.spacing16) {
            Text("\(currentValue)")
                .font(DesignTokens.displayFont)
                .foregroundStyle(accentColor)

            Text(unit)
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)

            Slider(
                value: Binding(
                    get: { Double(currentValue) },
                    set: { viewModel.setNumericAnswer(Int($0)) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(accentColor)
        }
        .padding(.vertical, DesignTokens.spacing16)
    }

    // MARK: - Slider Input

    private func sliderInputView(min: Int, max: Int, step: Int) -> some View {
        let currentValue = Int(viewModel.selectedSingleValue(for: question.id) ?? "") ?? min

        return VStack(spacing: DesignTokens.spacing16) {
            Text("\(currentValue)")
                .font(DesignTokens.displayFont)
                .foregroundStyle(accentColor)

            Slider(
                value: Binding(
                    get: { Double(currentValue) },
                    set: { viewModel.setSliderAnswer(Int($0)) }
                ),
                in: Double(min)...Double(max),
                step: Double(step)
            )
            .tint(accentColor)

            HStack {
                Text("\(min)")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textTertiary)
                Spacer()
                Text("\(max)")
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textTertiary)
            }
        }
        .padding(.vertical, DesignTokens.spacing16)
    }

    // MARK: - Bottom Actions

    @ViewBuilder
    private var bottomActions: some View {
        switch question.inputType {
        case .singleSelect:
            // Auto-advance handles navigation; show skip if optional
            if question.isOptional {
                skipButton
            }
        case .multiSelect:
            let hasSelection = !viewModel.selectedMultiValues(for: question.id).isEmpty
            VStack(spacing: DesignTokens.spacing8) {
                CTAButton(title: "Next", style: .primary) {
                    navigatingForward()
                    viewModel.goNext { onComplete() }
                }
                .opacity(hasSelection ? 1.0 : 0.4)
                .disabled(!hasSelection)

                if question.isOptional {
                    skipButton
                }
            }
            .padding(.horizontal, DesignTokens.spacing24)
            .padding(.bottom, DesignTokens.spacing32)
        case .timeInput, .numericInput, .slider:
            VStack(spacing: DesignTokens.spacing8) {
                CTAButton(title: "Next", style: .primary) {
                    navigatingForward()
                    viewModel.goNext { onComplete() }
                }

                if question.isOptional {
                    skipButton
                }
            }
            .padding(.horizontal, DesignTokens.spacing24)
            .padding(.bottom, DesignTokens.spacing32)
        }
    }

    private var skipButton: some View {
        Button {
            navigatingForward()
            viewModel.skipQuestion { onComplete() }
        } label: {
            Text("Skip")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textTertiary)
                .padding(.vertical, DesignTokens.spacing8)
        }
    }

    private func navigatingForward() {
        // Reset forward direction for transitions — parent handles via .id()
    }
}
