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
        supplements: [PlanSupplement]
    ) -> some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: DesignTokens.spacing4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tint)
                    .opacity(isComplete ? 1.0 : 0.7)
                    .animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: isComplete)
                Text(label)
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)
                if isComplete {
                    AnimatedCheckmark(isChecked: true, color: DesignTokens.textPrimary, size: 12)
                        .transition(.opacity)
                }
                Spacer()
                if !isComplete {
                    Button {
                        onTakeAllSection?(supplements.map(\.id))
                    } label: {
                        Text("TAKE ALL")
                            .font(DesignTokens.sectionHeader)
                            .tracking(0.5)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                    .transition(.opacity)
                }
            }
            .animation(reduceMotion ? .none : .easeOut(duration: 0.3), value: isComplete)
            .padding(.horizontal, DesignTokens.spacing16)
            .padding(.top, DesignTokens.spacing12)
            .padding(.bottom, DesignTokens.spacing4)

            // Rows
            ForEach(Array(supplements.enumerated()), id: \.element.id) { index, supplement in
                SupplementLogRow(
                    supplement: supplement,
                    isTaken: supplementStates[supplement.id] ?? false,
                    onToggle: { onToggle(supplement.id) }
                )
            }

            Spacer().frame(height: DesignTokens.spacing4)
        }
        .background(
            ZStack {
                // Spectrum glow (behind card)
                if isComplete {
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
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.4), value: isComplete)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .overlay(
            SpectrumProgressBorder(progress: progress, cornerRadius: DesignTokens.radiusMedium)
                .animation(
                    reduceMotion ? .none : .easeOut(duration: 0.35),
                    value: progress
                )
        )
    }
}

// MARK: - Spectrum Progress Border

private struct SpectrumProgressBorder: View {
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

private struct TopLeftRoundedRect: Shape {
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
