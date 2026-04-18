import SwiftUI

struct BaselineScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var showHeadline = false
    @State private var showSubtitle = false
    @State private var sliderVisible: [Bool] = Array(repeating: false, count: 5)
    @State private var showCTA = false

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(alignment: .leading, spacing: DesignTokens.spacing20) {
                // Header
                HeadlineText(text: "How have you been lately?")
                    .opacity(showHeadline ? 1 : 0)
                    .offset(y: showHeadline ? 0 : 12)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing8)

                // Wellness Sliders
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        WellnessSlider(
                            dimension: .sleep,
                            value: Bindable(viewModel).baselineSleep,
                            lowLabel: WellnessDimension.sleep.lowLabel,
                            highLabel: WellnessDimension.sleep.highLabel
                        )
                        .modifier(SliderCardStyle(visible: sliderVisible[0]))

                        WellnessSlider(
                            dimension: .energy,
                            value: Bindable(viewModel).baselineEnergy,
                            lowLabel: WellnessDimension.energy.lowLabel,
                            highLabel: WellnessDimension.energy.highLabel,
                            accentOverride: DesignTokens.accentEnergyDark
                        )
                        .modifier(SliderCardStyle(visible: sliderVisible[1]))

                        WellnessSlider(
                            dimension: .clarity,
                            value: Bindable(viewModel).baselineClarity,
                            lowLabel: WellnessDimension.clarity.lowLabel,
                            highLabel: WellnessDimension.clarity.highLabel
                        )
                        .modifier(SliderCardStyle(visible: sliderVisible[2]))

                        WellnessSlider(
                            dimension: .mood,
                            value: Bindable(viewModel).baselineMood,
                            lowLabel: WellnessDimension.mood.lowLabel,
                            highLabel: WellnessDimension.mood.highLabel
                        )
                        .modifier(SliderCardStyle(visible: sliderVisible[3]))

                        WellnessSlider(
                            dimension: .gut,
                            value: Bindable(viewModel).baselineGut,
                            lowLabel: WellnessDimension.gut.lowLabel,
                            highLabel: WellnessDimension.gut.highLabel
                        )
                        .modifier(SliderCardStyle(visible: sliderVisible[4]))
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, 100)
                }

                // CTA
                CTAButton(title: "Continue", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 8)
            }
        }
        .onAppear {
            startEntranceAnimations()
        }
    }

    private func startEntranceAnimations() {
        // Headline
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.5)) {
                showHeadline = true
            }
        }

        // Subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.4)) {
                showSubtitle = true
            }
        }

        // Sliders cascade: 0.5s start, 0.12s apart
        for index in 0..<5 {
            let delay = 0.5 + Double(index) * 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.45)) {
                    sliderVisible[index] = true
                }
            }
        }

        // CTA
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                showCTA = true
            }
        }
    }
}

private struct SliderCardStyle: ViewModifier {
    let visible: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.vertical, DesignTokens.spacing12)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 16)
    }
}

#Preview {
    BaselineScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
