import SwiftUI
import UIKit

struct PaywallScreen: View {
    var viewModel: OnboardingViewModel
    let onSubscribe: () -> Void
    var onDismiss: () -> Void = {}

    // MARK: - Animation State

    @State private var showRestore = false
    @State private var showHeadline = false
    @State private var showSubtitle = false
    @State private var visibleTeaserCards: Int = 0
    @State private var visibleBenefitRows: Int = 0
    @State private var visibleTimelineNodes: Int = 0
    @State private var showPricing = false
    @State private var showCTA = false

    // MARK: - Interaction State

    @State private var selectedPlan: PricingPlan = .annual
    @State private var showAllPlans: Bool = false
    @State private var expandedCardID: UUID? = nil

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    // MARK: - Computed Properties

    private var userName: String {
        let name = viewModel.firstName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "friend" : name
    }


    private var supplements: [PlanSupplement] {
        viewModel.generatedPlan?.supplements.filter(\.isIncluded) ?? []
    }

    private var teaserSupplements: [PlanSupplement] {
        Array(supplements.filter { $0.tier == .core }.prefix(2))
    }

    private var peekSupplement: PlanSupplement? {
        let coreSups = supplements.filter { $0.tier == .core }
        if coreSups.count > 2 {
            return coreSups[2]
        }
        return supplements.first { $0.tier == .targeted }
    }

    private var remainingCount: Int {
        let shown = teaserSupplements.count + (peekSupplement != nil ? 1 : 0)
        return max(supplements.count - shown, 0)
    }

    private var hiddenGoalLabels: [String] {
        let shownIDs = Set(teaserSupplements.map(\.id) + [peekSupplement?.id].compactMap { $0 })
        let hiddenSupplements = supplements.filter { !shownIDs.contains($0.id) }
        let allHiddenGoalRaws = Set(hiddenSupplements.flatMap(\.matchedGoals))
        let userGoals = Array(viewModel.healthGoals)
        return userGoals
            .filter { allHiddenGoalRaws.contains($0.rawValue) }
            .map(\.shortLabel)
    }

    private var hiddenGoalsCopy: String {
        let count = remainingCount
        let labels = hiddenGoalLabels
        let goalText: String
        if labels.count > 2 {
            let allButLast = labels.dropLast().joined(separator: ", ")
            goalText = "\(allButLast), and \(labels.last!)"
        } else if labels.count == 2 {
            goalText = "\(labels[0]) and \(labels[1])"
        } else if let single = labels.first {
            goalText = single
        } else {
            return "\(count) more supplements"
        }
        return "\(count) more supplements targeting your \(goalText) goals"
    }

    private var ctaSubtext: String {
        switch selectedPlan {
        case .annual:
            return "7-day free trial, then $79.99/year. Cancel anytime."
        case .quarterly:
            return "7-day free trial, then $29.99/quarter. Cancel anytime."
        case .monthly:
            return "7-day free trial, then $12.99/month. Cancel anytime."
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar — restore only
                topBar

                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // A. Personalized Hero
                        heroSection
                            .padding(.top, DesignTokens.spacing24)

                        // Decorative divider
                        SpectrumBar(height: 5)
                            .padding(.horizontal, DesignTokens.spacing48)
                            .opacity(showSubtitle ? 1 : 0)

                        // B. Supplement Teaser
                        supplementTeaserSection

                        // C. Trial Timeline
                        trialTimelineSection

                        // D. Value Proposition Checklist
                        benefitsSection

                        // E. Pricing Section
                        pricingSection

                        // F. Bottom spacer for CTA clearance
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                }

                // Fixed bottom CTA
                ctaSection
            }
        }
        .onAppear {
            startEntranceAnimation()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button("Not now") {
                onDismiss()
            }
            .font(DesignTokens.captionFont)
            .foregroundStyle(DesignTokens.textSecondary)

            Spacer()

            Button("Restore") {
                // RevenueCat restore will be wired later
            }
            .font(DesignTokens.captionFont)
            .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.horizontal, DesignTokens.spacing16)
        .padding(.top, DesignTokens.spacing8)
        .padding(.bottom, DesignTokens.spacing4)
        .opacity(showRestore ? 1 : 0)
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DesignTokens.spacing8) {
            HeadlineText(
                text: "\(userName), your personalized supplement plan is ready.",
                alignment: .center,
                fontSize: 28
            )
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline || reduceMotion ? 0 : 12)

        }
    }

    // MARK: - Supplement Teaser

    private var supplementTeaserSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Text("YOUR PLAN")
                .font(DesignTokens.sectionHeader)
                .foregroundStyle(DesignTokens.textPrimary)
                .tracking(1.2)
                .opacity(visibleTeaserCards > 0 ? 1 : 0)

            ForEach(Array(teaserSupplements.enumerated()), id: \.element.id) { index, supplement in
                SupplementCardView(
                    supplement: supplement,
                    trailingAccessory: .goalChips(Array(viewModel.healthGoals)),
                    expansionMode: .inline,
                    isExpanded: expandedCardID == supplement.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            expandedCardID = expandedCardID == supplement.id ? nil : supplement.id
                        }
                    }
                )
                .opacity(index < visibleTeaserCards ? 1 : 0)
                .offset(y: index < visibleTeaserCards || reduceMotion ? 0 : 8)
            }

            if let peek = peekSupplement {
                SupplementCardView(
                    supplement: peek,
                    trailingAccessory: .goalChips(Array(viewModel.healthGoals)),
                    expansionMode: .none
                )
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 52, alignment: .top)
                    .clipped()
                    .allowsHitTesting(false)
                    .opacity(visibleTeaserCards >= teaserSupplements.count ? 1 : 0)
            }

            if remainingCount > 0 {
                HStack {
                    Spacer()
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                        Text(hiddenGoalsCopy)
                            .font(DesignTokens.labelMono)
                            .lineSpacing(0)
                    }
                    .foregroundStyle(DesignTokens.accentImmunity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DesignTokens.accentImmunity.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(DesignTokens.accentImmunity.opacity(0.2), lineWidth: 1)
                    )
                    Spacer()
                }
                .opacity(visibleTeaserCards >= teaserSupplements.count ? 1 : 0)
            }
        }
    }

    // MARK: - Benefits Section

    private static let benefits: [(icon: String, title: String, subtitle: String)] = [
        ("brain.head.profile", "AI-powered supplement plan", "Personalized to your goals and health profile"),
        ("chart.line.uptrend.xyaxis", "Daily tracking & Wellbeing Score", "See what's working with data-driven insights"),
        ("arrow.triangle.2.circlepath", "Adaptive recommendations", "Your plan evolves as your data grows")
    ]

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
            ForEach(Array(Self.benefits.enumerated()), id: \.offset) { index, benefit in
                benefitRow(icon: benefit.icon, title: benefit.title, subtitle: benefit.subtitle)
                    .opacity(index < visibleBenefitRows ? 1 : 0)
                    .offset(y: index < visibleBenefitRows || reduceMotion ? 0 : 8)
            }
        }
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DesignTokens.textPrimary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Geist-SemiBold", size: 15))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text(subtitle)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
    }



    // MARK: - Trial Timeline

    private var trialTimelineSection: some View {
        VStack(spacing: 0) {
            TrialTimelineView(visibleNodes: visibleTimelineNodes, reduceMotion: reduceMotion)
        }
        .padding(DesignTokens.spacing16)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: DesignTokens.spacing12) {
            if showAllPlans {
                // Expanded: 3 plan cards
                HStack(alignment: .top, spacing: DesignTokens.spacing8) {
                    PricingCardView(plan: .monthly, isSelected: selectedPlan == .monthly) {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = .monthly }
                    }
                    PricingCardView(plan: .annual, isSelected: selectedPlan == .annual) {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = .annual }
                    }
                    PricingCardView(plan: .quarterly, isSelected: selectedPlan == .quarterly) {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = .quarterly }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Default: single annual card
                defaultAnnualCard
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Button {
                HapticManager.selection()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showAllPlans.toggle()
                }
            } label: {
                Text(showAllPlans ? "Show less" : "View all plans")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
        .opacity(showPricing ? 1 : 0)
        .offset(y: showPricing || reduceMotion ? 0 : 12)
    }

    private var defaultAnnualCard: some View {
        VStack(spacing: DesignTokens.spacing4) {
            Text("Save 49%")
                .font(.custom("GeistMono-Medium", size: 10))
                .foregroundStyle(DesignTokens.bgDeepest)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(DesignTokens.positive)
                .clipShape(Capsule())
                .padding(.bottom, 2)

            Text("$1.54 / week")
                .font(DesignTokens.titleFont)
                .foregroundStyle(DesignTokens.textPrimary)

            HStack(spacing: 4) {
                Text("Billed annually as")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                Text("$155.88")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .overlay(
                        Rectangle()
                            .fill(DesignTokens.textSecondary)
                            .frame(height: 1.5)
                    )
                Text("$79.99")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            Text("7-day free trial included")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.positive)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.spacing20)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
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

            VStack(spacing: DesignTokens.spacing8) {
                CTAButton(
                    title: "Start My Free Trial",
                    style: .primary,
                    action: onSubscribe,
                    spectrumBorder: true
                )

                Text(ctaSubtext)
                    .font(.custom("Geist-Regular", size: 11))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: DesignTokens.spacing16) {
                    Button("Terms") {
                        // Wire to terms URL later
                    }
                    .font(.custom("Geist-Regular", size: 11))
                    .foregroundStyle(DesignTokens.textSecondary)

                    Text("|")
                        .font(.custom("Geist-Regular", size: 11))
                        .foregroundStyle(DesignTokens.textSecondary)

                    Button("Privacy") {
                        // Wire to privacy URL later
                    }
                    .font(.custom("Geist-Regular", size: 11))
                    .foregroundStyle(DesignTokens.textSecondary)
                }
                .padding(.bottom, DesignTokens.spacing4)
            }
            .padding(.horizontal, DesignTokens.spacing24)
            .padding(.bottom, DesignTokens.spacing16)
            .background(DesignTokens.bgDeepest)
        }
        .opacity(showCTA ? 1 : 0)
        .offset(y: showCTA || reduceMotion ? 0 : 40)
    }

    // MARK: - Entrance Animation

    private func startEntranceAnimation() {
        let fadeDuration: Double = reduceMotion ? 0.15 : 0.4

        // 0.2s: Restore button
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.05 : 0.2)) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showRestore = true
            }
        }

        // 0.3s: Headline
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.05 : 0.3)) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showHeadline = true
            }
            HapticManager.notification(.success)
        }

        // 0.5s: Subtitle + spectrum bar
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.1 : 0.5)) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showSubtitle = true
            }
        }

        // 0.8s: Supplement teaser cards stagger (0.15s apart)
        let teaserCount = teaserSupplements.count + 1 // +1 for section header trigger
        for i in 0..<teaserCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.15 : 0.8) + Double(i) * (reduceMotion ? 0.03 : 0.15)) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    visibleTeaserCards = i + 1
                }
            }
        }

        // 1.2s: Benefit rows stagger (0.1s apart)
        for i in 0..<Self.benefits.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.2 : 1.2) + Double(i) * (reduceMotion ? 0.03 : 0.1)) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    visibleBenefitRows = i + 1
                }
            }
        }

        // 1.8s: Timeline nodes stagger (0.15s apart)
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.25 : 1.8) + Double(i) * (reduceMotion ? 0.03 : 0.15)) {
                withAnimation(.easeOut(duration: fadeDuration)) {
                    visibleTimelineNodes = i + 1
                }
            }
        }

        // 2.2s: Pricing
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.3 : 2.2)) {
            withAnimation(.easeOut(duration: fadeDuration)) {
                showPricing = true
            }
            HapticManager.impact(.light)
        }

        // 2.6s: CTA slides up with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.35 : 2.6)) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showCTA = true
            }
        }
    }

}

// MARK: - Pricing Plan

private enum PricingPlan: String, CaseIterable {
    case monthly
    case annual
    case quarterly

    var label: String {
        switch self {
        case .monthly: return "1 MONTH"
        case .annual: return "1 YEAR"
        case .quarterly: return "3 MONTHS"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$12.99"
        case .annual: return "$79.99"
        case .quarterly: return "$29.99"
        }
    }

    var billingCycle: String {
        switch self {
        case .monthly: return "billed monthly"
        case .annual: return "billed annually"
        case .quarterly: return "billed quarterly"
        }
    }

    var perWeek: String {
        switch self {
        case .monthly: return "$3.00 per week"
        case .annual: return "$1.54 per week"
        case .quarterly: return "$2.31 per week"
        }
    }

    var isBestValue: Bool {
        self == .annual
    }

    /// Percent saved vs paying monthly, nil for monthly itself.
    var savingsPercent: Int? {
        switch self {
        case .monthly: return nil
        case .annual: return 49
        case .quarterly: return 23
        }
    }

    /// What you'd pay at the monthly rate for this billing period.
    var monthlyEquivalentPrice: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "$155.88"
        case .quarterly: return "$38.97"
        }
    }
}

// MARK: - Pricing Card View

private struct PricingCardView: View {
    let plan: PricingPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: DesignTokens.spacing4) {
                Text(plan.label)
                    .font(DesignTokens.sectionHeader)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .tracking(1.0)

                Text(plan.price)
                    .font(DesignTokens.titleFont)
                    .foregroundStyle(DesignTokens.textPrimary)

                if let baseline = plan.monthlyEquivalentPrice,
                   let savings = plan.savingsPercent {
                    HStack(spacing: 4) {
                        Text(baseline)
                            .font(.custom("GeistMono-Medium", size: 10))
                            .foregroundStyle(DesignTokens.textTertiary)
                            .strikethrough(color: DesignTokens.textTertiary)

                        Text("\(savings)% off")
                            .font(.custom("GeistMono-Medium", size: 10))
                            .foregroundStyle(DesignTokens.negative)
                    }
                }

                Text(plan.billingCycle)
                    .font(.custom("Geist-Regular", size: 10))
                    .foregroundStyle(DesignTokens.textSecondary)

                Text(plan.perWeek)
                    .font(DesignTokens.labelMono)
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.spacing16)
            .padding(.horizontal, DesignTokens.spacing4)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                    .stroke(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [
                                    DesignTokens.accentSleep,
                                    DesignTokens.accentEnergy,
                                    DesignTokens.accentClarity,
                                    DesignTokens.accentMood,
                                    DesignTokens.accentGut
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            : AnyShapeStyle(DesignTokens.borderDefault),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .overlay(alignment: .top) {
                if plan.isBestValue {
                    Text("Best value")
                        .font(.custom("GeistMono-Medium", size: 9))
                        .foregroundStyle(DesignTokens.bgDeepest)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [DesignTokens.accentEnergy, DesignTokens.accentClarity],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .offset(y: -9)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trial Timeline View

private struct TrialTimelineView: View {
    let visibleNodes: Int
    let reduceMotion: Bool

    private let nodes: [(day: String, title: String, subtitle: String)] = [
        ("TODAY", "FREE", "Get instant access to all premium features"),
        ("DAY 5", "", "We'll send you a friendly reminder"),
        ("DAY 7", "", "Billing begins — cancel anytime prior with no charge")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
                HStack(alignment: .top, spacing: DesignTokens.spacing12) {
                    // Timeline node + line
                    VStack(spacing: 0) {
                        timelineNode(index: index)
                        if index < nodes.count - 1 {
                            Rectangle()
                                .fill(DesignTokens.textTertiary)
                                .frame(width: 1.5)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 3)
                        }
                    }
                    .frame(width: 24)
                    .padding(.top, 2)

                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: DesignTokens.spacing8) {
                            Text(node.day)
                                .font(DesignTokens.sectionHeader)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .tracking(1.0)

                            if !node.title.isEmpty {
                                Text(node.title)
                                    .font(.custom("GeistMono-Medium", size: 10))
                                    .foregroundStyle(DesignTokens.positive)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DesignTokens.positive.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(node.subtitle)
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                    .padding(.bottom, index < nodes.count - 1 ? DesignTokens.spacing12 : 0)

                    Spacer()
                }
                .opacity(index < visibleNodes ? 1 : 0)
                .offset(y: index < visibleNodes || reduceMotion ? 0 : 8)
            }
        }
    }

    @ViewBuilder
    private func timelineNode(index: Int) -> some View {
        if index == 0 {
            // Today: filled chartreuse
            Circle()
                .fill(DesignTokens.accentGut)
                .frame(width: 14, height: 14)
        } else if index == 1 {
            // Day 5: outlined chartreuse
            Circle()
                .stroke(DesignTokens.accentGut, lineWidth: 1.5)
                .frame(width: 14, height: 14)
        } else {
            // Day 7: outlined tertiary
            Circle()
                .stroke(DesignTokens.textTertiary, lineWidth: 1.5)
                .frame(width: 14, height: 14)
        }
    }
}


// MARK: - Preview

#Preview {
    PaywallScreen(
        viewModel: {
            let vm = OnboardingViewModel()
            vm.firstName = "Matt"
            vm.healthGoals = [.sleep, .energy, .focus, .stressAnxiety]

            let engine = RecommendationEngine()
            let profile = vm.buildUserProfile()
            vm.generatedPlan = engine.generatePlan(for: profile)

            return vm
        }(),
        onSubscribe: {}
    )
}
