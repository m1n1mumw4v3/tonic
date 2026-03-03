import SwiftUI

struct UnitPicker<Unit: Hashable & CaseIterable>: View where Unit.AllCases: RandomAccessCollection {
    @Binding var selection: Unit
    let label: (Unit) -> String

    var body: some View {
        VStack(spacing: DesignTokens.spacing4) {
            ForEach(Array(Unit.allCases), id: \Unit.self) { unit in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = unit
                    }
                } label: {
                    Text(label(unit))
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(
                            selection == unit
                                ? DesignTokens.bgDeepest
                                : DesignTokens.textSecondary
                        )
                        .frame(width: 48, height: 44)
                        .background(
                            selection == unit
                                ? DesignTokens.textPrimary
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(DesignTokens.spacing4)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall + DesignTokens.spacing4))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusSmall + DesignTokens.spacing4)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
    }
}
