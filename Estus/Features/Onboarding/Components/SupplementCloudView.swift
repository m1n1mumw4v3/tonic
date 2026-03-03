import SwiftUI

struct SupplementCloudView: View {
    var animated: Bool = true

    @State private var opacity: CGFloat = 0
    @State private var startDate: Date = .now

    private static let accentColors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentMood,
        DesignTokens.accentGut,
        DesignTokens.accentLongevity
    ]

    private static let supplements = [
        "Vitamin D3", "Magnesium", "Ashwagandha", "Fish Oil", "B12",
        "Zinc", "Iron", "Probiotics", "Turmeric", "CoQ10",
        "Vitamin C", "Melatonin", "Collagen", "Biotin", "Folate",
        "Creatine", "L-Theanine", "Rhodiola", "Elderberry", "Spirulina",
        "Selenium", "Calcium", "NAC", "Lions Mane", "Berberine",
        "Resveratrol", "Quercetin", "K2", "Chromium", "5-HTP",
        "GABA", "DHA", "Lutein", "Alpha-GPC", "Astragalus",
        "Cordyceps", "Reishi", "Maca", "Boron", "Glycine",
        "Taurine", "Iodine", "Choline", "PQQ", "Shilajit",
        "Tongkat Ali", "Saw Palmetto", "Oregano Oil", "Psyllium", "Inositol"
    ]

    private struct CloudItem: Identifiable {
        let id: Int
        let text: String
        let x: CGFloat
        let y: CGFloat
        let fontSize: CGFloat
        let fontWeight: Font.Weight
        let opacity: Double
        let rotation: Double
        // Per-item drift parameters
        let phaseX: Double
        let phaseY: Double
        let speedX: Double
        let speedY: Double
        let driftRadius: CGFloat
        let colorIndex: Int
    }

    private static let cachedItems: [CloudItem] = {
        var seededRandom = SeededRandom(seed: 42)
        return supplements.enumerated().map { index, name in
            CloudItem(
                id: index,
                text: name,
                x: seededRandom.next() * 0.85 + 0.075,
                y: seededRandom.next() * 0.85 + 0.075,
                fontSize: CGFloat(11 + seededRandom.next() * 11),
                fontWeight: [Font.Weight.light, .regular, .semibold][Int(seededRandom.next() * 3) % 3],
                opacity: seededRandom.next() < 0.12 ? 0.85 + seededRandom.next() * 0.15 : 0.55 + seededRandom.next() * 0.25,
                rotation: Double(seededRandom.next() * 6 - 3),
                phaseX: Double(seededRandom.next()) * .pi * 2,
                phaseY: Double(seededRandom.next()) * .pi * 2,
                speedX: 0.15 + Double(seededRandom.next()) * 0.25,
                speedY: 0.15 + Double(seededRandom.next()) * 0.25,
                driftRadius: 6 + seededRandom.next() * 10,
                colorIndex: Int(seededRandom.next() * 6) % 6
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !animated)) { timeline in
            let elapsed = animated ? timeline.date.timeIntervalSince(startDate) : 0

            GeometryReader { geo in
                ZStack {
                    ForEach(Self.cachedItems) { item in
                        let dx = CGFloat(sin(elapsed * item.speedX + item.phaseX)) * item.driftRadius
                        let dy = CGFloat(cos(elapsed * item.speedY + item.phaseY)) * item.driftRadius

                        Text(item.text)
                            .font(.custom("Geist-Regular", size: item.fontSize).weight(item.fontWeight))
                            .foregroundStyle(Self.accentColors[item.colorIndex].opacity(item.opacity))
                            .rotationEffect(.degrees(item.rotation))
                            .position(
                                x: item.x * geo.size.width + dx,
                                y: item.y * geo.size.height + dy
                            )
                    }
                }
            }
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 0.75),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .opacity(opacity)
        .onAppear {
            startDate = .now
            guard animated else {
                opacity = 1
                return
            }

            withAnimation(.easeIn(duration: 0.6)) {
                opacity = 1
            }
        }
    }
}

// Simple seeded random for deterministic layout
private struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) & 0x7FFFFFFF) / CGFloat(0x7FFFFFFF)
    }
}

#Preview {
    SupplementCloudView()
        .frame(height: 300)
        .background(DesignTokens.bgDeepest)
}
