import SwiftUI

struct HeightScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private enum HeightUnit: String, CaseIterable {
        case ft, cm
    }

    // Total inches range: 3'0" (36) to 7'11" (95)
    private let imperialOptions: [Int] = Array(36...95)
    // cm range: 91 cm (~3'0") to 241 cm (~7'11")
    private let metricOptions: [Int] = Array(91...241)

    @State private var selectedUnit: HeightUnit = .ft
    @State private var selectedTotalInches: Int = 68 // 5'8" default
    @State private var selectedCm: Int = 173 // ~5'8" default

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "How tall are you?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                ZStack(alignment: .trailing) {
                    Group {
                        if selectedUnit == .ft {
                            ScrollWheelPicker(
                                selection: $selectedTotalInches,
                                items: imperialOptions,
                                label: { totalInches in
                                    let feet = totalInches / 12
                                    let inches = totalInches % 12
                                    return "\(feet)'\(inches)\""
                                }
                            )
                        } else {
                            ScrollWheelPicker(
                                selection: $selectedCm,
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
                        viewModel.includeHeight = true
                        onContinue()
                    }

                    Button {
                        viewModel.includeHeight = false
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
            selectedTotalInches = viewModel.heightFeet * 12 + viewModel.heightInches
            selectedCm = viewModel.heightCm
        }
    }

    private func convertValues(from oldUnit: HeightUnit, to newUnit: HeightUnit) {
        guard oldUnit != newUnit else { return }
        if newUnit == .cm {
            selectedCm = Int(round(Double(selectedTotalInches) * 2.54))
        } else {
            selectedTotalInches = Int(round(Double(selectedCm) / 2.54))
        }
    }

    private func syncToViewModel() {
        if selectedUnit == .ft {
            viewModel.heightFeet = selectedTotalInches / 12
            viewModel.heightInches = selectedTotalInches % 12
            viewModel.heightCm = Int(round(Double(selectedTotalInches) * 2.54))
        } else {
            let totalInches = Int(round(Double(selectedCm) / 2.54))
            viewModel.heightFeet = totalInches / 12
            viewModel.heightInches = totalInches % 12
            viewModel.heightCm = selectedCm
        }
    }
}

#Preview {
    HeightScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
