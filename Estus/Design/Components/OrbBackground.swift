import SwiftUI

struct OrbBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSince(startDate)

            ZStack {
                Color(hex: "#0D0D0D")
                MorphingBlob(time: t)
            }
        }
    }
}

// MARK: - Morphing Blob

private struct MorphingBlob: View {
    let time: TimeInterval

    private let innerColor = Color(hex: "#FAC655")
    private let outerColor = Color(hex: "#96953F")

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let metrics = BlobMetrics(size: size, time: time)
            let blobs = metrics.blobs

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

            // Per-blob body gradients — each blob has its own bright
            // hotspot at its own center, so the nucleus always stays
            // inside the drop. Masked by the fused silhouette.
            let body = ZStack {
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

            // Per-blob halos — each drop radiates its own soft glow.
            // plusLighter means overlapping halos brighten when drops
            // meet, reinforcing the "merging goo" read.
            let halos = ZStack {
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

            ZStack {
                halos
                body
            }
            .hueRotation(.degrees(metrics.hueDegrees))
            .compositingGroup()
            .drawingGroup()
        }
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
    var blobs: [Blob] {
        let cx = size.width / 2
        let cy = size.height / 2
        let R = baseRadius
        let t = time * 0.30
        let slow = time * 0.14

        return specs.map { s in
            let hx = cx + CGFloat(cos(slow * s.homeFx + s.homePx)) * size.width * s.homeAx
            let hy = cy + CGFloat(sin(slow * s.homeFy + s.homePy)) * size.height * s.homeAy
            let ox = CGFloat(cos(t * s.orbitFx + s.orbitPx)) * R * s.orbitAx
            let oy = CGFloat(sin(t * s.orbitFy + s.orbitPy)) * R * s.orbitAy
            let r  = R * s.rScale * (s.rBase + CGFloat(sin(t * s.rFreq + s.rPhase)) * s.rSwing)
            return Blob(x: hx + ox, y: hy + oy, r: r)
        }
    }

    private let specs: [Spec] = [
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
