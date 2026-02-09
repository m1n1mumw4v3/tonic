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
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    HeadlineText(text: "Rate your typical\nwellness levels")
                        .opacity(showHeadline ? 1 : 0)
                        .offset(y: showHeadline ? 0 : 12)

                    Text("Be honest — this helps establish a baseline.")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 8)
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.top, DesignTokens.spacing8)

                // Wellness Sliders
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignTokens.spacing20) {
                        WellnessSlider(
                            dimension: .sleep,
                            value: Bindable(viewModel).baselineSleep,
                            lowLabel: WellnessDimension.sleep.lowLabel,
                            highLabel: WellnessDimension.sleep.highLabel
                        )
                        .opacity(sliderVisible[0] ? 1 : 0)
                        .offset(y: sliderVisible[0] ? 0 : 16)

                        WellnessSlider(
                            dimension: .energy,
                            value: Bindable(viewModel).baselineEnergy,
                            lowLabel: WellnessDimension.energy.lowLabel,
                            highLabel: WellnessDimension.energy.highLabel
                        )
                        .opacity(sliderVisible[1] ? 1 : 0)
                        .offset(y: sliderVisible[1] ? 0 : 16)

                        WellnessSlider(
                            dimension: .clarity,
                            value: Bindable(viewModel).baselineClarity,
                            lowLabel: WellnessDimension.clarity.lowLabel,
                            highLabel: WellnessDimension.clarity.highLabel
                        )
                        .opacity(sliderVisible[2] ? 1 : 0)
                        .offset(y: sliderVisible[2] ? 0 : 16)

                        WellnessSlider(
                            dimension: .mood,
                            value: Bindable(viewModel).baselineMood,
                            lowLabel: WellnessDimension.mood.lowLabel,
                            highLabel: WellnessDimension.mood.highLabel
                        )
                        .opacity(sliderVisible[3] ? 1 : 0)
                        .offset(y: sliderVisible[3] ? 0 : 16)

                        WellnessSlider(
                            dimension: .gut,
                            value: Bindable(viewModel).baselineGut,
                            lowLabel: WellnessDimension.gut.lowLabel,
                            highLabel: WellnessDimension.gut.highLabel
                        )
                        .opacity(sliderVisible[4] ? 1 : 0)
                        .offset(y: sliderVisible[4] ? 0 : 16)
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

#Preview {
    BaselineScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
