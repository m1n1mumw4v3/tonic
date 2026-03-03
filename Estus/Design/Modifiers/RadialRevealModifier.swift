import SwiftUI

struct RadialRevealModifier: ViewModifier {
    let progress: CGFloat
    let tapPoint: CGPoint
    let cardSize: CGSize
    let useMetalShaders: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if useMetalShaders && !reduceMotion {
            content
                .layerEffect(
                    ShaderLibrary.radialReveal(
                        .float2(Float(tapPoint.x), Float(tapPoint.y)),
                        .float2(Float(cardSize.width), Float(cardSize.height)),
                        .float(Float(progress)),
                        .float(12.0) // feather width in pts
                    ),
                    maxSampleOffset: .zero
                )
        } else {
            // Fallback: simple opacity cross-fade
            content
                .opacity(progress)
        }
    }
}

extension View {
    func radialReveal(progress: CGFloat, tapPoint: CGPoint, cardSize: CGSize, useMetalShaders: Bool) -> some View {
        modifier(RadialRevealModifier(progress: progress, tapPoint: tapPoint, cardSize: cardSize, useMetalShaders: useMetalShaders))
    }
}
