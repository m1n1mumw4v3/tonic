 import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void
    var onLogin: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showLogo = false
    @State private var showTagline = false
    @State private var showButtons = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#E3E3E3").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tagline
                    Text("The supplement plan\nyour body's been asking for.")
                        .font(.custom("Geist-Regular", size: 18))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : -12)
                        .padding(.top, 50)

                    Spacer()

                    // Logo
                    Image("EstusLogomark")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 28)
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? 1 : 0.98)

                    Spacer().frame(height: 20)

                    // Animated gradient card
                    ZStack(alignment: .bottom) {
                        OrbBackground()

                        VStack(spacing: DesignTokens.spacing12) {
                            Button(action: {
                                HapticManager.impact(.light)
                                onContinue()
                            }) {
                                Text("Get Started")
                                    .font(.custom("Geist-Medium", size: 17))
                                    .tracking(0.32)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: 240)
                                    .frame(height: 52)
                                    .background(.white.opacity(0.2))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.6), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(ScalePressStyle())

                            Button(action: {
                                HapticManager.impact(.light)
                                onLogin?()
                            }) {
                                Text("I already have an account")
                                    .font(.custom("Geist-Regular", size: 14))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.top, DesignTokens.spacing4)
                        }
                        .opacity(showButtons ? 1 : 0)
                        .padding(.bottom, DesignTokens.spacing40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .frame(height: geo.size.height * 0.56)
                    .padding(.horizontal, 28)
                    .padding(.bottom, max(28 - geo.safeAreaInsets.bottom, 0))
                }
            }
        }
        .onAppear {
            guard !reduceMotion else {
                showLogo = true
                showTagline = true
                showButtons = true
                return
            }

            // Beat 1: Logo breathes in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 1.8)) {
                    showLogo = true
                }
            }

            // Beat 2: Tagline fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    showTagline = true
                }
            }

            // Beat 3: CTA buttons + haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showButtons = true
                }
                HapticManager.impact(.light)
            }
        }
    }
}

// MARK: - Button Style

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
