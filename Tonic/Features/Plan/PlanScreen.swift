import SwiftUI

struct PlanScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PlanViewModel()
    @State private var selectedSupplement: PlanSupplement?
    @State private var isOverviewExpanded = true
    @State private var showAddSheet = false
    @State private var showUndoToast = false
    @State private var undoMessage = ""

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
                    // Header
                    planHeader

                    if viewModel.activePlan != nil {
                        // Plan overview (collapsible)
                        if let reasoning = viewModel.activePlan?.aiReasoning {
                            planReasoningCard(reasoning: reasoning)
                        }

                        // Morning section
                        if !viewModel.morningSupplements.isEmpty {
                            supplementSection(title: "MORNING", icon: "sun.max.fill", tint: DesignTokens.accentEnergy, supplements: viewModel.morningSupplements)
                        }

                        // Evening section
                        if !viewModel.eveningSupplements.isEmpty {
                            supplementSection(title: "EVENING", icon: "moon.fill", tint: DesignTokens.accentSleep, supplements: viewModel.eveningSupplements)
                        }

                        // Explore / add supplements CTA
                        Button {
                            HapticManager.selection()
                            showAddSheet = true
                        } label: {
                            HStack(spacing: DesignTokens.spacing8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 15))
                                Text("Add Supplements to Your Plan")
                                    .font(DesignTokens.bodyFont)
                            }
                            .foregroundStyle(DesignTokens.positive)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(DesignTokens.positive.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                    .stroke(DesignTokens.positive.opacity(0.25), lineWidth: 1)
                            )
                        }

                        // Disclaimer
                        HStack(alignment: .top, spacing: DesignTokens.spacing8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(DesignTokens.textSecondary)
                                .padding(.top, 2)

                            Text("This plan is informational, not medical advice. Always consult your doctor before taking anything new.")
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .lineSpacing(2)
                        }
                        .padding(.top, DesignTokens.spacing4)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, DesignTokens.spacing32)
            }

            // Undo toast overlay
            if showUndoToast {
                VStack {
                    Spacer()
                    UndoToast(
                        message: undoMessage,
                        onUndo: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.undoRemoval()
                            }
                            HapticManager.notification(.success)
                        },
                        isPresented: $showUndoToast
                    )
                    .padding(.bottom, DesignTokens.spacing48)
                }
                .animation(.easeInOut(duration: 0.3), value: showUndoToast)
            }
        }
        .onAppear {
            viewModel.load(appState: appState)
        }
        .sheet(item: $selectedSupplement) { supplement in
            SupplementDetailSheet(supplement: supplement) { removed in
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.removeSupplement(removed)
                    undoMessage = "\(removed.name) removed"
                    showUndoToast = true
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            if let profile = appState.currentUser {
                AddSupplementSheet(
                    profile: profile,
                    existingSupplements: viewModel.activePlan?.supplements ?? []
                ) { newSupplements in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.addSupplements(newSupplements)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var planHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                Text("\(viewModel.userName)'s Supplement Plan")
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)

                if viewModel.activePlan != nil {
                    Text("\(viewModel.planDateString.uppercased())\(viewModel.planVersionLabel)")
                        .font(DesignTokens.labelMono)
                        .tracking(1.2)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                SpectrumBar(height: 2)
                    .padding(.top, DesignTokens.spacing4)
            }

        }
        .padding(.top, DesignTokens.spacing8)
    }

    // MARK: - Supplement Section

    private func supplementSection(title: String, icon: String, tint: Color, supplements: [PlanSupplement]) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(tint)

                Text(title)
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)
            }

            ForEach(supplements) { supplement in
                Button {
                    selectedSupplement = supplement
                } label: {
                    planSupplementRow(supplement: supplement)
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
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
        VStack(alignment: .leading, spacing: isOverviewExpanded ? DesignTokens.spacing12 : 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isOverviewExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.textSecondary)

                        Text("PLAN OVERVIEW")
                            .font(DesignTokens.sectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                        .rotationEffect(.degrees(isOverviewExpanded ? 0 : -90))
                }
            }
            .buttonStyle(.plain)

            if isOverviewExpanded {
                Text(reasoning)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
    var onRemove: ((PlanSupplement) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showRemoveConfirmation = false

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

                    // Remove button
                    if onRemove != nil {
                        Button {
                            HapticManager.impact(.medium)
                            showRemoveConfirmation = true
                        } label: {
                            HStack(spacing: DesignTokens.spacing8) {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Remove from Plan")
                                    .font(DesignTokens.ctaFont)
                            }
                            .foregroundStyle(DesignTokens.negative)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(DesignTokens.negative.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                    .stroke(DesignTokens.negative.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.top, DesignTokens.spacing8)
                    }
                }
                .padding(DesignTokens.spacing20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert(
            "Remove \(supplement.name)?",
            isPresented: $showRemoveConfirmation
        ) {
            Button("Remove", role: .destructive) {
                onRemove?(supplement)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let goals = supplement.matchedGoals
                .compactMap { key in HealthGoal(rawValue: key)?.shortLabel }
                .joined(separator: " and ")
            let goalsText = goals.isEmpty ? "" : "This supplement was recommended for your \(goals) goals. "
            Text("\(goalsText)It was categorized as \(supplement.tier.label) in your plan.")
        }
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
