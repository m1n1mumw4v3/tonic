import SwiftUI

struct EmberGlowModifier: ViewModifier {
    let isActive: Bool
    var intensity: CGFloat = 0.12

    @State private var viewSize: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool {
        isActive && !reduceMotion && viewSize.width > 0
    }

    func body(content: Content) -> some View {
        if shouldAnimate {
            TimelineView(.periodic(from: .now, by: 1.0 / 20.0)) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                content
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newSize in
                        viewSize = newSize
                    }
                    .colorEffect(
                        ShaderLibrary.emberGlow(
                            .float2(Float(viewSize.width), Float(viewSize.height)),
                            .float(Float(elapsed)),
                            .float(Float(intensity))
                        )
                    )
            }
        } else {
            content
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newSize in
                    viewSize = newSize
                }
        }
    }
}

extension View {
    func emberGlow(isActive: Bool, intensity: CGFloat = 0.12) -> some View {
        modifier(EmberGlowModifier(isActive: isActive, intensity: intensity))
    }
}
