import SwiftUI

struct RemovableChip: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.spacing8) {
            Text(name)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .lineLimit(1)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
        }
        .padding(.leading, DesignTokens.spacing16)
        .padding(.trailing, DesignTokens.spacing12)
        .padding(.vertical, DesignTokens.spacing12)
        .background(DesignTokens.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusFull)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }
}
