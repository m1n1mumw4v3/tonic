import SwiftUI

struct WellbeingPreviewCard: View {
    var animated: Bool = true

    @State private var appeared = false
    @State private var sparklineProgress: CGFloat = 0

    // Sparkline data — gentle upward trend (10-point scale)
    private let sparklinePoints: [CGFloat] = [6.2, 6.5, 6.8, 7.2, 7.5, 7.8, 8.0]

    var body: some View {
        VStack(spacing: DesignTokens.spacing16) {
            WellbeingScoreRing(
                sleepScore: 8,
                energyScore: 7,
                clarityScore: 9,
                moodScore: 8,
                gutScore: 7,
                size: 100,
                lineWidth: 8,
                animated: animated
            )

            // Sparkline
            SparklineView(points: sparklinePoints, progress: sparklineProgress)
                .frame(height: 40)
                .padding(.horizontal, DesignTokens.spacing8)
        }
        .padding(DesignTokens.spacing20)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            guard animated else {
                appeared = true
                sparklineProgress = 1
                return
            }

            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.6)) {
                    sparklineProgress = 1
                }
            }
        }
    }
}

// MARK: - Sparkline

private struct SparklineView: View {
    let points: [CGFloat]
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minVal = points.min() ?? 0
            let maxVal = points.max() ?? 100
            let range = max(maxVal - minVal, 1)

            let coords: [CGPoint] = points.enumerated().map { i, val in
                CGPoint(
                    x: CGFloat(i) / CGFloat(points.count - 1) * w,
                    y: h - ((val - minVal) / range) * h
                )
            }

            // Gradient fill below line
            Path { path in
                guard let first = coords.first else { return }
                path.move(to: CGPoint(x: first.x, y: h))
                path.addLine(to: first)
                for pt in coords.dropFirst() {
                    path.addLine(to: pt)
                }
                if let last = coords.last {
                    path.addLine(to: CGPoint(x: last.x, y: h))
                }
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [DesignTokens.positive.opacity(0.25), DesignTokens.positive.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .mask(
                Rectangle()
                    .frame(width: w * progress)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )

            // Line
            Path { path in
                guard let first = coords.first else { return }
                path.move(to: first)
                for pt in coords.dropFirst() {
                    path.addLine(to: pt)
                }
            }
            .trim(from: 0, to: progress)
            .stroke(DesignTokens.positive, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

#Preview {
    WellbeingPreviewCard()
        .padding(24)
        .background(DesignTokens.bgDeepest)
}
