import SwiftUI

struct PlanScreen: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PlanViewModel()
    @State private var isOverviewExpanded = true
    @State private var showAddSheet = false
    @State private var showUndoToast = false
    @State private var undoMessage = ""
    @State private var expandedCardId: UUID?
    @State private var isRemovedExpanded = false

    private var userGoals: [HealthGoal] {
        appState.currentUser?.healthGoals.sorted { $0.rawValue < $1.rawValue } ?? []
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
                    // Header
                    planHeader

                    if viewModel.activePlan != nil {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
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

                            // Removed section
                            if !viewModel.removedSupplements.isEmpty {
                                removedSection
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
                        }
                        .lockedOverlay(
                            title: "Your Plan",
                            subtitle: "Subscribe to see your full supplement plan"
                        )
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
                SupplementCardView(
                    supplement: supplement,
                    trailingAccessory: .goalChips(userGoals),
                    expansionMode: .inline,
                    detailLevel: .full,
                    menuActions: [
                        SupplementCardMenuAction("Remove from Plan", icon: "trash", role: .destructive) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.removeSupplement(supplement)
                                undoMessage = "\(supplement.name) removed"
                                showUndoToast = true
                            }
                        }
                    ],
                    isExpanded: expandedCardId == supplement.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedCardId = expandedCardId == supplement.id ? nil : supplement.id
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Removed Section

    private var removedSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRemovedExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text("REMOVED")
                        .font(DesignTokens.sectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text("\(viewModel.removedSupplements.count)")
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.textTertiary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                        .rotationEffect(.degrees(isRemovedExpanded ? 0 : -90))
                }
            }
            .buttonStyle(.plain)

            if isRemovedExpanded {
                ForEach(viewModel.removedSupplements) { supplement in
                    SupplementCardView(
                        supplement: supplement,
                        trailingAccessory: .goalChips(userGoals),
                        expansionMode: .inline,
                        detailLevel: .full,
                        menuActions: [
                            SupplementCardMenuAction("Restore to Plan", icon: "arrow.uturn.backward", role: nil) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.restoreSupplement(supplement)
                                }
                                HapticManager.notification(.success)
                            }
                        ],
                        isIncluded: false,
                        isExpanded: expandedCardId == supplement.id,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedCardId = expandedCardId == supplement.id ? nil : supplement.id
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
        }
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

#Preview {
    let appState = AppState()
    var user = UserProfile(firstName: "Matt")
    user.healthGoals = [.sleep, .energy, .focus]
    appState.currentUser = user
    appState.isOnboardingComplete = true

    let engine = RecommendationEngine()
    appState.activePlan = engine.generatePlan(for: user)

    return PlanScreen()
        .environment(appState)
}
