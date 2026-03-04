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

                // Braille + greeting + step copy — vertically centered group
                VStack(spacing: DesignTokens.spacing24) {
                    BrailleThinkingIndicator()

                    HeadlineText(
                        text: "Hang tight, \(viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty ? "friend" : viewModel.firstName).",
                        alignment: .center,
                        color: .white
                    )

                    ZStack(alignment: .top) {
                        ForEach(Array(stages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(DesignTokens.headlineFont)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .top)
                                .modifier(ShimmerModifier(isActive: !reduceMotion && index == currentStage))
                                .opacity(index == currentStage ? 1 : 0)
                                .animation(.easeInOut(duration: 1.4), value: currentStage)
                        }
                    }
                    .frame(width: geometry.size.width - DesignTokens.spacing32 * 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: -DesignTokens.spacing32)

                // Progress bar with embedded % — near the bottom
                ZStack {
                    // Background track + black text
                    RoundedRectangle(cornerRadius: 14)
                        .fill(DesignTokens.bgElevated)
                    Text("\(displayPercent)%")
                        .font(.custom("GeistMono-Medium", size: 13))
                        .foregroundStyle(DesignTokens.textPrimary)

                    // Gradient fill + white text, both masked to progress
                    GeometryReader { barGeo in
                        let fillWidth = barGeo.size.width * min(max(progress, 0), 1)

                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: DesignTokens.spectrumColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("\(displayPercent)%")
                                .font(.custom("GeistMono-Medium", size: 13))
                                .foregroundStyle(.white)
                        }
                        .mask(
                            HStack(spacing: 0) {
                                Rectangle().frame(width: fillWidth)
                                Spacer(minLength: 0)
                            }
                        )
                    }
                }
                .frame(height: 28)
                .padding(.horizontal, DesignTokens.spacing48)
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

// MARK: - Braille Thinking Indicator

private struct BrailleThinkingIndicator: View {
    private let cellCount = 8
    private let dotSize: CGFloat = 7
    private let innerSpacing: CGFloat = 5
    private let cellGap: CGFloat = 10

    // Liquid metal palette
    private let metalBright = Color(red: 0.92, green: 0.94, blue: 0.96)
    private let metalMid    = Color(red: 0.78, green: 0.82, blue: 0.88)
    private let metalDark   = Color(red: 0.60, green: 0.65, blue: 0.72)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: reduceMotion)) { context in
            let time = reduceMotion ? 0.0 : context.date.timeIntervalSinceReferenceDate

            Canvas { ctx, size in
                let cellWidth = 2 * dotSize + innerSpacing
                let cellHeight = 3 * dotSize + 2 * innerSpacing
                let totalWidth = CGFloat(cellCount) * cellWidth + CGFloat(cellCount - 1) * cellGap
                let originX = (size.width - totalWidth) / 2
                let originY = (size.height - cellHeight) / 2

                for cell in 0..<cellCount {
                    let cellX = originX + CGFloat(cell) * (cellWidth + cellGap)

                    for row in 0..<3 {
                        for col in 0..<2 {
                            let cx = cellX + CGFloat(col) * (dotSize + innerSpacing) + dotSize / 2
                            let cy = originY + CGFloat(row) * (dotSize + innerSpacing) + dotSize / 2

                            let globalCol = cell * 2 + col
                            let dotIndex = cell * 6 + row * 2 + col
                            let opacity = Self.dotOpacity(col: globalCol, row: row, cell: cell, dotIndex: dotIndex, time: time)

                            guard opacity > 0.05 else { continue }

                            // Outer glow — liquid metal sheen
                            let glowSize = dotSize * 2.5
                            ctx.opacity = opacity * 0.18
                            ctx.fill(
                                Circle().path(in: CGRect(x: cx - glowSize / 2, y: cy - glowSize / 2, width: glowSize, height: glowSize)),
                                with: .color(metalMid)
                            )

                            // Main dot — metallic base
                            ctx.opacity = opacity
                            ctx.fill(
                                Circle().path(in: CGRect(x: cx - dotSize / 2, y: cy - dotSize / 2, width: dotSize, height: dotSize)),
                                with: .color(metalDark)
                            )

                            // Mid-layer — brighter metal fill, slightly inset
                            let innerSize = dotSize * 0.75
                            ctx.opacity = opacity
                            ctx.fill(
                                Circle().path(in: CGRect(x: cx - innerSize / 2, y: cy - innerSize / 2 - 0.5, width: innerSize, height: innerSize)),
                                with: .color(metalMid)
                            )

                            // Specular highlight — top-left hot spot
                            let hlSize = dotSize * 0.38
                            ctx.opacity = opacity * 0.85
                            ctx.fill(
                                Circle().path(in: CGRect(x: cx - dotSize * 0.18 - hlSize / 2, y: cy - dotSize * 0.22 - hlSize / 2, width: hlSize, height: hlSize)),
                                with: .color(metalBright)
                            )

                            // Tiny peak highlight — the "mercury droplet" glint
                            let peakSize = dotSize * 0.18
                            ctx.opacity = opacity * 0.6
                            ctx.fill(
                                Circle().path(in: CGRect(x: cx - dotSize * 0.12 - peakSize / 2, y: cy - dotSize * 0.18 - peakSize / 2, width: peakSize, height: peakSize)),
                                with: .color(.white)
                            )
                        }
                    }
                }
            }
        }
        .frame(height: 3 * dotSize + 2 * innerSpacing + 20)
        .accessibilityLabel("Processing animation")
    }

    // Chaotic opacity: mix of directional waves, counter-waves, random pulses, and flicker
    private static func dotOpacity(col: Int, row: Int, cell: Int, dotIndex: Int, time: Double) -> Double {
        // Wave moving right
        let rightWave = sin(time * 2.6 + Double(col) * 0.5 + Double(row) * 1.1)
        // Wave moving left (negative col coefficient)
        let leftWave = sin(time * 3.1 - Double(col) * 0.7 + Double(row) * 0.6)
        // Vertical pulse per column
        let vertPulse = cos(time * 4.2 + Double(cell) * 2.3)
        // Per-dot pseudo-random flicker using golden ratio hash
        let hash = Double(dotIndex) * 1.618033988749895
        let flicker = sin(time * 5.7 + hash * 6.283) * cos(time * 3.9 + hash * 3.7)
        // Slow drift that changes which pattern dominates over time
        let drift = sin(time * 0.4 + Double(cell) * 0.8)

        // Blend: drift controls whether wave-based or flicker-based motion dominates
        let wavePart = (rightWave + leftWave + vertPulse) / 3.0
        let flickerWeight = (drift + 1.0) / 2.0 * 0.6 // 0…0.6
        let combined = wavePart * (1.0 - flickerWeight) + flicker * flickerWeight

        // Quantize with a bit of jitter at boundaries
        let jitter = sin(hash * 11.3 + time * 7.1) * 0.08
        let threshold = combined + jitter

        if threshold > 0.3 { return 1.0 }
        else if threshold > 0.0 { return 0.45 }
        else if threshold > -0.3 { return 0.12 }
        else { return 0.0 }
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
