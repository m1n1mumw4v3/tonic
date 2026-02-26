import SwiftUI

struct SupplementLogList: View {
    let supplements: [PlanSupplement]
    let supplementStates: [UUID: Bool]
    let onToggle: (UUID) -> Void
    var onTakeAllSection: (([UUID]) -> Void)?
    var amProgress: CGFloat = 0
    var pmProgress: CGFloat = 0
    var amComplete: Bool = false
    var pmComplete: Bool = false

    @State private var amExpanded = false
    @State private var pmExpanded = false
    @State private var amCollapsed = false
    @State private var pmCollapsed = false
    @State private var amTakeAllFired = false
    @State private var pmTakeAllFired = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let amTimings: Set<SupplementTiming> = [.emptyStomach, .morning, .withFood]
    private static let pmTimings: Set<SupplementTiming> = [.afternoon, .evening, .bedtime]

    private var activeSupplements: [PlanSupplement] {
        supplements.filter { !$0.isRemoved }
    }

    private var amSupplements: [PlanSupplement] {
        activeSupplements
            .filter { Self.amTimings.contains($0.timing) }
            .sorted { $0.timing.sortOrder < $1.timing.sortOrder }
    }

    private var pmSupplements: [PlanSupplement] {
        activeSupplements
            .filter { Self.pmTimings.contains($0.timing) }
            .sorted { $0.timing.sortOrder < $1.timing.sortOrder }
    }


    var body: some View {
        VStack(spacing: DesignTokens.spacing20) {
            // Morning section
            if !amSupplements.isEmpty {
                sectionContainer(
                    icon: "sun.max.fill",
                    label: "AM",
                    tint: DesignTokens.accentEnergy,
                    progress: amProgress,
                    isComplete: amComplete,
                    isExpanded: $amExpanded,
                    isCollapsed: $amCollapsed,
                    takeAllFired: $amTakeAllFired,
                    supplements: amSupplements
                )
            }

            // Evening section
            if !pmSupplements.isEmpty {
                sectionContainer(
                    icon: "moon.fill",
                    label: "PM",
                    tint: DesignTokens.accentSleep,
                    progress: pmProgress,
                    isComplete: pmComplete,
                    isExpanded: $pmExpanded,
                    isCollapsed: $pmCollapsed,
                    takeAllFired: $pmTakeAllFired,
                    supplements: pmSupplements
                )
            }
        }
    }

    // MARK: - Section Container

    private func sectionContainer(
        icon: String,
        label: String,
        tint: Color,
        progress: CGFloat,
        isComplete: Bool,
        isExpanded: Binding<Bool>,
        isCollapsed: Binding<Bool>,
        takeAllFired: Binding<Bool>,
        supplements: [PlanSupplement]
    ) -> some View {
        let showRows = !isCollapsed.wrappedValue || isExpanded.wrappedValue

        return VStack(spacing: 0) {
            // Section header
            HStack(spacing: DesignTokens.spacing4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(tint)
                    .opacity(isComplete ? 1.0 : 0.7)
                Text(label)
                    .font(.custom("Geist-SemiBold", size: 16))
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)
                if isCollapsed.wrappedValue {
                    HStack(spacing: 4) {
                        AnimatedCheckmark(isChecked: true, color: .white, size: 8)
                        Text("COMPLETE")
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, DesignTokens.spacing8)
                    .padding(.vertical, 3)
                    .background(DesignTokens.positive)
                    .clipShape(Capsule())
                    .transition(.opacity)
                }
                Spacer()
                if isCollapsed.wrappedValue {
                    HStack(spacing: DesignTokens.spacing4) {
                        Text(isExpanded.wrappedValue ? "Edit" : "")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textTertiary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DesignTokens.textTertiary)
                            .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.5)) {
                            isExpanded.wrappedValue.toggle()
                        }
                    }
                    .transition(.opacity)
                } else if onTakeAllSection != nil {
                    Button {
                        guard !takeAllFired.wrappedValue else { return }
                        takeAllFired.wrappedValue = true
                        HapticManager.impact(.light)
                        onTakeAllSection?(supplements.map(\.id))
                    } label: {
                        Text("TAKE ALL")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.positive)
                    }
                    .disabled(takeAllFired.wrappedValue)
                }
            }
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.top, DesignTokens.spacing12)
            .padding(.bottom, showRows ? DesignTokens.spacing4 : DesignTokens.spacing12)

            // Rows (collapse when section is complete and not expanded)
            if showRows {
                ForEach(Array(supplements.enumerated()), id: \.element.id) { index, supplement in
                    SupplementLogRow(
                        supplement: supplement,
                        isTaken: supplementStates[supplement.id] ?? false,
                        onToggle: { onToggle(supplement.id) }
                    )
                }

            }
        }
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.6), value: isCollapsed.wrappedValue)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.5), value: isExpanded.wrappedValue)
        .onChange(of: isComplete) { _, complete in
            if complete {
                // Delay the collapse so checkmark animations finish first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isCollapsed.wrappedValue = true
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isCollapsed.wrappedValue = false
                    isExpanded.wrappedValue = false
                }
                takeAllFired.wrappedValue = false
            }
        }
        .background(
            ZStack {
                // Spectrum glow (behind card)
                if isCollapsed.wrappedValue {
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(
                            AngularGradient(
                                colors: DesignTokens.spectrumColors + [DesignTokens.spectrumColors[0]],
                                center: .center
                            ),
                            lineWidth: 4
                        )
                        .blur(radius: 8)
                        .opacity(0.4)
                        .transition(.opacity)
                }

                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .fill(DesignTokens.bgSurface)
            }
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.6), value: isCollapsed.wrappedValue)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .overlay(
            SpectrumProgressBorder(progress: progress, cornerRadius: DesignTokens.radiusMedium)
                .animation(
                    reduceMotion ? .none : .easeOut(duration: 0.5),
                    value: progress
                )
        )
    }
}

// MARK: - Spectrum Progress Border

struct SpectrumProgressBorder: View {
    let progress: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        TopLeftRoundedRect(cornerRadius: cornerRadius)
            .trim(from: 0, to: progress)
            .stroke(
                AngularGradient(
                    colors: DesignTokens.spectrumColors + [DesignTokens.spectrumColors[0]],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
    }
}

// MARK: - Custom Shape (starts top-left)

struct TopLeftRoundedRect: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)

        // Start at top-left, just after the corner
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))

        // Top edge → top-right corner
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
        )

        // Right edge → bottom-right corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
            radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )

        // Bottom edge → bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
            radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )

        // Left edge → top-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )

        return path
    }
}
