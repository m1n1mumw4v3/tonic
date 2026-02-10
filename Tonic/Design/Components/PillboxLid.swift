import SwiftUI

struct PillboxLid: View {
    let userName: String

    // MARK: - Metal palette

    private static let metalDark    = Color(red: 0.42, green: 0.44, blue: 0.48)
    private static let metalMid     = Color(red: 0.55, green: 0.57, blue: 0.61)
    private static let metalLight   = Color(red: 0.68, green: 0.70, blue: 0.73)
    private static let metalBright  = Color(red: 0.78, green: 0.80, blue: 0.82)
    private static let metalHighlight = Color(red: 0.88, green: 0.89, blue: 0.91)

    private static let etchColor    = Color(red: 0.35, green: 0.37, blue: 0.40)
    private static let etchLight    = Color(red: 0.52, green: 0.54, blue: 0.57)

    var body: some View {
        ZStack {
            // Personalized etching — centered on the full lid
            VStack(spacing: DesignTokens.spacing4) {
                // Decorative line
                Rectangle()
                    .fill(Self.etchColor)
                    .frame(width: 40, height: 1)
                    .padding(.bottom, DesignTokens.spacing4)

                Text("\(userName)'s")
                    .font(Font.custom("GeistPixel-Grid", size: 28))
                    .foregroundStyle(Self.etchColor)

                Text("Supplement Program")
                    .font(Font.custom("GeistPixel-Grid", size: 28))
                    .foregroundStyle(Self.etchColor)

                // Decorative line
                Rectangle()
                    .fill(Self.etchColor)
                    .frame(width: 40, height: 1)
                    .padding(.top, DesignTokens.spacing4)
            }
            .multilineTextAlignment(.center)
            // Debossed etch: dark text with a subtle bright inset below
            .shadow(color: Self.etchLight.opacity(0.4), radius: 0, x: 0, y: 1)

            // Slide hint pinned to top
            VStack(spacing: DesignTokens.spacing8) {
                // Metal capsule handle
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Self.metalHighlight, Self.metalMid],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 36, height: 4)
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)

                Text("Slide to open")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(Self.etchColor)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Self.etchColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, DesignTokens.spacing24)
        }
        .frame(maxWidth: .infinity)
        // 1. Base aluminum gradient — convex surface (bright center, darker edges)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Self.metalBright, location: 0),
                            .init(color: Self.metalLight, location: 0.2),
                            .init(color: Self.metalMid, location: 0.55),
                            .init(color: Self.metalDark, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        // 2. Radial glow — overhead point light hotspot
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.06),
                            .clear,
                        ],
                        center: .init(x: 0.5, y: 0.18),
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .allowsHitTesting(false)
        )
        // 3. Specular highlight — sharp glint near top
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.35), location: 0),
                            .init(color: .white.opacity(0.18), location: 0.08),
                            .init(color: .white.opacity(0.04), location: 0.22),
                            .init(color: .clear, location: 0.38),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        )
        // 4. Edge-to-edge curvature — darken left/right edges
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.12), location: 0),
                            .init(color: .clear, location: 0.15),
                            .init(color: .clear, location: 0.85),
                            .init(color: .black.opacity(0.12), location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .allowsHitTesting(false)
        )
        // 5. Chamfered edge stroke — bright top bevel, dark bottom
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Self.metalHighlight, location: 0),
                            .init(color: Self.metalBright.opacity(0.6), location: 0.25),
                            .init(color: Self.metalMid.opacity(0.3), location: 0.5),
                            .init(color: Self.metalDark.opacity(0.8), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
        // 6. Inner highlight line
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge - 1)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.25), location: 0),
                            .init(color: Color.white.opacity(0.08), location: 0.15),
                            .init(color: .clear, location: 0.35),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .padding(1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
        // Drop shadows for physical weight
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 6)
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
    }
}
