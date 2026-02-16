import SwiftUI

struct CompactProgressRing: View {
    let progress: Double
    var size: CGFloat = 48
    var lineWidth: CGFloat = 4
    var label: String? = nil

    @State private var animatedProgress: Double = 0

    private let spectrumColors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentMood,
        DesignTokens.accentGut
    ]

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(DesignTokens.bgElevated, lineWidth: lineWidth)
                .frame(width: size, height: size)

            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: spectrumColors + [spectrumColors[0]],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Center label
            if let label {
                Text(label)
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textPrimary)
            }
        }
        .frame(width: size + lineWidth, height: size + lineWidth)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CompactProgressRing(progress: 0.375, label: "3/8")
        CompactProgressRing(progress: 1.0, label: "8/8")
        CompactProgressRing(progress: 0.0, label: "0/8")
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}
