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
    @State private var showTimeline = false
    @State private var visibleTimelineNodes: Int = 0
    @State private var showPricing = false
    @State private var showCTA = false

    // MARK: - Interaction State

    @State private var selectedPlan: PricingPlan = .annual
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
        Array(supplements.prefix(2))
    }

    private var peekSupplement: PlanSupplement? {
        supplements.count > 2 ? supplements[2] : nil
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
        "Start your free trial to view \(remainingCount) more supplements targeting your specific goals."
    }

    @Environment(AppState.self) private var appState

    private func sortedGoals(for supplement: PlanSupplement) -> [HealthGoal] {
        supplement.matchedGoals
            .compactMap { HealthGoal(rawValue: $0) }
            .sorted {
                appState.supplementCatalog.weight(for: supplement.name, goal: $0.rawValue) >
                appState.supplementCatalog.weight(for: supplement.name, goal: $1.rawValue)
            }
    }

    private var ctaSubtext: String {
        switch selectedPlan {
        case .annual:
            return "7-day free trial, then $29.99/year. Cancel anytime."
        case .monthly:
            return "7-day free trial, then $4.99/month. Cancel anytime."
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

                        // D. Pricing Section
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
        .task {
            await startEntranceAnimation()
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
                text: "\(userName), your personalized supplement plan is ready",
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
                    inlineGoals: sortedGoals(for: supplement),
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
                    expansionMode: .none,
                    inlineGoals: sortedGoals(for: peek)
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
                HStack(spacing: DesignTokens.spacing12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22))

                    Text(hiddenGoalsCopy)
                        .font(DesignTokens.captionFont)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(0)
                }
                .foregroundStyle(Color(hex: "#C25D93"))
                .padding(.leading, 18)
                .padding(.trailing, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color(hex: "#C25D93"), lineWidth: 1)
                )
                .opacity(visibleTeaserCards >= teaserSupplements.count ? 1 : 0)
            }
        }
    }

    // MARK: - Benefits Section

    private static let benefits: [(icon: String, title: String, subtitle: String, accent: Color)] = [
        ("person.crop.circle.badge.checkmark", "Built for your body", "Your plan is tailored to your goals, medications, and lifestyle — not generic advice", DesignTokens.accentSleep),
        ("chart.line.uptrend.xyaxis", "Know what's actually working", "Track how supplements affect your sleep, energy, mood, and more", DesignTokens.accentClarity),
        ("sparkles", "Gets smarter every week", "Your plan adjusts based on real patterns in your data", DesignTokens.accentGut)
    ]

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            ForEach(Array(Self.benefits.enumerated()), id: \.offset) { index, benefit in
                benefitRow(icon: benefit.icon, title: benefit.title, subtitle: benefit.subtitle, accent: benefit.accent)
                    .opacity(index < visibleBenefitRows ? 1 : 0)
                    .offset(y: index < visibleBenefitRows || reduceMotion ? 0 : 8)
            }
        }
    }

    private func benefitRow(icon: String, title: String, subtitle: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 32, height: 32)
                .background(accent.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Geist-SemiBold", size: 15))
                    .foregroundStyle(DesignTokens.textPrimary)
                Text(subtitle)
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
        .padding(DesignTokens.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
    }



    // MARK: - Trial Timeline

    private var trialTimelineSection: some View {
        VStack(spacing: 0) {
            TrialTimelineView(visibleNodes: visibleTimelineNodes, reduceMotion: reduceMotion)
        }
        .padding(DesignTokens.spacing16)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .opacity(showTimeline ? 1 : 0)
        .offset(y: showTimeline || reduceMotion ? 0 : 8)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: DesignTokens.spacing16) {
            Text("Choose the plan that works best for you")
                .font(.custom("Geist-Regular", size: 16))
                .foregroundStyle(DesignTokens.textPrimary)
                .padding(.top, DesignTokens.spacing8)
                .padding(.bottom, DesignTokens.spacing8)

        HStack(alignment: .top, spacing: DesignTokens.spacing8) {
            PricingCardView(plan: .monthly, isSelected: selectedPlan == .monthly) {
                HapticManager.selection()
                withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = .monthly }
            }
            PricingCardView(plan: .annual, isSelected: selectedPlan == .annual) {
                HapticManager.selection()
                withAnimation(.easeInOut(duration: 0.2)) { selectedPlan = .annual }
            }
        }
        }
        .opacity(showPricing ? 1 : 0)
        .offset(y: showPricing || reduceMotion ? 0 : 12)
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
                    spectrumBorder: false
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

    @MainActor
    private func startEntranceAnimation() async {
        let fadeDuration: Double = reduceMotion ? 0.15 : 0.4
        let stagger: Double = reduceMotion ? 0.03 : 0.15

        // Restore button
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.2))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showRestore = true
        }

        // Headline
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.0 : 0.1))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showHeadline = true
        }
        HapticManager.notification(.success)

        // Subtitle + spectrum bar
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.2))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showSubtitle = true
        }

        // Supplement teaser cards stagger
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.3))
        let teaserCount = teaserSupplements.count + 1
        for i in 0..<teaserCount {
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: fadeDuration)) {
                visibleTeaserCards = i + 1
            }
            try? await Task.sleep(for: .seconds(stagger))
        }

        // Timeline card appears
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.02 : 0.1))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showTimeline = true
        }

        // Timeline nodes stagger
        for i in 0..<3 {
            guard !Task.isCancelled else { return }
            try? await Task.sleep(for: .seconds(stagger))
            withAnimation(.easeOut(duration: fadeDuration)) {
                visibleTimelineNodes = i + 1
            }
        }

        // Pricing
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.2))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showPricing = true
        }
        HapticManager.impact(.light)

        // CTA slides up with spring
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.4))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showCTA = true
        }
    }

}

// MARK: - Pricing Plan

private enum PricingPlan: String, CaseIterable {
    case monthly
    case annual

    var label: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .annual: return "$29.99"
        }
    }

    var billingCycle: String {
        switch self {
        case .monthly: return "billed monthly"
        case .annual: return "billed annually"
        }
    }

    var perWeek: String {
        switch self {
        case .monthly: return "$1.15 per week"
        case .annual: return "$0.58 per week"
        }
    }

    var isBestValue: Bool {
        self == .annual
    }

    /// Percent saved vs paying monthly, nil for monthly itself.
    var savingsPercent: Int? {
        switch self {
        case .monthly: return nil
        case .annual: return 50
        }
    }

    /// What you'd pay at the monthly rate for this billing period.
    var monthlyEquivalentPrice: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "$59.88"
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
                    .font(.custom("Geist-Regular", size: 14))
                    .foregroundStyle(DesignTokens.textPrimary)

                Text(plan.price)
                    .font(.custom("Geist-Regular", size: 20))
                    .foregroundStyle(DesignTokens.textPrimary)

                if let baseline = plan.monthlyEquivalentPrice,
                   let savings = plan.savingsPercent {
                    HStack(spacing: 4) {
                        Text(baseline)
                            .font(.custom("GeistMono-Medium", size: 10))
                            .foregroundStyle(DesignTokens.textTertiary)
                            .strikethrough(color: DesignTokens.textTertiary)

                        Text("\(savings)% OFF")
                            .font(.custom("GeistMono-Medium", size: 10))
                            .foregroundStyle(Color(hex: "#C25D93"))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, DesignTokens.spacing16)
            .padding(.horizontal, DesignTokens.spacing4)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .overlay(
                RoundedRectangle(cornerRadius: 26)
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
                        .font(.custom("Geist-Regular", size: 12))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#C25D93"))
                        .clipShape(Capsule())
                        .offset(y: -11)
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
                                    .foregroundStyle(Color(hex: "#C25D93"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(hex: "#C25D93"), lineWidth: 1)
                                    )
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
            // Today: filled green
            Circle()
                .fill(DesignTokens.onboardingSelected)
                .frame(width: 14, height: 14)
        } else if index == 1 {
            // Day 5: outlined green
            Circle()
                .stroke(DesignTokens.onboardingSelected, lineWidth: 1.5)
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
    let appState = AppState()
    appState.supplementCatalog.populateFromStatic()
    return PaywallScreen(
        viewModel: {
            let vm = OnboardingViewModel()
            vm.firstName = "Matt"
            vm.healthGoals = [.sleep, .energy, .focus, .stressAnxiety]

            let engine = RecommendationEngine(catalog: appState.supplementCatalog)
            let profile = vm.buildUserProfile()
            vm.generatedPlan = engine.generatePlan(for: profile)

            return vm
        }(),
        onSubscribe: {}
    )
    .environment(appState)
}
