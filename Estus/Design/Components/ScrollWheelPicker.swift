import SwiftUI

struct ScrollWheelPicker<Item: Hashable>: View {
    @Binding var selection: Item
    let items: [Item]
    let label: (Item) -> String

    var itemHeight: CGFloat = 56
    var visibleItemCount: Int = 5

    @State private var scrollPosition: Item?

    private var totalHeight: CGFloat {
        CGFloat(visibleItemCount) * itemHeight
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Top padding to center first item
                Color.clear
                    .frame(height: itemHeight * CGFloat(visibleItemCount / 2))

                ForEach(items, id: \.self) { item in
                    GeometryReader { geo in
                        let midY = geo.frame(in: .named("picker")).midY
                        let centerY = totalHeight / 2
                        let distance = abs(midY - centerY)
                        let maxDistance = itemHeight * CGFloat(visibleItemCount / 2)
                        let progress = min(distance / maxDistance, 1.0)

                        let scale = 1.0 - (progress * 0.35)
                        let opacity = 1.0 - (progress * 0.75)
                        let isCenter = distance < itemHeight / 2

                        Text(label(item))
                            .font(isCenter
                                ? .custom("GeistMono-Medium", size: 40)
                                : .custom("GeistMono-Regular", size: 32))
                            .foregroundStyle(DesignTokens.textPrimary)
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .frame(maxWidth: .infinity)
                            .frame(height: itemHeight)
                    }
                    .frame(height: itemHeight)
                    .id(item)
                }

                // Bottom padding to center last item
                Color.clear
                    .frame(height: itemHeight * CGFloat(visibleItemCount / 2))
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .coordinateSpace(name: "picker")
        .frame(height: totalHeight)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.25),
                    .init(color: .white, location: 0.75),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            scrollPosition = selection
        }
        .onChange(of: scrollPosition) { _, newValue in
            if let newValue, newValue != selection {
                selection = newValue
                HapticManager.selection()
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var age = 30
        var body: some View {
            ScrollWheelPicker(
                selection: $age,
                items: Array(18...100),
                label: { "\($0)" }
            )
            .background(DesignTokens.bgDeepest)
        }
    }
    return PreviewWrapper()
}
