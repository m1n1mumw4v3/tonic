import SwiftUI

struct GrainOverlay: View {
    var body: some View {
        Rectangle()
            .fill(Color(white: 0.5))
            .colorEffect(
                ShaderLibrary.grainEffect(
                    .float(0.06),
                    .float(42.0)
                )
            )
            .blendMode(.multiply)
            .opacity(0.04)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
