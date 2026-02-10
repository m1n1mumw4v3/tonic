import SwiftUI

struct WellnessSlider: View {
    let dimension: WellnessDimension
    @Binding var value: Double
    let lowLabel: String
    let highLabel: String
    var averageValue: Double? = nil

    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0

    private let detentInterval: Double = 1
    @State private var lastDetent: Int = -1

    private let trackHeightIdle: CGFloat = 6
    private let trackHeightActive: CGFloat = 8
    private let springCurve = Animation.spring(duration: 0.3, bounce: 0.4)

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            // Dimension label + value
            HStack {
                HStack(spacing: DesignTokens.spacing4) {
                    Image(systemName: dimension.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(dimension.color)

                    Text(dimension.label)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(dimension.color)
                }
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragging)

                Spacer()

                Text("\(Int(value))")
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(dimension.color)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: Int(value))
            }

            // Custom slider
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbX = width * value / 10
                let trackHeight = isDragging ? trackHeightActive : trackHeightIdle

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(DesignTokens.bgElevated)
                        .frame(height: trackHeight)
                        .animation(springCurve, value: isDragging)

                    // Track glow (blurred copy behind fill)
                    Capsule()
                        .fill(dimension.color.opacity(0.3))
                        .frame(width: max(0, thumbX), height: trackHeight)
                        .blur(radius: 6)
                        .animation(springCurve, value: isDragging)

                    // Filled track
                    Capsule()
                        .fill(dimension.color.opacity(0.6))
                        .frame(width: max(0, thumbX), height: trackHeight)
                        .animation(springCurve, value: isDragging)

                    // 7-day average marker
                    if let avg = averageValue {
                        let avgX = width * avg / 10

                        Text("7D avg")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(dimension.color.opacity(0.55))
                            .position(x: avgX, y: -1)
                            .allowsHitTesting(false)

                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(dimension.color.opacity(0.55))
                            .position(x: avgX, y: 8)
                            .allowsHitTesting(false)
                    }

                    // Thumb glow bloom
                    Circle()
                        .fill(dimension.color)
                        .frame(width: 32, height: 32)
                        .blur(radius: 16)
                        .opacity(isDragging ? 0.5 : 0)
                        .offset(x: thumbX - 16)
                        .animation(springCurve, value: isDragging)

                    // Thumb
                    Circle()
                        .fill(dimension.color)
                        .frame(width: 24, height: 24)
                        .shadow(color: dimension.color.opacity(isDragging ? 0.5 : 0.2), radius: isDragging ? 8 : 4)
                        .scaleEffect(isDragging ? 1.35 : 1.0)
                        .animation(springCurve, value: isDragging)
                        .offset(x: thumbX - 12)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    isDragging = true
                                    let newValue = max(0, min(10, Double(gesture.location.x / width) * 10))
                                    value = newValue

                                    // Haptic detents every 10 units
                                    let currentDetent = Int(newValue / detentInterval)
                                    if currentDetent != lastDetent {
                                        lastDetent = currentDetent
                                        HapticManager.selection()
                                    }
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    // Snap to nearest whole number
                                    value = round(value)
                                    HapticManager.impact(.light)
                                }
                        )
                }
            }
            .frame(height: 24)

            // Anchor labels
            HStack {
                Text(lowLabel)
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textPrimary.opacity(0.6))
                Spacer()
                Text(highLabel)
                    .font(DesignTokens.smallMono)
                    .foregroundStyle(DesignTokens.textPrimary.opacity(0.6))
            }
        }
        .padding(.vertical, DesignTokens.spacing4)
    }
}

#Preview {
    VStack(spacing: 24) {
        WellnessSlider(
            dimension: .sleep,
            value: .constant(7),
            lowLabel: "Restless / Broken",
            highLabel: "Deep & Restorative",
            averageValue: 5.3
        )
        WellnessSlider(
            dimension: .energy,
            value: .constant(4),
            lowLabel: "Drained / Fatigued",
            highLabel: "Vibrant & Sustained",
            averageValue: 6.8
        )
    }
    .padding()
    .background(DesignTokens.bgDeepest)
}
