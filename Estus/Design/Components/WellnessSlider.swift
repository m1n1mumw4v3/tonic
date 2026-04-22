import SwiftUI

struct WellnessSlider: View {
    let dimension: WellnessDimension
    @Binding var value: Double
    let lowLabel: String
    let highLabel: String
    var averageValue: Double? = nil
    var accentOverride: Color? = nil

    private var accentColor: Color {
        accentOverride ?? dimension.color
    }

    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0

    private let detentInterval: Double = 1
    @State private var lastDetent: Int = -1

    @State private var pulseProgress: CGFloat = 0
    @State private var pulseOpacity: Double = 0
    @State private var thumbLanding: Bool = false
    @State private var showPrompt = false

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
                        .foregroundStyle(accentColor)

                    Text(dimension.label)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(accentColor)

                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(accentColor.opacity(0.6))
                        .onTapGesture {
                            showPrompt.toggle()
                        }
                        .popover(isPresented: $showPrompt, arrowEdge: .top) {
                            Text(dimension.prompt)
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: 240, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .presentationCompactAdaptation(.popover)
                        }
                }
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragging)

                Spacer()

                Text("\(Int(value))")
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(accentColor)
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

                    // Filled track
                    Capsule()
                        .fill(accentColor.opacity(0.6))
                        .frame(width: max(0, thumbX), height: trackHeight)
                        .animation(springCurve, value: isDragging)

                    // 7-day average marker
                    if let avg = averageValue {
                        let avgX = width * avg / 10

                        Text("7D avg")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(accentColor.opacity(0.55))
                            .position(x: avgX, y: -1)
                            .allowsHitTesting(false)

                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(accentColor.opacity(0.55))
                            .position(x: avgX, y: 8)
                            .allowsHitTesting(false)
                    }

                    // Thumb glow bloom
                    Circle()
                        .fill(accentColor)
                        .frame(width: 32, height: 32)
                        .blur(radius: 16)
                        .opacity(isDragging ? 0.5 : 0)
                        .offset(x: thumbX - 16)
                        .animation(springCurve, value: isDragging)

                    // Landing pulse — layered soft glow rings
                    ZStack {
                        // Outer ring — expands farthest, fades quickly
                        Circle()
                            .stroke(accentColor, lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                            .blur(radius: 2)
                            .scaleEffect(0.8 + pulseProgress * 1.8)
                            .opacity(pulseOpacity * 0.35)

                        // Inner bloom — soft glow close to the thumb
                        Circle()
                            .fill(accentColor)
                            .frame(width: 24, height: 24)
                            .blur(radius: 8)
                            .scaleEffect(0.7 + pulseProgress * 0.9)
                            .opacity(pulseOpacity * 0.45)
                    }
                    .frame(width: 24, height: 24)
                    .offset(x: thumbX - 12)
                    .allowsHitTesting(false)

                    // Thumb
                    Circle()
                        .fill(accentColor)
                        .frame(width: 24, height: 24)
                        .shadow(color: accentColor.opacity(isDragging ? 0.5 : 0.2), radius: isDragging ? 8 : 4)
                        .scaleEffect(isDragging ? 1.35 : (thumbLanding ? 0.85 : 1.0))
                        .animation(springCurve, value: isDragging)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: thumbLanding)
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
                                    triggerLandingSplash()
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dimension.label)")
        .accessibilityValue("\(Int(value)) out of 10")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(10, round(value) + 1)
            case .decrement:
                value = max(0, round(value) - 1)
            @unknown default:
                break
            }
        }
    }

    private func triggerLandingSplash() {
        pulseProgress = 0
        pulseOpacity = 1.0
        thumbLanding = true

        // Smooth outward glow — gentle ease, no bounce
        withAnimation(.easeOut(duration: 0.7)) {
            pulseProgress = 1.0
        }

        // Fade out slightly quicker than the expansion for a clean tail
        withAnimation(.easeOut(duration: 0.55)) {
            pulseOpacity = 0
        }

        // Thumb squish then spring back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            thumbLanding = false
        }
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
