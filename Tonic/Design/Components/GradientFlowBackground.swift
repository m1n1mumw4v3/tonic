import SwiftUI

struct GradientFlowBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blobs = GradientFlowBackground.generateBlobs()

    private static let spectrumColors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentGut,
        DesignTokens.accentLongevity,
        DesignTokens.accentSleep // second purple anchor
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(blobs) { blob in
                    Circle()
                        .fill(blob.color)
                        .frame(width: blob.size, height: blob.size)
                        .blur(radius: blob.blur)
                        .opacity(blob.opacity)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Vertical gradient mask: transparent at top, opaque at bottom
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.25),
                        .init(color: .white, location: 0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Blob Model

    private struct GradientBlob: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var blur: CGFloat
        var opacity: Double
        var color: Color
        var duration: Double
        var delay: Double
        var driftX: CGFloat
        var driftY: CGFloat
        var targetScale: CGFloat
        var initialScale: CGFloat
    }

    private static func generateBlobs() -> [GradientBlob] {
        (0..<6).map { index in
            GradientBlob(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.60...0.95),
                size: CGFloat.random(in: 300...500),
                blur: CGFloat.random(in: 40...65),
                opacity: Double.random(in: 0.50...0.70),
                color: spectrumColors[index % spectrumColors.count],
                duration: Double.random(in: 5...8),
                delay: Double(index) * 0.4,
                driftX: CGFloat.random(in: -1...1) * 0.15,
                driftY: CGFloat.random(in: -1...1) * 0.12,
                targetScale: CGFloat.random(in: 1.0...1.15),
                initialScale: CGFloat.random(in: 0.85...1.0)
            )
        }
    }

    // MARK: - Drift Animation

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
}
