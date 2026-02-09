import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    @State private var visibleCharacters: Int = 0
    @State private var ringProgress: CGFloat = 0
    @State private var showTagline = false
    @State private var showCTA = false
    @State private var glowOpacity: CGFloat = 0
    @State private var glowScale: CGFloat = 1.0
    private let fullText = "Tonic."

    private var totalDuration: Double {
        Double(fullText.count) * 0.18 + 0.3
    }

    private let spectrumColors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentMood,
        DesignTokens.accentGut
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: DesignTokens.spacing32) {
                Spacer()

                // Logo block — spectrum ring + typewriter text
                ZStack {
                    // Background track
                    Circle()
                        .stroke(DesignTokens.bgElevated, lineWidth: 10)
                        .frame(width: 200, height: 200)

                    // Spectrum fill
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: spectrumColors + [spectrumColors[0]],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))

                    // Glow bloom on completion
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: spectrumColors + [spectrumColors[0]],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 14)
                        .opacity(glowOpacity)
                        .scaleEffect(glowScale)

                    // Typewriter text
                    Text(String(fullText.prefix(visibleCharacters)))
                        .font(.custom("GeistPixel-Grid", size: 57))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .tracking(64 * -0.03)
                        .frame(minWidth: 1)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: totalDuration)) {
                        ringProgress = 1.0
                    }
                    typeText()
                }

                // Tagline
                Text("Your supplements, optimized.")
                    .font(DesignTokens.titleFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 8)

                Spacer()

                // CTA
                CTAButton(title: "Get Started", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 8)
            }
        }
    }

    private func typeText() {
        for index in 1...fullText.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.18) {
                withAnimation(.easeOut(duration: 0.05)) {
                    visibleCharacters = index
                }

                // Last character — trigger cascade
                if index == fullText.count {
                    HapticManager.impact(.light)

                    // Glow bloom: flash on, then expand + fade
                    glowOpacity = 0.8
                    withAnimation(.easeOut(duration: 1.0)) {
                        glowScale = 1.4
                        glowOpacity = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showTagline = true
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showCTA = true
                        }
                        HapticManager.impact(.medium)
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeScreen(onContinue: {})
}
