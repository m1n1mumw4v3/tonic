import SwiftUI

struct PlanScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PlanViewModel()
    @State private var selectedSupplement: PlanSupplement?

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
                    // Header
                    planHeader

                    if viewModel.activePlan != nil {
                        // Morning section
                        if !viewModel.morningSupplements.isEmpty {
                            supplementSection(title: "MORNING", supplements: viewModel.morningSupplements)
                        }

                        // Evening section
                        if !viewModel.eveningSupplements.isEmpty {
                            supplementSection(title: "EVENING", supplements: viewModel.eveningSupplements)
                        }

                        // Overall plan reasoning
                        if let reasoning = viewModel.activePlan?.aiReasoning {
                            planReasoningCard(reasoning: reasoning)
                        }

                        // Disclaimer
                        Text("This plan is informational, not medical advice.")
                            .font(.custom("GeistMono-Regular", size: 9))
                            .foregroundStyle(DesignTokens.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, DesignTokens.spacing8)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, DesignTokens.spacing32)
            }
        }
        .onAppear {
            viewModel.load(appState: appState)
        }
        .sheet(item: $selectedSupplement) { supplement in
            SupplementDetailSheet(supplement: supplement)
        }
    }

    // MARK: - Header

    private var planHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            Text("\(viewModel.userName)'s Supplement Plan")
                .font(DesignTokens.headlineFont)
                .foregroundStyle(DesignTokens.textPrimary)

            if let plan = viewModel.activePlan {
                HStack(spacing: DesignTokens.spacing8) {
                    Text("v\(plan.version)".uppercased())
                        .font(DesignTokens.labelMono)
                        .tracking(1.2)
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text("·")
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text(viewModel.planDateString.uppercased())
                        .font(DesignTokens.labelMono)
                        .tracking(1.2)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }

            SpectrumBar(height: 2)
                .padding(.top, DesignTokens.spacing4)
        }
        .padding(.top, DesignTokens.spacing8)
    }

    // MARK: - Supplement Section

    private func supplementSection(title: String, supplements: [PlanSupplement]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Text(title)
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            ForEach(supplements) { supplement in
                Button {
                    selectedSupplement = supplement
                } label: {
                    planSupplementRow(supplement: supplement)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func planSupplementRow(supplement: PlanSupplement) -> some View {
        HStack(spacing: DesignTokens.spacing12) {
            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                Text(supplement.name)
                    .font(DesignTokens.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.textPrimary)

                Text(supplement.dosage)
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(DesignTokens.info)
            }

            Spacer()

            // Category badge
            Text(supplement.category.uppercased())
                .font(DesignTokens.labelMono)
                .tracking(1.0)
                .foregroundStyle(DesignTokens.textTertiary)
                .padding(.horizontal, DesignTokens.spacing8)
                .padding(.vertical, DesignTokens.spacing4)
                .background(DesignTokens.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(DesignTokens.spacing12)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Plan Reasoning

    private func planReasoningCard(reasoning: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Text("PLAN OVERVIEW")
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            Text(reasoning)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .lineSpacing(4)
        }
        .cardStyle()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignTokens.spacing16) {
            Image(systemName: "pill.fill")
                .font(.system(size: 48))
                .foregroundStyle(DesignTokens.textTertiary)
            Text("No plan yet")
                .font(DesignTokens.headlineFont)
                .foregroundStyle(DesignTokens.textPrimary)
            Text("Complete onboarding to generate your personalized supplement plan")
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignTokens.spacing48)
    }
}

// MARK: - Supplement Detail Sheet

struct SupplementDetailSheet: View {
    let supplement: PlanSupplement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                            Text(supplement.name)
                                .font(DesignTokens.titleFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                            Text(supplement.dosage)
                                .font(DesignTokens.dataMono)
                                .foregroundStyle(DesignTokens.info)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(DesignTokens.textTertiary)
                        }
                    }

                    SpectrumBar(height: 2)

                    // Timing
                    detailRow(label: "TIMING", value: supplement.timing.label)

                    // Category
                    detailRow(label: "CATEGORY", value: supplement.category.capitalized)

                    // AI Reasoning
                    if let reasoning = supplement.reasoning {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                            Text("WHY THIS IS IN YOUR PLAN")
                                .font(DesignTokens.sectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(DesignTokens.textSecondary)

                            Text(reasoning)
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .lineSpacing(4)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                            Text("WHY THIS IS IN YOUR PLAN")
                                .font(DesignTokens.sectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(DesignTokens.textSecondary)

                            Text("AI-generated explanation will appear here once connected to the backend.")
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textTertiary)
                                .italic()
                        }
                    }

                    // Knowledge base notes
                    if let kb = SupplementKnowledgeBase.supplement(named: supplement.name) {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                            Text("RESEARCH NOTES")
                                .font(DesignTokens.sectionHeader)
                                .tracking(1.5)
                                .foregroundStyle(DesignTokens.textSecondary)

                            Text(kb.notes)
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(DesignTokens.spacing20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.labelMono)
                .tracking(1.2)
                .foregroundStyle(DesignTokens.textTertiary)
            Spacer()
            Text(value)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)
        }
    }
}

#Preview {
    let appState = AppState()
    appState.currentUser = UserProfile(firstName: "Matt")
    appState.isOnboardingComplete = true

    let engine = RecommendationEngine()
    var profile = UserProfile()
    profile.healthGoals = [.sleep, .energy, .focus]
    appState.activePlan = engine.generatePlan(for: profile)

    return PlanScreen()
        .environment(appState)
}
