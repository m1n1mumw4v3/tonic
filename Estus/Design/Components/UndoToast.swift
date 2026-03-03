import SwiftUI

struct UndoToast: View {
    let message: String
    let onUndo: () -> Void
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: DesignTokens.spacing12) {
            Text(message)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .lineLimit(1)

            Spacer()

            Button {
                onUndo()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            } label: {
                Text("Undo")
                    .font(DesignTokens.ctaFont)
                    .foregroundStyle(DesignTokens.info)
            }
        }
        .padding(.horizontal, DesignTokens.spacing16)
        .padding(.vertical, DesignTokens.spacing12)
        .background(DesignTokens.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        .padding(.horizontal, DesignTokens.spacing16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            }
        }
    }
}
