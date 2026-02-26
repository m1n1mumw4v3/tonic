import SwiftUI

// MARK: - View Model

@Observable
class AddSupplementViewModel {
    var recommendations: [Supplement] = []
    var otherSupplements: [Supplement] = []
    var excludedSupplementNames: Set<String> = []
    var planSupplementNames: Set<String> = []

    func load(profile: UserProfile, existingSupplements: [PlanSupplement], catalog: SupplementCatalog) {
        let engine = RecommendationEngine(catalog: catalog)
        let medicationKeywords = engine.extractMedicationKeywords(from: profile)
        excludedSupplementNames = engine.findExcludedSupplements(
            medications: medicationKeywords,
            allergies: profile.allergies,
            profile: profile
        )

        planSupplementNames = Set(existingSupplements.map(\.name))

        let userGoalKeys = Set(profile.healthGoals.map(\.rawValue))

        // Score all catalog supplements by evidence weight
        var scored: [(supplement: Supplement, score: Int)] = []
        for supplement in catalog.allSupplements {
            let weightedScore = userGoalKeys.reduce(0) { sum, goalKey in
                sum + catalog.weight(for: supplement.name, goal: goalKey)
            }
            scored.append((supplement, weightedScore))
        }

        // Split into recommended (score > 0) and other (score == 0)
        let goalMatched = scored
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map(\.supplement)

        let noGoalMatch = scored
            .filter { $0.score == 0 }
            .map(\.supplement)

        recommendations = goalMatched
        otherSupplements = noGoalMatch
    }

    func matchedGoals(for supplement: Supplement, profile: UserProfile, catalog: SupplementCatalog) -> [HealthGoal] {
        let userGoalKeys = Set(profile.healthGoals.map(\.rawValue))
        let matched = userGoalKeys.filter { goalKey in
            catalog.goalMappings(for: goalKey).contains { $0.name == supplement.name }
        }
        return profile.healthGoals.filter { matched.contains($0.rawValue) }
    }
}

// MARK: - Add Supplement Sheet

struct AddSupplementSheet: View {
    let profile: UserProfile
    let existingSupplements: [PlanSupplement]
    let onAdd: ([PlanSupplement]) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var viewModel = AddSupplementViewModel()
    @State private var selectedTab = 0
    @State private var stagedSupplements: Set<UUID> = []
    @State private var searchText = ""

    private var catalog: SupplementCatalog { appState.supplementCatalog }

    private var filteredGroups: [(category: String, label: String, supplements: [Supplement])] {
        if searchText.isEmpty {
            return catalog.supplementsByCategory
        }
        let query = searchText.lowercased()
        return catalog.supplementsByCategory.compactMap { group in
            let filtered = group.supplements.filter { $0.name.lowercased().contains(query) }
            guard !filtered.isEmpty else { return nil }
            return (category: group.category, label: group.label, supplements: filtered)
        }
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Add to Your Plan")
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.top, DesignTokens.spacing20)
                .padding(.bottom, DesignTokens.spacing16)

                // Segmented picker
                Picker("Tab", selection: $selectedTab) {
                    Text("Recommended").tag(0)
                    Text("Browse All").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.bottom, DesignTokens.spacing16)

                // Content
                if selectedTab == 0 {
                    recommendedTab
                } else {
                    browseTab
                }
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            viewModel.load(profile: profile, existingSupplements: existingSupplements, catalog: catalog)
        }
    }

    // MARK: - Recommended Tab

    private var recommendedTab: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.spacing8) {
                if !viewModel.recommendations.isEmpty {
                    ForEach(viewModel.recommendations) { supplement in
                        recommendationCard(for: supplement)
                    }
                }

                if !viewModel.otherSupplements.isEmpty {
                    Text("OTHER SUPPLEMENTS")
                        .font(DesignTokens.sectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, DesignTokens.spacing12)

                    ForEach(viewModel.otherSupplements) { supplement in
                        recommendationCard(for: supplement)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.bottom, stagedSupplements.isEmpty ? DesignTokens.spacing32 : 100)
        }
        .overlay(alignment: .bottom) {
            ctaOverlay
        }
    }

    // MARK: - Browse Tab

    private var browseTab: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: DesignTokens.spacing8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignTokens.textTertiary)

                TextField("Search supplements...", text: $searchText)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
            }
            .padding(DesignTokens.spacing12)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.bottom, DesignTokens.spacing16)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredGroups, id: \.category) { group in
                        Text(group.label.uppercased())
                            .font(DesignTokens.sectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .padding(.horizontal, DesignTokens.spacing20)
                            .padding(.top, DesignTokens.spacing16)
                            .padding(.bottom, DesignTokens.spacing8)

                        ForEach(group.supplements) { supplement in
                            recommendationCard(for: supplement)
                                .padding(.horizontal, DesignTokens.spacing20)
                                .padding(.bottom, DesignTokens.spacing8)
                        }
                    }
                }
                .padding(.bottom, stagedSupplements.isEmpty ? DesignTokens.spacing32 : 100)
            }
            .overlay(alignment: .bottom) {
                ctaOverlay
            }
        }
    }

    // MARK: - Shared Card

    private func recommendationCard(for supplement: Supplement) -> some View {
        let isInPlan = viewModel.planSupplementNames.contains(supplement.name)
        let isExcluded = viewModel.excludedSupplementNames.contains(supplement.name)
        let isSelected = stagedSupplements.contains(supplement.id)
        let goals = viewModel.matchedGoals(for: supplement, profile: profile, catalog: catalog)

        return RecommendationCard(
            supplement: supplement,
            matchedGoals: goals,
            isSelected: isSelected,
            isInPlan: isInPlan,
            isExcluded: isExcluded
        ) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    stagedSupplements.remove(supplement.id)
                } else {
                    stagedSupplements.insert(supplement.id)
                }
            }
        }
    }

    // MARK: - CTA Overlay

    @ViewBuilder
    private var ctaOverlay: some View {
        if !stagedSupplements.isEmpty {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, DesignTokens.bgDeepest],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
                .allowsHitTesting(false)

                let count = stagedSupplements.count
                CTAButton(
                    title: "Add \(count) Supplement\(count == 1 ? "" : "s") to Plan",
                    style: .primary,
                    action: {
                        let engine = RecommendationEngine(catalog: catalog)
                        let newSupplements = stagedSupplements.compactMap { id -> PlanSupplement? in
                            guard let supplement = catalog.supplement(byId: id) else { return nil }
                            return engine.buildPlanSupplement(from: supplement, for: profile, existingSupplements: existingSupplements)
                        }
                        HapticManager.notification(.success)
                        onAdd(newSupplements)
                        dismiss()
                    },
                    spectrumBorder: true
                )
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.bottom, DesignTokens.spacing8)
                .background(DesignTokens.bgDeepest)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.2), value: stagedSupplements.count)
        }
    }
}
