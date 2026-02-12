import SwiftUI

struct GrainOverlay: View {
    var body: some View {
        Rectangle()
            .fill(Color(white: 0.5))
            .colorEffect(
                ShaderLibrary.grainEffect(
                    .float(0.10),
                    .float(42.0)
                )
            )
            .blendMode(.screen)
            .opacity(0.22)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
