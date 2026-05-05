import SwiftUI
import UIKit

private struct PlanRevealShopItem: Identifiable {
    let id: UUID
    let name: String
}

struct PlanRevealScreen: View {
    var viewModel: OnboardingViewModel
    let onConfirm: () -> Void

    // MARK: - Animation State

    @State private var showBackground = false
    @State private var showHeadline = false
    @State private var showSubtitle = false
    @State private var showSummary = false
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
    @State private var showEvidenceInfo: EvidenceLevel? = nil
    @State private var isSummaryExpanded: Bool = true
    @State private var showShimmer: Bool = true
    @State private var showTierInfo: SupplementTier? = nil
    @State private var shopSupplement: PlanRevealShopItem?
    @State private var shopProduct: RankedProduct?
    @State private var productsBySupplementId: [UUID: [RankedProduct]] = [:]
    @State private var loadingProductIds: Set<UUID> = []
    @State private var pendingRemovalId: UUID?

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
        let present = Set(supplements.filter(\.isIncluded).map(\.tier))
        return SupplementTier.allCases.filter { present.contains($0) }
    }

    private var removedSupplements: [PlanSupplement] {
        supplements.filter { !$0.isIncluded }
    }

    private var pendingRemovalSupplement: PlanSupplement? {
        guard let id = pendingRemovalId else { return nil }
        return supplements.first(where: { $0.id == id })
    }

    private var planTitle: String {
        let name = viewModel.firstName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Your Plan" : "\(name)'s Plan"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // Header
                        headerSection
                            .padding(.top, DesignTokens.spacing40)

                        // AI reasoning as flowing text
                        if let summary = viewModel.generatedPlan?.aiReasoning {
                            summaryBlurb(summary)
                        }

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
            // Evidence info modal
            if let level = showEvidenceInfo {
                EvidenceInfoModal(level: level) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showEvidenceInfo = nil
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }

        }
        .animation(.easeOut(duration: 0.2), value: showEvidenceInfo != nil)
        .task {
            generateParticles()
            await startEntranceAnimation()
        }
        .sheet(item: $shopSupplement) { item in
            ProductListSheet(
                supplementId: item.id,
                supplementName: item.name
            )
        }
        .sheet(item: $shopProduct) { rankedProduct in
            ShopLinksSheet(
                product: rankedProduct.product,
                pricing: rankedProduct.pricing
            )
        }
        .confirmationDialog(
            "Remove \(pendingRemovalSupplement?.name ?? "supplement") from your plan?",
            isPresented: Binding(
                get: { pendingRemovalId != nil },
                set: { if !$0 { pendingRemovalId = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingRemovalId
        ) { id in
            Button("Remove", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let index = viewModel.generatedPlan?.supplements.firstIndex(where: { $0.id == id }) {
                        viewModel.generatedPlan?.supplements[index].isIncluded = false
                    }
                    if expandedCardId == id {
                        expandedCardId = nil
                    }
                }
                HapticManager.notification(.success)
                pendingRemovalId = nil
            }
            Button("Cancel", role: .cancel) {
                pendingRemovalId = nil
            }
        } message: { _ in
            Text("You can add it back later by toggling it on.")
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: DesignTokens.spacing8) {
            Text(planTitle)
                .font(.custom("Geist-Light", size: 28))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(DesignTokens.textPrimary)
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline || reduceMotion ? 0 : 12)

        }
    }

    // MARK: - Goal Chips

    private var goalChipsSection: some View {
        HStack(spacing: DesignTokens.spacing4) {
            // "All" chip
            allChip
                .opacity(visibleGoalChips > 0 ? 1 : 0)

            ForEach(Array(userGoals.enumerated()), id: \.element.id) { index, goal in
                goalChip(for: goal)
                    .opacity(index < visibleGoalChips ? 1 : 0)
            }
        }
    }

    private var allChip: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedGoalFilter = nil
            }
        } label: {
            Text("All")
                .font(DesignTokens.labelMono)
                .foregroundStyle(selectedGoalFilter == nil ? .white : DesignTokens.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selectedGoalFilter == nil ? DesignTokens.textPrimary : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(DesignTokens.textPrimary, lineWidth: selectedGoalFilter == nil ? 0 : 1))
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
            Text(goal.shortLabel)
                .font(DesignTokens.labelMono)
                .foregroundStyle(isSelected ? .white : goal.chipColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? goal.chipColor : Color.white)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(goal.chipColor, lineWidth: isSelected ? 0 : 1))
                .opacity(isFiltering && !isSelected ? 0.6 : 1)
        }
        .buttonStyle(.plain)
    }

    private func cardMatchesFilter(_ supplement: PlanSupplement) -> Bool {
        guard let filter = selectedGoalFilter else { return true }
        return supplement.matchedGoals.contains(filter.rawValue)
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

    // MARK: - Summary Blurb

    private func summaryBlurb(_ text: String) -> some View {
        VStack(spacing: 0) {
            // Header pill
            Button {
                HapticManager.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isSummaryExpanded.toggle()
                }
            } label: {
                HStack(spacing: DesignTokens.spacing8) {
                    Image("EstusAIIcon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("Plan Overview")
                        .font(.custom("Geist-Regular", size: 20))
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .rotationEffect(.degrees(isSummaryExpanded ? 180 : 0))
                }
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.vertical, DesignTokens.spacing16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Description card (clipped so collapse animation hides behind pill)
            VStack(spacing: 0) {
                if isSummaryExpanded {
                    Text(text)
                        .font(.custom("Geist-Regular", size: 14))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .modifier(OneShotShimmerModifier(isActive: showShimmer && !reduceMotion))
                        .padding(DesignTokens.spacing20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .clipped()
        }
        .opacity(showSummary ? 1 : 0)
        .offset(y: showSummary || reduceMotion ? 0 : 8)
    }

    // MARK: - Supplement Sections

    private var supplementSections: some View {
        VStack(spacing: DesignTokens.spacing32) {
            ForEach(tiers) { tier in
                let tierSupplements = supplements.filter { $0.tier == tier && $0.isIncluded }
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
                            SupplementCardView(
                                supplement: supplement,
                                trailingAccessory: .toggle(isOn: supplement.isIncluded, action: {
                                    HapticManager.selection()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        toggleSupplement(supplement.id)
                                    }
                                }),
                                inlineGoals: sortedGoals(for: supplement),
                                isIncluded: supplement.isIncluded,
                                isExpanded: expandedCardId == supplement.id,
                                showBottomLearnMore: false,
                                products: supplement.supplementId.flatMap { productsBySupplementId[$0] },
                                productsLoading: supplement.supplementId.map { loadingProductIds.contains($0) } ?? false,
                                doseRange: appState.supplementCatalog.doseRange(for: supplement.name),
                                dosageUnit: supplement.dosage.dosageUnit,
                                recommendedDosageMg: supplement.dosageMg,
                                userDosageMg: dosageBinding(for: supplement),
                                onDosageCommit: { mg in setUserDosage(supplement.id, mg: mg) },
                                onEvidenceInfoTapped: { level in
                                    showEvidenceInfo = level
                                },
                                onShopTapped: supplement.supplementId != nil ? {
                                    shopSupplement = PlanRevealShopItem(
                                        id: supplement.supplementId!,
                                        name: supplement.name
                                    )
                                } : nil,
                                onProductTapped: { rankedProduct in
                                    shopProduct = rankedProduct
                                },
                                onSeeAllProductsTapped: supplement.supplementId != nil ? {
                                    shopSupplement = PlanRevealShopItem(
                                        id: supplement.supplementId!,
                                        name: supplement.name
                                    )
                                } : nil,
                                onRemoveTapped: {
                                    HapticManager.selection()
                                    pendingRemovalId = supplement.id
                                },
                                onTap: {
                                    HapticManager.selection()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        let isExpanding = expandedCardId != supplement.id
                                        expandedCardId = isExpanding ? supplement.id : nil
                                        if isExpanding {
                                            loadProducts(for: supplement)
                                        }
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

            if !removedSupplements.isEmpty {
                removedSection
            }
        }
    }

    private var removedSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            HStack(spacing: 6) {
                Text("Removed")
                    .font(.custom("Geist-Regular", size: 16))
                    .foregroundStyle(DesignTokens.textPrimary)

                Text("\(removedSupplements.count)")
                    .font(DesignTokens.labelMono)
                    .foregroundStyle(DesignTokens.textTertiary)
            }

            ForEach(removedSupplements) { supplement in
                SupplementCardView(
                    supplement: supplement,
                    trailingAccessory: .toggle(isOn: supplement.isIncluded, action: {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            toggleSupplement(supplement.id)
                        }
                    }),
                    inlineGoals: sortedGoals(for: supplement),
                    isIncluded: true,
                    isExpanded: expandedCardId == supplement.id,
                    showBottomLearnMore: false,
                    products: supplement.supplementId.flatMap { productsBySupplementId[$0] },
                    productsLoading: supplement.supplementId.map { loadingProductIds.contains($0) } ?? false,
                    doseRange: appState.supplementCatalog.doseRange(for: supplement.name),
                    dosageUnit: supplement.dosage.dosageUnit,
                    recommendedDosageMg: supplement.dosageMg,
                    userDosageMg: dosageBinding(for: supplement),
                    onDosageCommit: { mg in setUserDosage(supplement.id, mg: mg) },
                    onEvidenceInfoTapped: { level in
                        showEvidenceInfo = level
                    },
                    onShopTapped: supplement.supplementId != nil ? {
                        shopSupplement = PlanRevealShopItem(
                            id: supplement.supplementId!,
                            name: supplement.name
                        )
                    } : nil,
                    onProductTapped: { rankedProduct in
                        shopProduct = rankedProduct
                    },
                    onSeeAllProductsTapped: supplement.supplementId != nil ? {
                        shopSupplement = PlanRevealShopItem(
                            id: supplement.supplementId!,
                            name: supplement.name
                        )
                    } : nil,
                    onRestoreTapped: {
                        HapticManager.selection()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let index = viewModel.generatedPlan?.supplements.firstIndex(where: { $0.id == supplement.id }) {
                                viewModel.generatedPlan?.supplements[index].isIncluded = true
                            }
                        }
                    },
                    onTap: {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            let isExpanding = expandedCardId != supplement.id
                            expandedCardId = isExpanding ? supplement.id : nil
                            if isExpanding {
                                loadProducts(for: supplement)
                            }
                        }
                    }
                )
                .opacity(expandedCardId == supplement.id ? 1.0 : 0.55)
                .scaleEffect(expandedCardId == supplement.id ? 1.0 : 0.97)
                .animation(.easeInOut(duration: 0.25), value: removedSupplements.count)
            }
        }
    }

    private func tierHeader(for tier: SupplementTier, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(tier.label)
                .font(.custom("Geist-Regular", size: 16))
                .foregroundStyle(DesignTokens.textPrimary)

            Image(systemName: "info.circle")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.textTertiary)
                .onTapGesture {
                    showTierInfo = showTierInfo == tier ? nil : tier
                }
                .popover(isPresented: Binding(
                    get: { showTierInfo == tier },
                    set: { if !$0 { showTierInfo = nil } }
                ), arrowEdge: .top) {
                    Text(tier.description)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .presentationCompactAdaptation(.popover)
                }
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
                SpectrumFillButton(
                    title: "Start my plan (\(includedCount))",
                    disabled: includedCount == 0,
                    action: onConfirm
                )
                .opacity(includedCount > 0 ? 1.0 : 0.4)
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

    private func setUserDosage(_ id: UUID, mg: Double?) {
        if let index = viewModel.generatedPlan?.supplements.firstIndex(where: { $0.id == id }) {
            viewModel.generatedPlan?.supplements[index].userOverriddenDosageMg = mg
        }
    }

    private func dosageBinding(for supplement: PlanSupplement) -> Binding<Double?> {
        Binding(
            get: { supplement.userOverriddenDosageMg },
            set: { setUserDosage(supplement.id, mg: $0) }
        )
    }

    // MARK: - Product Loading

    private func loadProducts(for supplement: PlanSupplement) {
        guard let supplementId = supplement.supplementId else {
            print("[Products] No supplementId for \(supplement.name)")
            return
        }
        guard productsBySupplementId[supplementId] == nil,
              !loadingProductIds.contains(supplementId) else {
            print("[Products] Already cached/loading for \(supplement.name) (\(supplementId))")
            return
        }

        print("[Products] Fetching for \(supplement.name) (\(supplementId))")
        loadingProductIds.insert(supplementId)

        Task {
            do {
                let service = SupplementService()
                let fetched = try await service.fetchProducts(forSupplementId: supplementId)
                print("[Products] Got \(fetched.count) products for \(supplement.name)")
                await MainActor.run {
                    productsBySupplementId[supplementId] = fetched
                    loadingProductIds.remove(supplementId)
                }
            } catch {
                print("[Products] Error for \(supplement.name): \(error)")
                await MainActor.run {
                    productsBySupplementId[supplementId] = []
                    loadingProductIds.remove(supplementId)
                }
            }
        }
    }

    // MARK: - Entrance Animation

    @MainActor
    private func startEntranceAnimation() async {
        let fadeDuration: Double = reduceMotion ? 0.15 : 0.4

        // Background + particles
        withAnimation(.easeOut(duration: reduceMotion ? 0.1 : 0.3)) {
            showBackground = true
        }

        // Headline
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.3))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showHeadline = true
        }
        HapticManager.notification(.success)

        // Subtitle + SpectrumBar
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.3))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showSubtitle = true
        }
        await startCountAnimation()

        // Plan summary
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.2))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: fadeDuration)) {
            showSummary = true
        }

        // Stop shimmer after 2.5s (fire-and-forget child task)
        if !reduceMotion {
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    showShimmer = false
                }
            }
        }

        // Goal chips staggered
        let chipInterval: Double = reduceMotion ? 0.03 : 0.08
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.02 : 0.3))
        for i in 0..<userGoals.count {
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: fadeDuration)) {
                visibleGoalChips = i + 1
            }
            try? await Task.sleep(for: .seconds(chipInterval))
        }

        // Tier headers + cards
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.4))
        for tier in tiers {
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: fadeDuration)) {
                showTierHeaders[tier] = true
            }
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.05 : 0.2))

            let tierSupplements = supplements.filter { $0.tier == tier }
            let cardInterval: Double = tier == .supporting ? 0.08 : 0.15
            for supplement in tierSupplements {
                guard !Task.isCancelled else { return }
                if let globalIndex = supplements.firstIndex(where: { $0.id == supplement.id }) {
                    withAnimation(.easeOut(duration: fadeDuration)) {
                        visibleCards = globalIndex + 1
                    }
                }
                try? await Task.sleep(for: .seconds(reduceMotion ? 0.03 : cardInterval))
            }
        }

        // CTA slides up after last card
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.1 : 0.4))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showCTA = true
        }
    }

    // MARK: - Count Animation

    @MainActor
    private func startCountAnimation() async {
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
            try? await Task.sleep(for: .seconds(stepInterval))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                animatedSupplementCount = i
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


// MARK: - Spectrum Fill Button

private struct SpectrumFillButton: View {
    let title: String
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            guard !disabled else { return }
            HapticManager.impact(.light)
            HapticManager.notification(.success)
            action()
        } label: {
            Text(title)
                .font(DesignTokens.ctaFont)
                .tracking(0.32)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(DesignTokens.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(CTAPressStyle())
        .disabled(disabled)
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

// MARK: - One-Shot Shimmer

private struct OneShotShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let bandWidth = width * 0.5

                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.7), location: 0.35),
                                .init(color: .white.opacity(0.7), location: 0.65),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: bandWidth)
                        .offset(x: -bandWidth + phase * (width + bandWidth))
                    }
                    .mask(content)
                }
                .onAppear {
                    withAnimation(.linear(duration: 2.5)) {
                        phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    let appState = AppState()
    appState.supplementCatalog.populateFromStatic()
    return PlanRevealScreen(
        viewModel: {
            let vm = OnboardingViewModel()
            vm.firstName = ""
            vm.healthGoals = [.sleep, .energy, .focus, .stressAnxiety]

            let engine = RecommendationEngine(catalog: appState.supplementCatalog)
            let profile = vm.buildUserProfile()
            vm.generatedPlan = engine.generatePlan(for: profile)

            return vm
        }(),
        onConfirm: {}
    )
    .environment(appState)
}
