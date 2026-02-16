import SwiftUI

struct AIInterstitialScreen: View {
    var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var currentStage: Int = 0
    @State private var progress: CGFloat = 0
    @State private var displayPercent: Int = 0
    @State private var blobs: [GradientBlob] = []
    @State private var hasCompleted = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stages: [String] = [
        "Analyzing your profile...",
        "Cross-referencing clinical research...",
        "Checking for interactions...",
        "Building your personalized plan..."
    ]

    private let stageDuration: UInt64 = 2_900_000_000 // 2.9 seconds in nanoseconds
    private let totalDuration: Double = 11.6

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DesignTokens.bgDeepest.ignoresSafeArea()

                gradientBackground

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
            blobs = Self.generateBlobs()
            startSequence()
        }
    }

    // MARK: - Sequence Timer

    private func startSequence() {
        Task {
            // 4 stages, 25% each, tick 1% at a time = 100 ticks total
            // Each stage is 2.9s → each tick is 2.9s / 25 = 116ms
            let tickDuration: UInt64 = 116_000_000

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

    // MARK: - Gradient Blobs

    private struct GradientBlob: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var color: Color
        var duration: Double
        var delay: Double
        // Pre-computed drift targets so they don't change on re-render
        var driftX: CGFloat
        var driftY: CGFloat
        var targetScale: CGFloat
        var initialScale: CGFloat
    }

    private static let spectrumColors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentMood,
        DesignTokens.accentGut
    ]

    private static func generateBlobs() -> [GradientBlob] {
        (0..<5).map { index in
            GradientBlob(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.05...0.55),
                size: CGFloat.random(in: 250...400),
                color: spectrumColors[index % spectrumColors.count],
                duration: Double.random(in: 10...15),
                delay: Double(index) * 0.6,
                driftX: CGFloat.random(in: -1...1) * 0.15,
                driftY: CGFloat.random(in: -1...1) * 0.15,
                targetScale: CGFloat.random(in: 1.0...1.2),
                initialScale: CGFloat.random(in: 0.8...1.0)
            )
        }
    }

    private var gradientBackground: some View {
        GeometryReader { geometry in
            ForEach(blobs) { blob in
                Ellipse()
                    .fill(blob.color)
                    .frame(width: blob.size, height: blob.size)
                    .blur(radius: 60)
                    .opacity(0.3)
                    .position(
                        x: blob.x * geometry.size.width,
                        y: blob.y * geometry.size.height
                    )
                    .modifier(DriftModifier(
                        targetOffsetX: blob.driftX * geometry.size.width,
                        targetOffsetY: blob.driftY * geometry.size.height,
                        targetScale: blob.targetScale,
                        initialScale: blob.initialScale,
                        duration: blob.duration,
                        delay: blob.delay,
                        isActive: !reduceMotion
                    ))
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Drift Animation Modifier

private struct DriftModifier: ViewModifier {
    let targetOffsetX: CGFloat
    let targetOffsetY: CGFloat
    let targetScale: CGFloat
    let initialScale: CGFloat
    let duration: Double
    let delay: Double
    let isActive: Bool

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .offset(
                x: isAnimating ? targetOffsetX : 0,
                y: isAnimating ? targetOffsetY : 0
            )
            .scaleEffect(isAnimating ? targetScale : initialScale)
            .animation(
                isActive
                    ? .easeInOut(duration: duration).repeatForever(autoreverses: true).delay(delay)
                    : .default,
                value: isAnimating
            )
            .onAppear {
                if isActive {
                    isAnimating = true
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
                .opacity(0.5)
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
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        phase = 1
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
