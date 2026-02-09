import SwiftUI

struct AIInterstitialScreen: View {
    var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var currentStage: Int = 0
    @State private var progress: CGFloat = 0
    @State private var particles: [Particle] = []
    @State private var hasCompleted = false

    private let stages: [String] = [
        "Analyzing your profile...",
        "Cross-referencing clinical research...",
        "Checking for interactions...",
        "Building your personalized plan..."
    ]

    private let stageDuration: UInt64 = 2_400_000_000 // 2.4 seconds in nanoseconds
    private let totalDuration: Double = 9.6

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            // Background particles
            particleField

            // Main content
            VStack(spacing: DesignTokens.spacing40) {
                Spacer()

                // Greeting
                HeadlineText(
                    text: "Hang tight, \(viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty ? "friend" : viewModel.firstName)...",
                    alignment: .center
                )

                // Stage messages
                VStack(spacing: DesignTokens.spacing16) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { index, message in
                        HStack(spacing: 8) {
                            if index < currentStage {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(DesignTokens.positive)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            Text(message)
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                        .opacity(stageOpacity(for: index))
                        .scaleEffect(currentStage == index ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.6), value: currentStage)
                    }
                }
                .frame(height: 120)

                Spacer()

                // Progress bar
                VStack(spacing: DesignTokens.spacing12) {
                    SpectrumBar(height: 4, progress: progress)
                        .padding(.horizontal, DesignTokens.spacing48)
                        .animation(.linear(duration: 0.3), value: progress)

                    Text("\(Int(progress * 100))%")
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Spacer()
                    .frame(height: DesignTokens.spacing48)
            }
        }
        .onAppear {
            generateParticles()
            startSequence()
        }
    }

    // MARK: - Stage Opacity

    private func stageOpacity(for index: Int) -> Double {
        if index == currentStage {
            return 1.0
        } else if index < currentStage {
            return 0.7
        } else {
            return 0.0
        }
    }

    // MARK: - Sequence Timer

    private func startSequence() {
        Task {
            for stage in 0..<stages.count {
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStage = stage
                }

                // Animate progress over this stage
                let stageStart = CGFloat(stage) / CGFloat(stages.count)
                let stageEnd = CGFloat(stage + 1) / CGFloat(stages.count)
                let steps = 20
                let stepDuration = stageDuration / UInt64(steps)

                for step in 0...steps {
                    guard !Task.isCancelled else { return }
                    let fraction = CGFloat(step) / CGFloat(steps)
                    let newProgress = stageStart + (stageEnd - stageStart) * fraction

                    await MainActor.run {
                        withAnimation(.linear(duration: 0.15)) {
                            progress = newProgress
                        }
                    }

                    if step < steps {
                        try? await Task.sleep(nanoseconds: stepDuration)
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

    // MARK: - Particles

    private struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var duration: Double
        var color: Color
    }

    private static let spectrumColors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentMood,
        DesignTokens.accentGut
    ]

    private func generateParticles() {
        particles = (0..<30).map { _ in
            Particle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.15...0.4),
                duration: Double.random(in: 3...7),
                color: Self.spectrumColors.randomElement()!
            )
        }
    }

    private var particleField: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(
                        x: particle.x * geometry.size.width,
                        y: particle.y * geometry.size.height
                    )
                    .opacity(particle.opacity)
                    .modifier(PulseModifier(duration: particle.duration))
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Pulse Animation Modifier

private struct PulseModifier: ViewModifier {
    let duration: Double
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 1.0 : 0.2)
            .scaleEffect(isAnimating ? 1.3 : 0.8)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
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
