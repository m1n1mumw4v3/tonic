import SwiftUI

/// The Estus lockup with a one-shot "Gather to Lockup" intro:
/// four colored orbs fly in and goo together into the mark (shown large at
/// the logo's center), the mark breathes in full color, then half-turns and
/// shrinks into its superscript spot while the letters sweep in.
///
/// Plays once on first appear (~3.3 s). Under Reduce Motion it renders the
/// final frame immediately. The final frame matches `estus-logo-01.svg`.
struct AnimatedLogoLockup: View {
    /// When true the final lockup keeps the colored mark instead of ink.
    var keepColor: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate: Date?
    @State private var isFinished = false

    var body: some View {
        Color.clear
            .aspectRatio(EstusLogoGeometry.aspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    TimelineView(.animation(paused: isFinished || reduceMotion)) { timeline in
                        LockupFrame(
                            time: elapsed(at: timeline.date),
                            k: geo.size.width / EstusLogoGeometry.viewBox.width,
                            keepColor: keepColor
                        )
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Estus")
            .task {
                guard startDate == nil, !reduceMotion else { return }
                startDate = .now

                // Haptic as the mark lands in its superscript spot.
                try? await Task.sleep(for: .seconds(LogoTimeline.markLands))
                guard !Task.isCancelled else { return }
                HapticManager.impact(.light)

                try? await Task.sleep(for: .seconds(LogoTimeline.duration - LogoTimeline.markLands))
                guard !Task.isCancelled else { return }
                isFinished = true
            }
    }

    private func elapsed(at date: Date) -> Double {
        if reduceMotion || isFinished { return .infinity }
        guard let startDate else { return 0 }
        return date.timeIntervalSince(startDate)
    }
}

// MARK: - Frame

/// One frame of the lockup at time `time` (seconds since start).
/// `k` is points per SVG unit for the 6160×1280 logo frame.
private struct LockupFrame: View {
    let time: Double
    let k: CGFloat
    let keepColor: Bool

    private static let glyphs: [AnyShape] = [
        AnyShape(EstusLogoE()), AnyShape(EstusLogoS1()), AnyShape(EstusLogoT()),
        AnyShape(EstusLogoU()), AnyShape(EstusLogoS2()),
    ]

    var body: some View {
        let box = EstusLogoGeometry.viewBox
        let mark = EstusLogoGeometry.markCenter
        let gather = LogoTimeline.gatherCenter
        let travel = LogoTimeline.markTravel(time)
        // The mark group is laid out at its largest scale and only ever scaled
        // down (except the small breath), so the shapes stay crisp.
        let u = k * LogoTimeline.peakScale
        let side = MarkGroup.localSize * u

        ZStack(alignment: .topLeading) {
            ForEach(Self.glyphs.indices, id: \.self) { i in
                let p = LogoTimeline.letterProgress(index: i, time: time)
                Self.glyphs[i]
                    .fill(DesignTokens.logoInk)
                    .opacity(p)
                    .offset(x: -260 * k * (1 - p))
            }

            MarkGroup(time: time, u: u, keepColor: keepColor)
                .frame(width: side, height: side)
                .scaleEffect(LogoTimeline.markScale(time) / LogoTimeline.peakScale)
                .rotationEffect(.degrees(180 * travel))
                .position(x: mark.x * k, y: mark.y * k)
                // Starts with the mark at the gather point above the logo.
                .offset(
                    x: (gather.x - mark.x) * k * (1 - travel),
                    y: (gather.y - mark.y) * k * (1 - travel)
                )
        }
        .frame(width: box.width * k, height: box.height * k, alignment: .topLeading)
    }
}

// MARK: - Mark Group

/// Goo lobes, color mark, and ink mark, in a square local space centered on
/// the mark center (5760, 400). `u` is points per SVG unit.
private struct MarkGroup: View {
    let time: Double
    let u: CGFloat
    let keepColor: Bool

    /// Local canvas size in SVG units — roomy enough for the lobes' start
    /// positions plus their blur.
    static let localSize: CGFloat = 2800

    private struct Lobe {
        let center: CGPoint   // relative to mark center
        let radius: CGFloat
        let color: Color
        let start: CGPoint    // start offset from `center`
        let hold: Double      // seconds before it starts flying
    }

    private static let lobes: [Lobe] = [
        Lobe(center: CGPoint(x: -200, y: -200), radius: 200, color: DesignTokens.accentMood,
             start: CGPoint(x: -650, y: -600), hold: 0.08),
        Lobe(center: CGPoint(x: 240, y: -240), radius: 160, color: DesignTokens.accentGut,
             start: CGPoint(x: 620, y: -640), hold: 0.20),
        Lobe(center: CGPoint(x: -240, y: 240), radius: 160, color: DesignTokens.accentLongevity,
             start: CGPoint(x: -600, y: 360), hold: 0.24),
        Lobe(center: CGPoint(x: 200, y: 200), radius: 200, color: DesignTokens.accentEnergy,
             start: CGPoint(x: 640, y: 380), hold: 0.12),
    ]

    /// Soft color fields blended under the mark, like the app icon.
    private static let colorFields: [(center: CGPoint, radius: CGFloat, color: Color)] = [
        (CGPoint(x: -200, y: -200), 260, DesignTokens.accentMood),
        (CGPoint(x: 240, y: -240), 200, DesignTokens.accentGut),
        (CGPoint(x: -240, y: 240), 200, DesignTokens.accentLongevity),
        (CGPoint(x: 200, y: 200), 260, DesignTokens.accentEnergy),
    ]

    var body: some View {
        let goo = LogoTimeline.gooOpacity(time)
        let color = LogoTimeline.colorOpacity(time, keepColor: keepColor)
        let ink = LogoTimeline.inkOpacity(time, keepColor: keepColor)

        ZStack {
            if goo > 0 {
                gooLayer.opacity(goo)
            }
            if color > 0 {
                colorMark.opacity(color)
            }
            if ink > 0 {
                CenteredMark(unit: u)
                    .fill(DesignTokens.logoInk)
                    .opacity(ink)
            }
        }
    }

    /// Lobe circles in local points at the current time.
    private func lobeCircles(radiusScale: CGFloat, in size: CGSize) -> [(Path, Color)] {
        let origin = CGPoint(x: size.width / 2, y: size.height / 2)
        return Self.lobes.map { lobe in
            let p = LogoTimeline.lobeProgress(hold: lobe.hold, time: time)
            let x = lobe.center.x + lobe.start.x * (1 - p)
            let y = lobe.center.y + lobe.start.y * (1 - p)
            let r = lobe.radius * (0.4 + 0.6 * p) * radiusScale
            let rect = CGRect(
                x: origin.x + (x - r) * u,
                y: origin.y + (y - r) * u,
                width: 2 * r * u,
                height: 2 * r * u
            )
            return (Path(ellipseIn: rect), lobe.color)
        }
    }

    /// Metaball goo: colored lobes clipped to a thresholded-blur silhouette,
    /// so they fuse only once they're nearly in place.
    private var gooLayer: some View {
        Canvas { context, size in
            context.addFilter(.blur(radius: 30 * u))
            for (path, color) in lobeCircles(radiusScale: 1.35, in: size) {
                context.fill(path, with: .color(color))
            }
        }
        .mask {
            Canvas { context, size in
                context.addFilter(.alphaThreshold(min: 0.40, color: .white))
                context.addFilter(.blur(radius: 70 * u))
                context.drawLayer { layer in
                    for (path, _) in lobeCircles(radiusScale: 1, in: size) {
                        layer.fill(path, with: .color(.white))
                    }
                }
            }
        }
    }

    /// The real mark outline filled with the four accents blended softly.
    private var colorMark: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(DesignTokens.accentLongevity))
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 90 * u))
                for field in Self.colorFields {
                    let r = field.radius
                    let rect = CGRect(
                        x: origin.x + (field.center.x - r) * u,
                        y: origin.y + (field.center.y - r) * u,
                        width: 2 * r * u,
                        height: 2 * r * u
                    )
                    layer.fill(Path(ellipseIn: rect), with: .color(field.color))
                }
            }
        }
        .mask(CenteredMark(unit: u))
    }
}

/// `EstusMark` with its center (5760, 400) placed at the rect's center,
/// at `unit` points per SVG unit.
private struct CenteredMark: Shape {
    let unit: CGFloat

    func path(in rect: CGRect) -> Path {
        let c = EstusLogoGeometry.markCenter
        return EstusLogoGeometry.mark.applying(CGAffineTransform(
            a: unit, b: 0, c: 0, d: unit,
            tx: rect.midX - c.x * unit,
            ty: rect.midY - c.y * unit
        ))
    }
}

// MARK: - Timeline

/// Keyframe tracks for the intro, in seconds from appear.
private enum LogoTimeline {
    static let peakScale: CGFloat = 2.6
    /// Where the mark assembles, in logo SVG units: horizontally centered,
    /// raised so the 2.6–2.8× mark and the lower lobes' start points stay
    /// clear of whatever sits below the logo (the welcome card).
    static let gatherCenter = CGPoint(x: 3080, y: -200)
    static let markLands: Double = 2.88
    /// Last letter settles at 2.24 + 4 × 0.06 + 0.8.
    static let duration: Double = 3.3

    private static let inOut = CubicBezier(0.65, 0, 0.35, 1)
    private static let lobeEase = CubicBezier(0.3, 0.7, 0.2, 1)
    private static let fadeEase = CubicBezier(0.42, 0, 0.58, 1)
    private static let letterEase = CubicBezier(0.16, 1, 0.3, 1)

    static func markScale(_ t: Double) -> CGFloat {
        CGFloat(track(t, [(1.44, 2.6), (1.68, 2.8), (1.92, 2.6), (2.88, 1.0)], inOut))
    }

    /// 0 = mark centered on the logo, upright; 1 = in its spot, turned 180°.
    static func markTravel(_ t: Double) -> CGFloat {
        CGFloat(track(t, [(1.92, 0), (2.88, 1)], inOut))
    }

    static func lobeProgress(hold: Double, time t: Double) -> CGFloat {
        CGFloat(track(t, [(hold, 0), (1.12, 1)], lobeEase))
    }

    static func gooOpacity(_ t: Double) -> Double {
        track(t, [(0, 0), (0.24, 1), (1.12, 1), (1.44, 0)], fadeEase)
    }

    static func colorOpacity(_ t: Double, keepColor: Bool) -> Double {
        keepColor
            ? track(t, [(1.04, 0), (1.36, 1)], fadeEase)
            : track(t, [(1.04, 0), (1.36, 1), (2.08, 1), (2.64, 0)], fadeEase)
    }

    static func inkOpacity(_ t: Double, keepColor: Bool) -> Double {
        keepColor ? 0 : track(t, [(2.08, 0), (2.64, 1)], fadeEase)
    }

    static func letterProgress(index: Int, time t: Double) -> CGFloat {
        let start = 2.24 + 0.06 * Double(index)
        return CGFloat(track(t, [(start, 0), (start + 0.8, 1)], letterEase))
    }

    /// Piecewise keyframe interpolation, eased per segment. Holds the first
    /// value before the first key and the last value after the last key.
    private static func track(_ t: Double, _ keys: [(time: Double, value: Double)], _ ease: CubicBezier) -> Double {
        guard let first = keys.first, t > first.time else { return keys.first?.value ?? 0 }
        for (a, b) in zip(keys, keys.dropFirst()) where t < b.time {
            let p = (t - a.time) / (b.time - a.time)
            return a.value + (b.value - a.value) * ease(p)
        }
        return keys.last?.value ?? 0
    }
}

/// CSS-style `cubic-bezier(x1, y1, x2, y2)` timing curve.
private struct CubicBezier {
    let x1, y1, x2, y2: Double

    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        self.x1 = x1; self.y1 = y1; self.x2 = x2; self.y2 = y2
    }

    func callAsFunction(_ x: Double) -> Double {
        guard x > 0 else { return 0 }
        guard x < 1 else { return 1 }
        // Bisect for the curve parameter whose x matches, then return its y.
        var lo = 0.0, hi = 1.0, s = x
        for _ in 0..<24 {
            s = (lo + hi) / 2
            if Self.bezier(s, x1, x2) < x { lo = s } else { hi = s }
        }
        return Self.bezier(s, y1, y2)
    }

    private static func bezier(_ s: Double, _ p1: Double, _ p2: Double) -> Double {
        let inv = 1 - s
        return 3 * inv * inv * s * p1 + 3 * inv * s * s * p2 + s * s * s
    }
}

#Preview {
    AnimatedLogoLockup()
        .padding(.horizontal, 28)
        .frame(maxHeight: .infinity)
        .background(DesignTokens.bgDeepest)
}
