import SwiftUI

struct DeepProfileCompletionScreen: View {
    let moduleType: DeepProfileModuleType
    let onDone: () -> Void

    @State private var showCheckmark = false
    @State private var showText = false
    @State private var showCTA = false
    @State private var checkScale: CGFloat = 0.3
    @State private var glowOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: DesignTokens.spacing32) {
            Spacer()

            // Animated checkmark
            ZStack {
                Circle()
                    .fill(moduleType.accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1 : 0)

                Circle()
                    .fill(moduleType.accentColor.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .opacity(glowOpacity)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(moduleType.accentColor)
                    .scaleEffect(checkScale)
                    .opacity(showCheckmark ? 1 : 0)
            }

            VStack(spacing: DesignTokens.spacing12) {
                Text("\(moduleType.displayName) Complete")
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 8)

                Text("Your responses will help refine your supplement plan over time.")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 8)
            }

            Spacer()

            CTAButton(title: "Done", style: .primary, action: onDone)
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
                .opacity(showCTA ? 1 : 0)
                .offset(y: showCTA ? 0 : 8)
        }
        .onAppear {
            animateEntrance()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
            showCheckmark = true
            checkScale = 1.0
        }

        // Glow bloom
        withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
            glowOpacity = 0.6
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
            glowOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.4)) {
                showText = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.4)) {
                showCTA = true
            }
        }
    }
}
