import SwiftUI

struct WeightScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private enum WeightUnit: String, CaseIterable {
        case lbs, kg
    }

    private let imperialOptions: [Int] = Array(60...500)
    private let metricOptions: [Int] = Array(27...227)

    @State private var selectedUnit: WeightUnit = .lbs
    @State private var selectedLbs: Int = 160
    @State private var selectedKg: Int = 73

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "What's your current weight?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                ZStack(alignment: .trailing) {
                    Group {
                        if selectedUnit == .lbs {
                            ScrollWheelPicker(
                                selection: $selectedLbs,
                                items: imperialOptions,
                                label: { "\($0)" }
                            )
                        } else {
                            ScrollWheelPicker(
                                selection: $selectedKg,
                                items: metricOptions,
                                label: { "\($0)" }
                            )
                        }
                    }

                    UnitPicker(selection: $selectedUnit, label: { $0.rawValue })
                        .onChange(of: selectedUnit) { oldUnit, newUnit in
                            convertValues(from: oldUnit, to: newUnit)
                        }
                }
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                VStack(spacing: DesignTokens.spacing8) {
                    CTAButton(title: "Next", style: .primary) {
                        syncToViewModel()
                        viewModel.includeWeight = true
                        onContinue()
                    }

                    Button {
                        viewModel.includeWeight = false
                        onContinue()
                    } label: {
                        Text("Skip")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignTokens.spacing32)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing8)
            }
        }
        .onAppear {
            selectedLbs = viewModel.weightLbs
            selectedKg = viewModel.weightKg
        }
    }

    private func convertValues(from oldUnit: WeightUnit, to newUnit: WeightUnit) {
        guard oldUnit != newUnit else { return }
        if newUnit == .kg {
            selectedKg = Int(round(Double(selectedLbs) * 0.453592))
        } else {
            selectedLbs = Int(round(Double(selectedKg) / 0.453592))
        }
    }

    private func syncToViewModel() {
        if selectedUnit == .lbs {
            viewModel.weightLbs = selectedLbs
            viewModel.weightKg = Int(round(Double(selectedLbs) * 0.453592))
        } else {
            viewModel.weightKg = selectedKg
            viewModel.weightLbs = Int(round(Double(selectedKg) / 0.453592))
        }
    }
}

#Preview {
    WeightScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
