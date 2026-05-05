import SwiftUI

struct OrbBackground: View {
    enum Style {
        /// Independent drops that wander, merge, and split — lava lamp feel.
        case multiDrops
        /// One unified blob whose silhouette morphs as it roams the card.
        case singleMorph
    }

    var style: Style = .multiDrops

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSince(startDate)

            ZStack {
                Color(hex: "#0D0D0D")
                MorphingBlob(time: t, style: style)
            }
        }
    }
}

// MARK: - Morphing Blob

private struct MorphingBlob: View {
    let time: TimeInterval
    let style: OrbBackground.Style

    private let innerColor = Color(hex: "#FAC655")
    private let outerColor = Color(hex: "#96953F")

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let metrics = BlobMetrics(size: size, time: time)
            let blobs: [BlobMetrics.Blob] = {
                switch style {
                case .multiDrops:  return metrics.multiDropBlobs
                case .singleMorph: return metrics.singleMorphBlobs
                }
            }()

            // Metaball silhouette — fuses blobs into one morphing goo
            // when they're near each other, splits into separate drops
            // when they drift apart.
            let silhouette = Canvas { context, _ in
                context.addFilter(.alphaThreshold(min: 0.40, color: .white))
                context.addFilter(.blur(radius: 40))
                context.drawLayer { ctx in
                    for b in blobs {
                        let rect = CGRect(
                            x: b.x - b.r,
                            y: b.y - b.r,
                            width: b.r * 2,
                            height: b.r * 2
                        )
                        ctx.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
            }
            .blur(radius: 18) // diffuse edge

            Group {
                switch style {
                case .multiDrops:
                    multiDropFill(blobs: blobs, silhouette: silhouette)
                case .singleMorph:
                    singleMorphFill(blobs: blobs, silhouette: silhouette, size: size)
                }
            }
            .hueRotation(.degrees(metrics.hueDegrees))
            .compositingGroup()
            .drawingGroup()
        }
    }

    // MARK: - Multi-drop fill

    /// Per-blob halos (plusLighter) + per-blob body gradients (masked by
    /// silhouette). Overlapping halos brighten where drops meet, which
    /// reads as "merging goo" across separated drops.
    @ViewBuilder
    private func multiDropFill(blobs: [BlobMetrics.Blob], silhouette: some View) -> some View {
        ZStack {
            // Halos
            ZStack {
                ForEach(Array(blobs.enumerated()), id: \.offset) { _, b in
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: innerColor.opacity(0.55), location: 0.00),
                            .init(color: outerColor.opacity(0.28), location: 0.45),
                            .init(color: .clear, location: 1.00)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: b.r * 1.7
                    )
                    .frame(width: b.r * 3.4, height: b.r * 3.4)
                    .position(x: b.x, y: b.y)
                    .blur(radius: 26)
                    .blendMode(.plusLighter)
                }
            }

            // Body
            ZStack {
                ForEach(Array(blobs.enumerated()), id: \.offset) { _, b in
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: innerColor, location: 0.0),
                            .init(color: innerColor.opacity(0.85), location: 0.35),
                            .init(color: outerColor, location: 0.85),
                            .init(color: outerColor.opacity(0.75), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: b.r
                    )
                    .frame(width: b.r * 2, height: b.r * 2)
                    .position(x: b.x, y: b.y)
                }
            }
            .mask { silhouette }
            .blur(radius: 22)
        }
    }

    // MARK: - Single-morph fill

    /// Two layers, designed so the boundary between them is invisible:
    /// the body (confined to the silhouette) fades to fully transparent
    /// at its outer edge, where the ambient halo takes over. At the
    /// silhouette boundary, only the halo is contributing — the same
    /// value inside and just outside — so there's no visible ring, no
    /// "inner orb vs outer orb" read. Both layers are anchored on the
    /// dominant static blob (blobs[0]) rather than a weighted centroid
    /// — sub-blob orbits can't pull the hotspot off the silhouette's
    /// visual center, so the inner core stays locked inside the halo
    /// regardless of how the sub-blobs jostle around it.
    @ViewBuilder
    private func singleMorphFill(blobs: [BlobMetrics.Blob], silhouette: some View, size: CGSize) -> some View {
        let anchor = blobs.first.map { CGPoint(x: $0.x, y: $0.y) } ?? .zero
        let extent = averageRadius(of: blobs)
        let unit = UnitPoint(
            x: anchor.x / max(size.width, 1),
            y: anchor.y / max(size.height, 1)
        )

        ZStack {
            // Ambient halo — fills from center out past the silhouette,
            // fading smoothly to clear. Provides continuous color across
            // the silhouette boundary.
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: innerColor.opacity(0.35), location: 0.00),
                    .init(color: outerColor.opacity(0.22), location: 0.45),
                    .init(color: outerColor.opacity(0.07), location: 0.80),
                    .init(color: .clear, location: 1.00)
                ]),
                center: unit,
                startRadius: 0,
                endRadius: extent * 2.4
            )

            // Body layer — brighter than the halo, but its outer stop is
            // fully transparent. At the silhouette boundary the body
            // contributes zero, so the transition into the halo is
            // continuous (no opacity jump, no visible ring).
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: innerColor.opacity(0.55), location: 0.00),
                    .init(color: innerColor.opacity(0.40), location: 0.40),
                    .init(color: outerColor.opacity(0.25), location: 0.75),
                    .init(color: outerColor.opacity(0.00), location: 1.00)
                ]),
                center: unit,
                startRadius: 0,
                endRadius: extent * 1.35
            )
            .mask { silhouette }
            .blur(radius: 22)
        }
    }

    private func weightedCentroid(of blobs: [BlobMetrics.Blob]) -> CGPoint {
        let totalWeight = blobs.reduce(0) { $0 + $1.r }
        guard totalWeight > 0 else { return .zero }
        let x = blobs.reduce(0) { $0 + $1.x * $1.r } / totalWeight
        let y = blobs.reduce(0) { $0 + $1.y * $1.r } / totalWeight
        return CGPoint(x: x, y: y)
    }

    private func averageRadius(of blobs: [BlobMetrics.Blob]) -> CGFloat {
        guard !blobs.isEmpty else { return 1 }
        return blobs.reduce(0) { $0 + $1.r } / CGFloat(blobs.count)
    }
}

// MARK: - Blob Metrics

private struct BlobMetrics {
    let size: CGSize
    let time: TimeInterval

    var baseRadius: CGFloat {
        min(size.width, size.height) * 0.34
    }

    /// Slow, continuous hue cycle. 36s per full rotation.
    var hueDegrees: Double { (time / 36.0) * 360.0 }

    /// Four independent drops. Each has its own wandering home point
    /// (amplitude scaled to card width/height so drops can reach —
    /// and partially exit — any edge), its own small orbit around
    /// that home, and its own radius pulse.
    var multiDropBlobs: [Blob] {
        let cx = size.width / 2
        let cy = size.height / 2
        let R = baseRadius
        let t = time * 0.30
        let slow = time * 0.14

        return multiSpecs.map { s in
            let hx = cx + CGFloat(cos(slow * s.homeFx + s.homePx)) * size.width * s.homeAx
            let hy = cy + CGFloat(sin(slow * s.homeFy + s.homePy)) * size.height * s.homeAy
            let ox = CGFloat(cos(t * s.orbitFx + s.orbitPx)) * R * s.orbitAx
            let oy = CGFloat(sin(t * s.orbitFy + s.orbitPy)) * R * s.orbitAy
            let r  = R * s.rScale * (s.rBase + CGFloat(sin(t * s.rFreq + s.rPhase)) * s.rSwing)
            return Blob(x: hx + ox, y: hy + oy, r: r)
        }
    }

    /// Five sub-blobs sharing one wandering home — orbits are tight so
    /// the silhouette always metaball-fuses into a single body that
    /// morphs as the home travels across the card.
    var singleMorphBlobs: [Blob] {
        let cx = size.width / 2
        let cy = size.height / 2
        // Bigger overall presence than the shared baseRadius — blob 0
        // dominates the silhouette, so scaling R here scales the whole
        // visible orb without affecting multi-drop mode.
        let R = baseRadius * 1.25
        let t = time * 0.42
        let slow = time * 0.26

        // Shared home — quasi-periodic path (two harmonics per axis)
        // scaled to card width/height so the whole blob can travel
        // anywhere and partially exit.
        let hxOffset = CGFloat(cos(slow * 0.70 + 0.3)) * 0.58
                     + CGFloat(cos(slow * 1.37 + 1.9)) * 0.32
        let hyOffset = CGFloat(sin(slow * 0.53 + 1.7)) * 0.58
                     + CGFloat(sin(slow * 1.29 + 3.4)) * 0.32
        let hx = cx + hxOffset * size.width * 0.52
        let hy = cy + hyOffset * size.height * 0.44

        return singleSpecs.map { s in
            let ox = CGFloat(cos(t * s.orbitFx + s.orbitPx)) * R * s.orbitAx
            let oy = CGFloat(sin(t * s.orbitFy + s.orbitPy)) * R * s.orbitAy
            let r  = R * s.rScale * (s.rBase + CGFloat(sin(t * s.rFreq + s.rPhase)) * s.rSwing)
            return Blob(x: hx + ox, y: hy + oy, r: r)
        }
    }

    // Tight-orbit specs for single-morph mode. Only orbit + radius
    // fields are used; home amplitudes are ignored (shared home above).
    private let singleSpecs: [Spec] = [
        Spec(homeAx: 0, homeAy: 0, homeFx: 0, homeFy: 0, homePx: 0, homePy: 0,
             orbitAx: 0.00, orbitAy: 0.00, orbitFx: 0.00, orbitFy: 0.00,
             orbitPx: 0.0, orbitPy: 0.0,
             rScale: 1.20, rBase: 1.00, rSwing: 0.08, rFreq: 1.30, rPhase: 0.0),

        Spec(homeAx: 0, homeAy: 0, homeFx: 0, homeFy: 0, homePx: 0, homePy: 0,
             orbitAx: 0.20, orbitAy: 0.22, orbitFx: 0.70, orbitFy: 0.93,
             orbitPx: 0.0, orbitPy: 0.0,
             rScale: 0.90, rBase: 0.95, rSwing: 0.08, rFreq: 1.00, rPhase: 0.4),

        Spec(homeAx: 0, homeAy: 0, homeFx: 0, homeFy: 0, homePx: 0, homePy: 0,
             orbitAx: 0.22, orbitAy: 0.19, orbitFx: 1.10, orbitFy: 0.62,
             orbitPx: 1.5, orbitPy: 2.1,
             rScale: 0.82, rBase: 0.95, rSwing: 0.09, rFreq: 0.74, rPhase: 1.1),

        Spec(homeAx: 0, homeAy: 0, homeFx: 0, homeFy: 0, homePx: 0, homePy: 0,
             orbitAx: 0.17, orbitAy: 0.20, orbitFx: 0.82, orbitFy: 1.21,
             orbitPx: 3.2, orbitPy: 0.7,
             rScale: 0.76, rBase: 0.95, rSwing: 0.10, rFreq: 1.15, rPhase: 2.2),

        Spec(homeAx: 0, homeAy: 0, homeFx: 0, homeFy: 0, homePx: 0, homePy: 0,
             orbitAx: 0.19, orbitAy: 0.17, orbitFx: 1.42, orbitFy: 0.87,
             orbitPx: 4.0, orbitPy: 2.5,
             rScale: 0.70, rBase: 0.95, rSwing: 0.10, rFreq: 1.42, rPhase: 3.0)
    ]

    private let multiSpecs: [Spec] = [
        // Radius = rScale * (rBase ± rSwing) * R. Keep rScale*(rBase-rSwing)
        // comfortably above the silhouette's alphaThreshold cutoff
        // (roughly 0.40 with blur(40)) so blobs never vanish.

        // Big slow drop.
        Spec(homeAx: 0.36, homeAy: 0.34, homeFx: 0.72, homeFy: 0.53,
             homePx: 0.3, homePy: 1.7,
             orbitAx: 0.18, orbitAy: 0.20, orbitFx: 0.70, orbitFy: 0.93,
             orbitPx: 0.0, orbitPy: 0.0,
             rScale: 1.35, rBase: 1.00, rSwing: 0.10, rFreq: 1.30, rPhase: 0.0),

        // Medium drop.
        Spec(homeAx: 0.40, homeAy: 0.36, homeFx: 0.91, homeFy: 0.67,
             homePx: 2.1, homePy: 4.3,
             orbitAx: 0.22, orbitAy: 0.19, orbitFx: 1.10, orbitFy: 0.62,
             orbitPx: 1.5, orbitPy: 2.1,
             rScale: 1.00, rBase: 0.95, rSwing: 0.10, rFreq: 1.00, rPhase: 0.4),

        // Small roaming drop.
        Spec(homeAx: 0.30, homeAy: 0.42, homeFx: 1.13, homeFy: 0.81,
             homePx: 3.7, homePy: 0.5,
             orbitAx: 0.17, orbitAy: 0.18, orbitFx: 0.82, orbitFy: 1.21,
             orbitPx: 3.2, orbitPy: 0.7,
             rScale: 0.75, rBase: 0.95, rSwing: 0.10, rFreq: 0.74, rPhase: 1.1),

        // Small fast droplet.
        Spec(homeAx: 0.42, homeAy: 0.30, homeFx: 0.59, homeFy: 0.95,
             homePx: 5.0, homePy: 2.9,
             orbitAx: 0.20, orbitAy: 0.16, orbitFx: 1.42, orbitFy: 0.87,
             orbitPx: 4.0, orbitPy: 2.5,
             rScale: 0.62, rBase: 0.95, rSwing: 0.10, rFreq: 1.42, rPhase: 2.0)
    ]

    // MARK: Types

    struct Blob {
        let x: CGFloat
        let y: CGFloat
        let r: CGFloat
    }

    private struct Spec {
        // Home point wander — amplitude as fraction of card width/height.
        let homeAx: CGFloat
        let homeAy: CGFloat
        let homeFx: Double
        let homeFy: Double
        let homePx: Double
        let homePy: Double
        // Small orbit around home.
        let orbitAx: CGFloat
        let orbitAy: CGFloat
        let orbitFx: Double
        let orbitFy: Double
        let orbitPx: Double
        let orbitPy: Double
        // Radius: base * (rBase ± rSwing) pulse.
        let rScale: CGFloat
        let rBase: CGFloat
        let rSwing: CGFloat
        let rFreq: Double
        let rPhase: Double
    }
}
