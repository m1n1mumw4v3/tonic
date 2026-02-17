import SwiftUI

struct AnimatedCheckmark: View {
    let isChecked: Bool
    let color: Color
    var size: CGFloat = 20

    @State private var progress: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CheckmarkShape()
            .trim(from: 0, to: progress)
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .onChange(of: isChecked) { _, checked in
                if checked {
                    drawIn()
                } else {
                    erase()
                }
            }
            .onAppear {
                if isChecked {
                    progress = 1.0
                }
            }
    }

    private func drawIn() {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.15)) {
                progress = 1.0
            }
            return
        }

        let drawDelay: Double = 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + drawDelay) {
            withAnimation(.easeOut(duration: 0.3)) {
                progress = 1.0
            }
        }

        // Micro-scale pulse after draw completes
        DispatchQueue.main.asyncAfter(deadline: .now() + drawDelay + 0.3) {
            withAnimation(.spring(duration: 0.2, bounce: 0.5)) {
                scale = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                    scale = 1.0
                }
            }
        }
    }

    private func erase() {
        if reduceMotion {
            withAnimation(.easeIn(duration: 0.15)) {
                progress = 0
            }
            return
        }

        withAnimation(.easeIn(duration: 0.2)) {
            progress = 0
        }
    }
}

// MARK: - Checkmark Shape

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Two-line checkmark: short leg then long leg
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.50))
        path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.25))
        return path
    }
}
