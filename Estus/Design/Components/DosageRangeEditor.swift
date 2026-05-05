import SwiftUI
import UIKit

// MARK: - Dosage Status

enum DosageStatus: Equatable {
    case below
    case inRange
    case above
    case exceedsLimit

    var color: Color {
        switch self {
        case .below: return DesignTokens.info
        case .inRange: return DesignTokens.positive
        case .above: return DesignTokens.accentEnergyDark
        case .exceedsLimit: return DesignTokens.negative
        }
    }

    var label: String {
        switch self {
        case .below: return "Below range"
        case .inRange: return "In range"
        case .above: return "Above range"
        case .exceedsLimit: return "Exceeds limit"
        }
    }

    var icon: String {
        switch self {
        case .below: return "arrow.down.circle.fill"
        case .inRange: return "checkmark.circle.fill"
        case .above: return "exclamationmark.circle.fill"
        case .exceedsLimit: return "exclamationmark.triangle.fill"
        }
    }

    static func evaluate(value: Double, low: Double, high: Double, limit: Double?) -> DosageStatus {
        if value < low { return .below }
        if value > high {
            if let limit, value > limit { return .exceedsLimit }
            return .above
        }
        return .inRange
    }
}

// MARK: - Dosage Range Editor

struct DosageRangeEditor: View {
    let low: Double
    let high: Double
    let limit: Double?
    let recommended: Double
    let unit: String
    let step: Double
    @Binding var value: Double
    var onCommit: (Double) -> Void = { _ in }

    @State private var dragValue: Double?
    @State private var lastZone: DosageStatus = .inRange

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    private var displayValue: Double { dragValue ?? value }

    private var status: DosageStatus {
        DosageStatus.evaluate(value: displayValue, low: low, high: high, limit: limit)
    }

    private var minBound: Double { 0 }

    private var maxBound: Double {
        if let limit { return limit }
        return high * 1.5
    }

    private var canDecrement: Bool { value - step > minBound - 0.0001 }
    private var canIncrement: Bool { value + step < maxBound + 0.0001 }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing8) {
            Image(systemName: "scalemass")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 18, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                headerRow
                barRow
                    .padding(.top, DesignTokens.spacing8)
                rangeLabels
                if isOverridden {
                    resetButton
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .onAppear { lastZone = status }
        .animation(.easeInOut(duration: 0.2), value: status)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(spacing: DesignTokens.spacing8) {
            Text("Dosage")
                .font(.custom("Geist-Regular", size: 16))
                .foregroundStyle(DesignTokens.textPrimary)
            Spacer(minLength: DesignTokens.spacing4)
            HStack(spacing: 2) {
                Text(format(displayValue))
                    .font(.custom("GeistMono-Medium", size: 16))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: displayValue)
                Text(unit)
                    .font(.custom("Geist-Regular", size: 12))
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.leading, 2)
            }
            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 10))
            Text(status.label)
                .font(DesignTokens.labelMono)
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Bar Row (inline +/-)

    private var barRow: some View {
        HStack(spacing: DesignTokens.spacing8) {
            stepperButton(icon: "minus", enabled: canDecrement) {
                guard canDecrement else { return }
                let next = clamp(snap(value - step))
                commit(next, withZoneHaptic: true)
            }
            rangeBar
            stepperButton(icon: "plus", enabled: canIncrement) {
                guard canIncrement else { return }
                let next = clamp(snap(value + step))
                commit(next, withZoneHaptic: true)
            }
        }
    }

    private func stepperButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(enabled ? DesignTokens.textPrimary : DesignTokens.textTertiary)
                .frame(width: 28, height: 28)
                .background(DesignTokens.bgElevated)
                .clipShape(Circle())
                .overlay(Circle().stroke(DesignTokens.borderDefault, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Range Bar

    private var rangeBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let trackHeight: CGFloat = 8
            let thumbSize: CGFloat = 22
            let centerY = geo.size.height / 2

            ZStack {
                Capsule()
                    .fill(DesignTokens.borderDefault)
                    .frame(width: width, height: trackHeight)
                    .position(x: width / 2, y: centerY)

                zoneBar(from: minBound, to: low,
                        color: DesignTokens.info, alpha: 0.12,
                        width: width, h: trackHeight, y: centerY)

                zoneBar(from: low, to: high,
                        color: DesignTokens.positive, alpha: 0.28,
                        width: width, h: trackHeight, y: centerY)

                if let limit, limit > high {
                    zoneBar(from: high, to: limit,
                            color: DesignTokens.accentEnergyDark, alpha: 0.20,
                            width: width, h: trackHeight, y: centerY)
                }

                tickMark(at: low, width: width, y: centerY)
                tickMark(at: high, width: width, y: centerY)

                if abs(recommended - low) > 0.001, abs(recommended - high) > 0.001 {
                    Circle()
                        .fill(DesignTokens.bgSurface)
                        .overlay(Circle().stroke(DesignTokens.textSecondary, lineWidth: 1.5))
                        .frame(width: 8, height: 8)
                        .position(x: ratio(recommended) * width, y: centerY)
                }

                Circle()
                    .fill(status.color)
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: status.color.opacity(0.35), radius: 5, x: 0, y: 2)
                    .position(x: ratio(displayValue) * width, y: centerY)
                    .animation(reduceMotion ? nil : .interactiveSpring(response: 0.18, dampingFraction: 0.85), value: displayValue)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        guard width > 0 else { return }
                        let frac = max(0, min(1, drag.location.x / width))
                        let raw = minBound + Double(frac) * (maxBound - minBound)
                        let snapped = clamp(snap(raw))
                        let detented: Double = (abs(snapped - recommended) < step) ? recommended : snapped
                        let zone = DosageStatus.evaluate(value: detented, low: low, high: high, limit: limit)
                        if zone != lastZone {
                            HapticManager.impact(.light)
                            lastZone = zone
                        }
                        dragValue = detented
                    }
                    .onEnded { _ in
                        if let final = dragValue {
                            if abs(final - value) > 0.0001 {
                                HapticManager.impact(.light)
                            }
                            value = final
                            onCommit(final)
                        }
                        dragValue = nil
                    }
            )
        }
        .frame(height: 26)
    }

    private func zoneBar(from a: Double, to b: Double, color: Color, alpha: Double,
                         width: CGFloat, h: CGFloat, y: CGFloat) -> some View {
        let aF = ratio(a)
        let bF = ratio(b)
        let w = max(0, (bF - aF) * width)
        let cx = (aF + bF) / 2 * width
        return Rectangle()
            .fill(color.opacity(alpha))
            .frame(width: w, height: h)
            .position(x: cx, y: y)
    }

    private func tickMark(at v: Double, width: CGFloat, y: CGFloat) -> some View {
        Rectangle()
            .fill(DesignTokens.textPrimary.opacity(0.4))
            .frame(width: 1.5, height: 14)
            .position(x: ratio(v) * width, y: y)
    }

    // MARK: - Range Labels

    private var rangeLabels: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                positionedLabel(text: "\(format(low)) \(unit)", at: low, width: geo.size.width)
                positionedLabel(text: "\(format(high)) \(unit)", at: high, width: geo.size.width)
                if let limit, abs(limit - high) > step {
                    positionedLabel(text: "\(format(limit)) \(unit) limit", at: limit, width: geo.size.width)
                }
            }
        }
        .frame(height: 14)
    }

    private func positionedLabel(text: String, at v: Double, width: CGFloat) -> some View {
        Text(text)
            .font(DesignTokens.smallMono)
            .foregroundStyle(DesignTokens.textTertiary)
            .fixedSize()
            .position(x: clampedLabelX(at: v, width: width), y: 7)
    }

    /// Keep labels from clipping at the edges by nudging them in.
    private func clampedLabelX(at v: Double, width: CGFloat) -> CGFloat {
        let raw = ratio(v) * width
        return max(24, min(width - 24, raw))
    }

    // MARK: - Reset Button

    private var isOverridden: Bool { abs(value - recommended) > 0.001 }

    private var resetButton: some View {
        Button {
            HapticManager.impact(.light)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.75)) {
                value = recommended
            }
            onCommit(recommended)
            lastZone = DosageStatus.evaluate(value: recommended, low: low, high: high, limit: limit)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 11))
                Text("Reset to \(format(recommended)) \(unit) recommendation")
                    .font(DesignTokens.smallMono)
            }
            .foregroundStyle(DesignTokens.textSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func commit(_ next: Double, withZoneHaptic: Bool) {
        let zone = DosageStatus.evaluate(value: next, low: low, high: high, limit: limit)
        if withZoneHaptic, zone != lastZone {
            HapticManager.impact(.light)
        }
        lastZone = zone
        value = next
        onCommit(next)
    }

    private func snap(_ v: Double) -> Double {
        guard step > 0 else { return v }
        return (v / step).rounded() * step
    }

    private func clamp(_ v: Double) -> Double {
        max(minBound, min(maxBound, v))
    }

    private func format(_ v: Double) -> String {
        if v >= 10 || v == v.rounded() {
            return String(Int(v.rounded()))
        }
        return String(format: "%.1f", v)
    }

    private func ratio(_ v: Double) -> CGFloat {
        let span = maxBound - minBound
        guard span > 0 else { return 0 }
        let bounded = max(minBound, min(maxBound, v))
        return CGFloat((bounded - minBound) / span)
    }
}

// MARK: - Helpers

extension Double {
    /// Picks a sensible step size given the recommended low/high so the user
    /// gets ~20 ticks across the recommended zone, snapped to a "nice" number.
    static func niceStep(low: Double, high: Double) -> Double {
        let span = max(high - low, 1)
        let target = span / 20
        let nice: [Double] = [0.5, 1, 2, 5, 10, 25, 50, 100, 250, 500, 1000]
        return nice.first(where: { $0 >= target }) ?? 1000
    }
}

extension String {
    /// Extract the unit suffix from a dosage string ("400mg" → "mg", "5000 IU" → "IU").
    /// Falls back to "mg" when no letter suffix is present.
    var dosageUnit: String {
        let stripped = trimmingCharacters(in: .whitespaces)
        var unit = ""
        for scalar in stripped.unicodeScalars.reversed() {
            if CharacterSet.letters.contains(scalar) {
                unit = String(scalar) + unit
            } else if !unit.isEmpty {
                break
            }
        }
        return unit.isEmpty ? "mg" : unit
    }
}

// MARK: - Preview

#Preview("In range") {
    StatefulPreview(initial: 300) { binding in
        DosageRangeEditor(
            low: 200, high: 400, limit: 400, recommended: 400,
            unit: "mg", step: 10, value: binding
        )
        .padding()
        .background(DesignTokens.bgSurface)
    }
}

#Preview("Below range") {
    StatefulPreview(initial: 100) { binding in
        DosageRangeEditor(
            low: 200, high: 400, limit: 400, recommended: 400,
            unit: "mg", step: 10, value: binding
        )
        .padding()
        .background(DesignTokens.bgSurface)
    }
}

#Preview("Above with limit") {
    StatefulPreview(initial: 6000) { binding in
        DosageRangeEditor(
            low: 1000, high: 5000, limit: 10000, recommended: 2000,
            unit: "IU", step: 250, value: binding
        )
        .padding()
        .background(DesignTokens.bgSurface)
    }
}

private struct StatefulPreview<Content: View>: View {
    @State var value: Double
    let content: (Binding<Double>) -> Content

    init(initial: Double, @ViewBuilder content: @escaping (Binding<Double>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
