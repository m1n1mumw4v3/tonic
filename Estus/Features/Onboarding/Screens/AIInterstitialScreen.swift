import SwiftUI

struct AIInterstitialScreen: View {
    var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var currentStage: Int = 0
    @State private var progress: CGFloat = 0
    @State private var displayPercent: Int = 0
    @State private var hasCompleted = false

    @State private var showContent = false
    @State private var showHeadline = false
    @State private var showDots = false
    @State private var showStageText = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stages: [String] = [
        "Analyzing your profile...",
        "Cross-referencing clinical research...",
        "Checking for interactions...",
        "Building your personalized plan..."
    ]

    private var userName: String {
        let name = viewModel.firstName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "friend" : name
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Full-screen orb background
                OrbBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Breathing dots
                    BreathingDots(isActive: showDots, reduceMotion: reduceMotion)
                        .padding(.bottom, DesignTokens.spacing24)

                    // Headline
                    HeadlineText(
                        text: "Hang tight, \(userName).",
                        alignment: .center,
                        color: .white
                    )
                    .opacity(showHeadline ? 1 : 0)
                    .offset(y: showHeadline || reduceMotion ? 0 : 8)
                    .padding(.horizontal, DesignTokens.spacing32)

                    // Stage text
                    ZStack(alignment: .top) {
                        ForEach(Array(stages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .opacity(index == currentStage ? 1 : 0)
                                .offset(y: index == currentStage ? 0 : 6)
                                .animation(.easeInOut(duration: 0.8), value: currentStage)
                        }
                    }
                    .padding(.top, DesignTokens.spacing16)
                    .padding(.horizontal, DesignTokens.spacing32)
                    .opacity(showStageText ? 1 : 0)

                    Spacer()

                    // Progress bar
                    VStack(spacing: DesignTokens.spacing8) {
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.15))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: barGeo.size.width * min(max(progress, 0), 1))
                            }
                        }
                        .frame(height: 4)

                        Text("\(displayPercent)%")
                            .font(.custom("GeistMono-Medium", size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, DesignTokens.spacing48)
                    .padding(.bottom, DesignTokens.spacing48)
                    .opacity(showContent ? 1 : 0)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startEntranceAnimation()
            startSequence()
        }
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        guard !reduceMotion else {
            showContent = true
            showHeadline = true
            showDots = true
            showStageText = true
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showContent = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.6)) {
                showHeadline = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showDots = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.6)) {
                showStageText = true
            }
        }
    }

    // MARK: - Sequence Timer

    private func startSequence() {
        Task {
            let tickDuration: UInt64 = 135_000_000

            for stage in 0..<stages.count {
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.8)) {
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

            try? await Task.sleep(nanoseconds: 500_000_000)

            guard !hasCompleted else { return }
            hasCompleted = true

            await MainActor.run {
                onComplete()
            }
        }
    }
}

// MARK: - Breathing Dots

private struct BreathingDots: View {
    let isActive: Bool
    let reduceMotion: Bool

    var body: some View {
        HStack(spacing: DesignTokens.spacing12) {
            ForEach(0..<5, id: \.self) { index in
                BreathingDot(
                    delay: Double(index) * 0.2,
                    isActive: isActive && !reduceMotion
                )
            }
        }
    }
}

private struct BreathingDot: View {
    let delay: Double
    let isActive: Bool

    private let dotSize: CGFloat = 12

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Soft outer glow
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: dotSize * 1.6, height: dotSize * 1.6)
                .blur(radius: 3)

            // Glass body
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.6), location: 0),
                            .init(color: Color.white.opacity(0.25), location: 0.5),
                            .init(color: Color.white.opacity(0.1), location: 1.0)
                        ],
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: dotSize * 0.6
                    )
                )
                .frame(width: dotSize, height: dotSize)

            // Edge ring
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 0.8)
                .frame(width: dotSize, height: dotSize)

            // Specular highlight
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: dotSize * 0.3, height: dotSize * 0.3)
                .offset(x: -dotSize * 0.15, y: -dotSize * 0.18)
        }
        .frame(width: dotSize * 2.2, height: dotSize * 2.2)
        .opacity(isAnimating ? 1.0 : 0.3)
        .scaleEffect(isAnimating ? 1.0 : 0.8)
        .animation(
            isActive
                ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(delay)
                : .default,
            value: isAnimating
        )
        .onAppear {
            if isActive {
                isAnimating = true
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                isAnimating = true
            }
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
