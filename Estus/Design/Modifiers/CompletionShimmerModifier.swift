import SwiftUI

struct CompletionShimmerModifier: ViewModifier {
    let isActive: Bool
    let progress: CGFloat
    var bandWidthFraction: CGFloat = 0.35
    var peakIntensity: CGFloat = 0.25

    @State private var viewSize: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldApply: Bool {
        isActive && !reduceMotion && viewSize.width > 0
    }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { newSize in
                viewSize = newSize
            }
            .conditionalShimmerEffect(
                shouldApply: shouldApply,
                viewSize: viewSize,
                progress: progress,
                bandWidthFraction: bandWidthFraction,
                peakIntensity: peakIntensity
            )
    }
}

private extension View {
    @ViewBuilder
    func conditionalShimmerEffect(
        shouldApply: Bool,
        viewSize: CGSize,
        progress: CGFloat,
        bandWidthFraction: CGFloat,
        peakIntensity: CGFloat
    ) -> some View {
        if shouldApply {
            self.colorEffect(
                ShaderLibrary.completionShimmer(
                    .float2(Float(viewSize.width), Float(viewSize.height)),
                    .float(Float(progress)),
                    .float(Float(bandWidthFraction)),
                    .float(Float(peakIntensity))
                )
            )
        } else {
            self
        }
    }
}

extension View {
    func completionShimmer(isActive: Bool, progress: CGFloat) -> some View {
        modifier(CompletionShimmerModifier(isActive: isActive, progress: progress))
    }
}
