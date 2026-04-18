import SwiftUI

struct OrbBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var yellowOffset: CGSize = .zero
    @State private var yellowScale: CGFloat = 1.0
    @State private var pinkOffset: CGSize = .zero
    @State private var pinkScale: CGFloat = 1.0
    @State private var showPink = false
    @State private var screenSize: CGSize = .zero

    private let yellowInner = Color(hex: "#FAC655")
    private let yellowOuter = Color(hex: "#96953F")
    private let pinkInner = Color(hex: "#DE62A4")
    private let pinkOuter = Color(hex: "#8F3B43")

    var body: some View {
        GeometryReader { geo in
            let orbSize = max(geo.size.width, geo.size.height) * 1.0

            ZStack {
                Color(hex: "#0D0D0D")

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [yellowInner, yellowInner, yellowOuter, yellowOuter.opacity(0.6)],
                            center: .center,
                            startRadius: orbSize * 0.02,
                            endRadius: orbSize * 0.5
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                    .blur(radius: 60)
                    .offset(yellowOffset)
                    .scaleEffect(yellowScale)
                    .opacity(showPink ? 0 : 1)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [pinkInner, pinkInner, pinkOuter, pinkOuter.opacity(0.6)],
                            center: .center,
                            startRadius: orbSize * 0.02,
                            endRadius: orbSize * 0.5
                        )
                    )
                    .frame(width: orbSize * 0.95, height: orbSize * 0.95)
                    .blur(radius: 60)
                    .offset(pinkOffset)
                    .scaleEffect(pinkScale)
                    .opacity(showPink ? 1 : 0)
            }
            .onAppear {
                screenSize = geo.size
                guard !reduceMotion else { return }
                randomizePositions()
                startDriftTimer()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    startColorCycle()
                }
            }
        }
    }

    private func randomizePositions() {
        let driftX = screenSize.width * 0.45
        let driftY = screenSize.height * 0.35
        withAnimation(.easeInOut(duration: .random(in: 3...5))) {
            yellowOffset = CGSize(
                width: .random(in: -driftX...driftX),
                height: .random(in: -driftY...driftY)
            )
            yellowScale = .random(in: 0.7...1.3)
        }
        withAnimation(.easeInOut(duration: .random(in: 3.5...5.5))) {
            pinkOffset = CGSize(
                width: .random(in: -driftX...driftX),
                height: .random(in: -driftY...driftY)
            )
            pinkScale = .random(in: 0.7...1.3)
        }
    }

    private func startDriftTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 2.5...4)) {
            randomizePositions()
            startDriftTimer()
        }
    }

    private func startColorCycle() {
        withAnimation(.easeInOut(duration: 3.5)) {
            showPink = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.easeInOut(duration: 3.5)) {
                showPink = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                startColorCycle()
            }
        }
    }
}
