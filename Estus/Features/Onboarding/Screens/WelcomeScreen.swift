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
                        WelcomeOrbBackground()

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

// MARK: - Animated Orb Background

private struct WelcomeOrbBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Continuous position & scale targets, randomized on a timer
    @State private var yellowOffset: CGSize = .zero
    @State private var yellowScale: CGFloat = 1.0
    @State private var pinkOffset: CGSize = .zero
    @State private var pinkScale: CGFloat = 1.0
    @State private var showPink = false

    private let yellowInner = Color(hex: "#E0B23D")
    private let yellowOuter = Color(hex: "#96953F")
    private let pinkInner = Color(hex: "#C25D93")
    private let pinkOuter = Color(hex: "#8F3B43")

    var body: some View {
        GeometryReader { geo in
            let orbSize = max(geo.size.width, geo.size.height) * 1.6

            ZStack {
                Color(hex: "#0D0D0D")

                // Yellow orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [yellowInner, yellowInner, yellowOuter, yellowOuter.opacity(0.6)],
                            center: .center,
                            startRadius: orbSize * 0.02,
                            endRadius: orbSize * 0.5
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                    .blur(radius: 60)
                    .offset(yellowOffset)
                    .scaleEffect(yellowScale)
                    .opacity(showPink ? 0 : 1)

                // Pink orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [pinkInner, pinkInner, pinkOuter, pinkOuter.opacity(0.6)],
                            center: .center,
                            startRadius: orbSize * 0.02,
                            endRadius: orbSize * 0.5
                        )
                    )
                    .frame(width: orbSize * 0.95, height: orbSize * 0.95)
                    .blur(radius: 60)
                    .offset(pinkOffset)
                    .scaleEffect(pinkScale)
                    .opacity(showPink ? 1 : 0)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            randomizePositions()
            startDriftTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                startColorCycle()
            }
        }
    }

    private func randomizePositions() {
        let drift: CGFloat = 180
        withAnimation(.easeInOut(duration: .random(in: 3...5))) {
            yellowOffset = CGSize(
                width: .random(in: -drift...drift),
                height: .random(in: -drift...drift)
            )
            yellowScale = .random(in: 0.7...1.3)
        }
        withAnimation(.easeInOut(duration: .random(in: 3.5...5.5))) {
            pinkOffset = CGSize(
                width: .random(in: -drift...drift),
                height: .random(in: -drift...drift)
            )
            pinkScale = .random(in: 0.7...1.3)
        }
    }

    private func startDriftTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 2.5...4)) {
            randomizePositions()
            startDriftTimer()
        }
    }

    private func startColorCycle() {
        withAnimation(.easeInOut(duration: 3.5)) {
            showPink = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.easeInOut(duration: 3.5)) {
                showPink = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                startColorCycle()
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
