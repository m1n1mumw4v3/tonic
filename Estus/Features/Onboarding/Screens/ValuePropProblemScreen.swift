import SwiftUI

struct ValuePropProblemScreen: View {
    let onContinue: () -> Void

    @State private var showHeadline = false

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                DeficiencyRingView()
                    .frame(width: 160, height: 160)
                    .padding(.top, DesignTokens.spacing48)
                    .padding(.bottom, DesignTokens.spacing48)

                // Headline
                VStack(alignment: .leading, spacing: DesignTokens.spacing20) {
                    Text("Did you know: 92% of people are deficient in at least one essential vitamin or mineral.")
                        .font(.custom("Geist-Light", size: 22))
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("Source: The Journal of Nutrition")
                        .font(.custom("Geist-Regular", size: 11))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showHeadline ? 1 : 0)
                .offset(y: showHeadline ? 0 : 12)
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                // CTA
                CTAButton(title: "Continue", style: .primary, action: onContinue)
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onAppear {
            // Headline slides up after ring starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showHeadline = true
                }
            }

            // TODO: PostHog — value_prop_screen_viewed (screen: "problem")
        }
    }
}

#Preview {
    ValuePropProblemScreen(onContinue: {})
}
