import SwiftUI

struct AIInterstitialScreen: View {
    var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var currentStage: Int = 0
    @State private var progress: CGFloat = 0
    @State private var displayPercent: Int = 0
    @State private var hasCompleted = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stages: [String] = [
        "Analyzing your profile...",
        "Cross-referencing clinical research...",
        "Checking for interactions...",
        "Building your personalized plan..."
    ]

    private let stageDuration: UInt64 = 3_375_000_000 // 3.375 seconds in nanoseconds
    private let totalDuration: Double = 13.5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DesignTokens.bgDeepest.ignoresSafeArea()

                GradientFlowBackground(fullScreen: true)
                GrainOverlay()

                // Greeting — pinned at ~1/4 down the screen
                HeadlineText(
                    text: "Hang tight, \(viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty ? "friend" : viewModel.firstName).",
                    alignment: .center
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.25)

                // Single rotating step with shimmer — vertically centered
                ZStack {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, message in
                        Text(message)
                            .font(DesignTokens.headlineFont)
                            .foregroundStyle(DesignTokens.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .modifier(ShimmerModifier(isActive: !reduceMotion && index == currentStage))
                            .opacity(index == currentStage ? 1 : 0)
                            .animation(.easeInOut(duration: 1.4), value: currentStage)
                    }
                }
                .frame(width: geometry.size.width - DesignTokens.spacing32 * 2, height: 80)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.5)

                // Progress bar — near the bottom
                VStack(spacing: DesignTokens.spacing12) {
                    SpectrumBar(height: 4, progress: progress)
                        .padding(.horizontal, DesignTokens.spacing48)

                    Text("\(displayPercent)%")
                        .font(.custom("GeistMono-Medium", size: 15))
                        .foregroundStyle(DesignTokens.textPrimary)
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height - DesignTokens.spacing48 - 30)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startSequence()
        }
    }

    // MARK: - Sequence Timer

    private func startSequence() {
        Task {
            // 4 stages, 25% each, tick 1% at a time = 100 ticks total
            // Each stage is 2.9s → each tick is 2.9s / 25 = 116ms
            let tickDuration: UInt64 = 135_000_000

            for stage in 0..<stages.count {
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 1.4)) {
                    currentStage = stage
                }

                let percentStart = stage * 25
                let percentEnd = (stage + 1) * 25

                for pct in (percentStart + 1)...percentEnd {
                    guard !Task.isCancelled else { return }
                    try? await Task.sleep(nanoseconds: tickDuration)

                    await MainActor.run {
                        displayPercent = pct
                        withAnimation(.linear(duration: 0.1)) {
                            progress = CGFloat(pct) / 100.0
                        }
                    }
                }
            }

            // Small pause after completion
            try? await Task.sleep(nanoseconds: 500_000_000)

            guard !hasCompleted else { return }
            hasCompleted = true

            await MainActor.run {
                onComplete()
            }
        }
    }

}

// MARK: - Shimmer Effect Modifier

private struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .opacity(0.85)
                .overlay {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let bandWidth = width * 0.5

                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.7), location: 0.35),
                                .init(color: .white.opacity(0.7), location: 0.65),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: bandWidth)
                        .offset(x: -bandWidth + phase * (width + bandWidth))
                    }
                    .mask(content)
                }
                .onAppear {
                    withAnimation(.linear(duration: 3.45).repeatForever(autoreverses: false)) {
                        phase = 1.5
                    }
                }
        } else {
            content
        }
    }
}

#Preview {
    AIInterstitialScreen(
        viewModel: {
            let vm = OnboardingViewModel()
            vm.firstName = "Matt"
            return vm
        }(),
        onComplete: {}
    )
}
