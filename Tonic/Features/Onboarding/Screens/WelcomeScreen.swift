import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    @State private var showLogo = false
    @State private var showTagline = false
    @State private var showCTA = false

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            GradientFlowBackground()
            GrainOverlay()

            VStack(spacing: DesignTokens.spacing32) {
                Spacer()

                // Wordmark
                Image("AmpleLogomark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 260)
                    .padding(.horizontal, DesignTokens.spacing32)
                    .opacity(showLogo ? 1 : 0)
                    .offset(y: showLogo ? 0 : 8)

                // Tagline
                Text("YOUR BODY KNOWS.\nNOW YOU WILL TOO.")
                    .font(DesignTokens.captionFont)
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, -DesignTokens.spacing16)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 6)

                Spacer()

                // CTA
                Button(action: {
                    HapticManager.impact(.light)
                    onContinue()
                }) {
                    Text("Get Started")
                        .font(DesignTokens.ctaFont)
                        .tracking(0.32)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(DesignTokens.bgDeepest)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                }
                .buttonStyle(ScalePressStyle())
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
                .opacity(showCTA ? 1 : 0)
                .offset(y: showCTA ? 0 : 8)
            }
        }
        .onAppear {
            // Logo fade in
            withAnimation(.easeOut(duration: 0.6)) {
                showLogo = true
            }

            // Tagline staggered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showTagline = true
                }
            }

            // CTA staggered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showCTA = true
                }
                HapticManager.impact(.medium)
            }
        }
    }
}

private struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    WelcomeScreen(onContinue: {})
}
