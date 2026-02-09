import SwiftUI
import UIKit

struct PlanRevealScreen: View {
    var viewModel: OnboardingViewModel
    let onConfirm: () -> Void

    // MARK: - Animation State

    @State private var showBackground = false
    @State private var showHeadline = false
    @State private var showSubtitle = false
    @State private var visibleGoalChips: Int = 0
    @State private var showTierHeaders: [SupplementTier: Bool] = [
        .core: false, .targeted: false, .supporting: false
    ]
    @State private var visibleCards: Int = 0
    @State private var showCTA = false
    @State private var particles: [RevealParticle] = []

    // MARK: - Interaction State

    @State private var expandedCardId: UUID?
    @State private var selectedGoalFilter: HealthGoal? = nil
    @State private var animatedSupplementCount: Int = 0

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    private var supplements: [PlanSupplement] {
        viewModel.generatedPlan?.supplements ?? []
    }

    private var includedCount: Int {
        supplements.filter(\.isIncluded).count
    }

    private var totalCount: Int {
        supplements.count
    }

    private var userGoals: [HealthGoal] {
        Array(viewModel.healthGoals).sorted { $0.rawValue < $1.rawValue }
    }

    private var tiers: [SupplementTier] {
        let present = Set(supplements.map(\.tier))
        return SupplementTier.allCases.filter { present.contains($0) }
    }

    private var userName: String {
        let name = viewModel.firstName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "friend" : name
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            // Background particles
            particleField
                .opacity(showBackground ? 1 : 0)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // Header
                        headerSection
                            .padding(.top, DesignTokens.spacing40)

                        // Decorative divider
                        SpectrumBar(height: 5)
                            .padding(.horizontal, DesignTokens.spacing48)
                            .opacity(showSubtitle ? 1 : 0)

                        // Goal chips
                        goalChipsSection

                        // Tiered supplement sections
                        supplementSections

                        // Summary + disclaimer
                        summarySection

                        // Bottom spacer for CTA clearance
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                }

                // Fixed bottom CTA
                ctaSection
            }
        }
        .onAppear {
            generateParticles()
            startEntranceAnimation()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: DesignTokens.spacing8) {
            HeadlineText(
                text: "Your plan is ready, \(userName).",
                alignment: .center,
                fontSize: 32
            )
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline || reduceMotion ? 0 : 12)

            HStack(spacing: 4) {
                Text("\(animatedSupplementCount)")
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(DesignTokens.info)
                    .contentTransition(.numericText())
                Text("supplements tailored to your goals")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
            .opacity(showSubtitle ? 1 : 0)
        }
    }

    // MARK: - Goal Chips

    private var goalChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.spacing8) {
                // "All" chip
                allChip
                    .opacity(visibleGoalChips > 0 ? 1 : 0)
                    .offset(x: visibleGoalChips > 0 || reduceMotion ? 0 : -20)

                ForEach(Array(userGoals.enumerated()), id: \.element.id) { index, goal in
                    goalChip(for: goal)
                        .opacity(index < visibleGoalChips ? 1 : 0)
                        .offset(x: index < visibleGoalChips || reduceMotion ? 0 : -20)
                }
            }
        }
    }

    private var allChip: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedGoalFilter = nil
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 11))
                Text("All")
                    .font(DesignTokens.labelMono)
            }
            .foregroundStyle(DesignTokens.textPrimary)
            .padding(.horizontal, DesignTokens.spacing12)
            .padding(.vertical, 6)
            .background(selectedGoalFilter == nil ? DesignTokens.textPrimary.opacity(0.15) : DesignTokens.textPrimary.opacity(0.06))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(DesignTokens.textPrimary.opacity(selectedGoalFilter == nil ? 0.4 : 0.15), lineWidth: 1))
            .opacity(selectedGoalFilter != nil ? 0.6 : 1)
        }
        .buttonStyle(.plain)
    }

    private func goalChip(for goal: HealthGoal) -> some View {
        let isSelected = selectedGoalFilter == goal
        let isFiltering = selectedGoalFilter != nil

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedGoalFilter = selectedGoalFilter == goal ? nil : goal
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: goal.icon)
                    .font(.system(size: 11))
                Text(goal.shortLabel)
                    .font(DesignTokens.labelMono)
            }
            .foregroundStyle(goal.accentColor)
            .padding(.horizontal, DesignTokens.spacing12)
            .padding(.vertical, 6)
            .background(goal.accentColor.opacity(isSelected ? 0.30 : 0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(goal.accentColor.opacity(isSelected ? 0.6 : 0.25), lineWidth: 1))
            .opacity(isFiltering && !isSelected ? 0.6 : 1)
        }
        .buttonStyle(.plain)
    }

    private func cardMatchesFilter(_ supplement: PlanSupplement) -> Bool {
        guard let filter = selectedGoalFilter else { return true }
        return supplement.matchedGoals.contains(filter.rawValue)
    }

    // MARK: - Supplement Sections

    private var supplementSections: some View {
        VStack(spacing: DesignTokens.spacing32) {
            ForEach(tiers) { tier in
                let tierSupplements = supplements.filter { $0.tier == tier }
                if !tierSupplements.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                        // Tier header
                        tierHeader(for: tier, count: tierSupplements.count)
                            .opacity(showTierHeaders[tier] == true ? 1 : 0)
                            .offset(y: showTierHeaders[tier] == true || reduceMotion ? 0 : 8)

                        // Cards
                        ForEach(tierSupplements) { supplement in
                            let globalIndex = supplements.firstIndex(where: { $0.id == supplement.id }) ?? 0
                            let matches = cardMatchesFilter(supplement)
                            RevealSupplementCard(
                                supplement: supplement,
                                tier: tier,
                                userGoals: userGoals,
                                isExpanded: expandedCardId == supplement.id,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        expandedCardId = expandedCardId == supplement.id ? nil : supplement.id
                                    }
                                },
                                onToggle: {
                                    HapticManager.selection()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        toggleSupplement(supplement.id)
                                    }
                                }
                            )
                            .opacity(globalIndex < visibleCards ? (matches ? 1 : 0.55) : 0)
                            .scaleEffect(globalIndex < visibleCards && !matches ? 0.97 : 1.0)
                            .offset(y: globalIndex < visibleCards || reduceMotion ? 0 : 12)
                            .animation(.easeInOut(duration: 0.25), value: selectedGoalFilter)
                        }
                    }
                }
            }
        }
    }

    private func tierHeader(for tier: SupplementTier, count: Int) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DesignTokens.spacing8) {
                    Image(systemName: tier.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tierAccentColor(for: tier))

                    Text(tier.label)
                        .font(DesignTokens.sectionHeader)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .tracking(1.2)
                }

                Text(tier.description)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            Spacer()

            Text("\(count) supplement\(count == 1 ? "" : "s")")
                .font(DesignTokens.labelMono)
                .foregroundStyle(DesignTokens.textTertiary)
        }
    }

    private func tierAccentColor(for tier: SupplementTier) -> Color {
        switch tier {
        case .core: return DesignTokens.accentEnergy
        case .targeted: return DesignTokens.accentClarity
        case .supporting: return DesignTokens.textSecondary
        }
    }

    // MARK: - Summary + Disclaimer

    private var summarySection: some View {
        VStack(spacing: DesignTokens.spacing8) {
            (
                Text("\(includedCount)")
                    .font(DesignTokens.dataMono)
                    .foregroundColor(DesignTokens.info)
                +
                Text(" of ")
                    .font(DesignTokens.captionFont)
                    .foregroundColor(DesignTokens.textSecondary)
                +
                Text("\(totalCount)")
                    .font(DesignTokens.dataMono)
                    .foregroundColor(DesignTokens.info)
                +
                Text(" supplements selected")
                    .font(DesignTokens.captionFont)
                    .foregroundColor(DesignTokens.textSecondary)
            )

            SpectrumBar(height: 3, progress: totalCount > 0 ? CGFloat(includedCount) / CGFloat(totalCount) : 0)
                .padding(.horizontal, DesignTokens.spacing48)

            Text("These recommendations are for informational purposes only and do not constitute medical advice. Consult your healthcare provider before starting any supplement regimen.")
                .font(.custom("Geist-Regular", size: 9))
                .foregroundStyle(DesignTokens.textTertiary)
                .multilineTextAlignment(.center)
        }
        .opacity(showCTA ? 1 : 0)
    }

    // MARK: - Fixed CTA

    private var ctaSection: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [DesignTokens.bgDeepest.opacity(0), DesignTokens.bgDeepest],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            VStack(spacing: 0) {
                CTAButton(
                    title: "Start my plan (\(includedCount))",
                    style: .primary,
                    action: onConfirm,
                    spectrumBorder: true
                )
                .opacity(includedCount > 0 ? 1.0 : 0.4)
                .disabled(includedCount == 0)
                .scaleEffect(showCTA || reduceMotion ? 1.0 : 0.95)
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing16)
            }
            .background(DesignTokens.bgDeepest)
        }
        .opacity(showCTA ? 1 : 0)
        .offset(y: showCTA || reduceMotion ? 0 : 40)
    }

    // MARK: - Toggle Helper

    private func toggleSupplement(_ id: UUID) {
        if let index = viewModel.generatedPlan?.supplements.firstIndex(where: { $0.id == id }) {
            viewModel.generatedPlan?.supplements[index].isIncluded.toggle()
        }
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        let fadeDuration: Double = reduceMotion ? 0.15 : 0.4

        // Background + particles
        withAnimation(.easeOut(duration: reduceMotion ? 0.1 : 0.3)) {
            showBackground = true
        }

        // Headline
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.05 : 0.3)) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showHeadline = true
            }
            HapticManager.notification(.success)
        }

        // Subtitle + SpectrumBar
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.1 : 0.6)) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showSubtitle = true
            }
            startCountAnimation()
        }

        // Goal chips staggered
        let chipStart: Double = reduceMotion ? 0.15 : 0.8
        let chipInterval: Double = reduceMotion ? 0.03 : 0.08
        for i in 0..<userGoals.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + chipStart + Double(i) * chipInterval) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    visibleGoalChips = i + 1
                }
            }
        }

        // Tier headers + cards
        let cardStart: Double = reduceMotion ? 0.3 : 1.2
        var delay = cardStart

        for tier in tiers {
            let tierDelay = delay
            DispatchQueue.main.asyncAfter(deadline: .now() + tierDelay) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    showTierHeaders[tier] = true
                }
            }
            delay += reduceMotion ? 0.05 : 0.2

            let tierSupplements = supplements.filter { $0.tier == tier }
            let cardInterval: Double = tier == .supporting ? 0.08 : 0.15
            for supplement in tierSupplements {
                let cardDelay = delay
                if let globalIndex = supplements.firstIndex(where: { $0.id == supplement.id }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + cardDelay) {
                        withAnimation(.easeOut(duration: fadeDuration)) {
                            visibleCards = globalIndex + 1
                        }
                    }
                }
                delay += reduceMotion ? 0.03 : cardInterval
            }
        }

        // CTA slides up after last card
        let ctaDelay = delay + (reduceMotion ? 0.1 : 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + ctaDelay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showCTA = true
            }
        }
    }

    // MARK: - Count Animation

    private func startCountAnimation() {
        let target = totalCount
        guard target > 0 else {
            animatedSupplementCount = 0
            return
        }

        if reduceMotion {
            animatedSupplementCount = target
            return
        }

        let totalDuration: Double = 0.6
        let stepInterval = totalDuration / Double(target)

        for i in 1...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepInterval * Double(i)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    animatedSupplementCount = i
                }
            }
        }
    }

    // MARK: - Particles

    private struct RevealParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var duration: Double
        var color: Color
    }

    private static let spectrumColors: [Color] = [
        DesignTokens.accentSleep,
        DesignTokens.accentEnergy,
        DesignTokens.accentClarity,
        DesignTokens.accentMood,
        DesignTokens.accentGut
    ]

    private func generateParticles() {
        particles = (0..<20).map { _ in
            RevealParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.3),
                duration: Double.random(in: 3...7),
                color: Self.spectrumColors.randomElement()!
            )
        }
    }

    private var particleField: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(
                        x: particle.x * geometry.size.width,
                        y: particle.y * geometry.size.height
                    )
                    .opacity(particle.opacity)
                    .modifier(RevealPulseModifier(duration: particle.duration))
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Supplement Card

private struct RevealSupplementCard: View {
    let supplement: PlanSupplement
    let tier: SupplementTier
    let userGoals: [HealthGoal]
    let isExpanded: Bool
    let onTap: () -> Void
    let onToggle: () -> Void

    private var matchedHealthGoals: [HealthGoal] {
        userGoals.filter { supplement.matchedGoals.contains($0.rawValue) }
    }

    private var accentColors: [Color] {
        matchedHealthGoals.map(\.accentColor)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Collapsed: name + dosage + toggle on one row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(supplement.name)
                            .font(.custom("Geist-SemiBold", size: 17))
                            .foregroundStyle(DesignTokens.textPrimary)
                            .strikethrough(!supplement.isIncluded, color: DesignTokens.textTertiary)

                        Text(supplement.dosage)
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(DesignTokens.info)
                    }

                    Spacer()

                    SupplementToggle(isOn: supplement.isIncluded, action: onToggle)
                }

                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                        // Divider
                        Rectangle()
                            .fill(DesignTokens.borderSubtle)
                            .frame(height: 1)
                            .padding(.top, DesignTokens.spacing4)

                        // Timing row
                        HStack(spacing: DesignTokens.spacing8) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundStyle(DesignTokens.textTertiary)
                                .frame(width: 18, alignment: .center)

                            Text(supplement.timing.label)
                                .font(DesignTokens.labelMono)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(DesignTokens.bgElevated)
                                .clipShape(Capsule())
                        }

                        // Goal tags row
                        if !matchedHealthGoals.isEmpty {
                            HStack(alignment: .top, spacing: DesignTokens.spacing8) {
                                Image(systemName: "scope")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DesignTokens.textTertiary)
                                    .frame(width: 18, alignment: .center)
                                    .padding(.top, 3)

                                FlowLayout(spacing: 6) {
                                    ForEach(matchedHealthGoals) { goal in
                                        Text(goal.shortLabel)
                                            .font(DesignTokens.smallMono)
                                            .foregroundStyle(goal.accentColor)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(goal.accentColor.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Research note as blockquote
                        if let note = supplement.researchNote, !note.isEmpty {
                            HStack(alignment: .top, spacing: 0) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(tierAccentColor.opacity(0.30))
                                    .frame(width: 2)

                                Text(note)
                                    .font(DesignTokens.captionFont)
                                    .foregroundStyle(DesignTokens.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.leading, DesignTokens.spacing8)
                            }
                        }

                        // Category badge
                        HStack(spacing: DesignTokens.spacing8) {
                            Image(systemName: "tag")
                                .font(.system(size: 12))
                                .foregroundStyle(DesignTokens.textTertiary)
                                .frame(width: 18, alignment: .center)

                            Text(SupplementKnowledgeBase.categoryLabel(for: supplement.category))
                                .font(DesignTokens.labelMono)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(DesignTokens.bgElevated)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(DesignTokens.borderDefault, lineWidth: 1)
                                )
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Chevron hint — sits below expanded content when open
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show less" : "Learn more")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
            }
            .padding(DesignTokens.spacing16)
            .background(cardBackground)
            .opacity(supplement.isIncluded ? 1.0 : 0.5)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                // Left accent bar — wider for core (5px), standard for targeted (3px)
                if tier == .core, accentColors.count > 1 {
                    UnevenRoundedRectangle(
                        topLeadingRadius: DesignTokens.radiusMedium,
                        bottomLeadingRadius: DesignTokens.radiusMedium
                    )
                    .fill(
                        LinearGradient(
                            colors: accentColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 5)
                } else if tier == .core, let color = accentColors.first {
                    UnevenRoundedRectangle(
                        topLeadingRadius: DesignTokens.radiusMedium,
                        bottomLeadingRadius: DesignTokens.radiusMedium
                    )
                    .fill(color)
                    .frame(width: 5)
                } else if tier == .targeted, let color = accentColors.first {
                    UnevenRoundedRectangle(
                        topLeadingRadius: DesignTokens.radiusMedium,
                        bottomLeadingRadius: DesignTokens.radiusMedium
                    )
                    .fill(color)
                    .frame(width: 3)
                }
            }
            // Core: subtle radial glow from left edge
            .overlay(alignment: .leading) {
                if tier == .core, let color = accentColors.first {
                    RadialGradient(
                        colors: [color.opacity(0.04), Color.clear],
                        center: .leading,
                        startRadius: 0,
                        endRadius: 120
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var tierAccentColor: Color {
        accentColors.first ?? DesignTokens.textSecondary
    }

    @ViewBuilder
    private var cardBackground: some View {
        if tier == .supporting {
            DesignTokens.bgSurface.opacity(0.7)
        } else {
            DesignTokens.bgSurface
        }
    }
}

// MARK: - Custom Toggle

private struct SupplementToggle: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule()
                .fill(isOn ? DesignTokens.positive : DesignTokens.bgElevated)
                .frame(width: 44, height: 26)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .padding(2)
                }
                .animation(.easeInOut(duration: 0.2), value: isOn)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pulse Animation

private struct RevealPulseModifier: ViewModifier {
    let duration: Double
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 1.0 : 0.2)
            .scaleEffect(isAnimating ? 1.3 : 0.8)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Preview

#Preview {
    PlanRevealScreen(
        viewModel: {
            let vm = OnboardingViewModel()
            vm.firstName = "Matt"
            vm.healthGoals = [.sleep, .energy, .focus, .stressAnxiety]

            let engine = RecommendationEngine()
            let profile = vm.buildUserProfile()
            vm.generatedPlan = engine.generatePlan(for: profile)

            return vm
        }(),
        onConfirm: {}
    )
}
