import SwiftUI

struct DeepProfileHub: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = DeepProfileHubViewModel()
    @State private var appearedRows: Set<String> = []
    @State private var showBaselineProfile = false

    private var service: DeepProfileService {
        appState.deepProfileService
    }

    private var userGoals: [HealthGoal] {
        appState.currentUser?.healthGoals ?? []
    }

    private var isAllComplete: Bool {
        service.isComplete
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacing16) {
                    // Header
                    header
                        .padding(.top, DesignTokens.spacing8)

                    // Spectrum progress bar
                    SpectrumBar(progress: service.completionProgress)
                        .frame(height: 3)

                    // General Profile
                    generalProfileRow

                    // Module sections
                    if isAllComplete {
                        // Flat list when all done
                        moduleList(DeepProfileModuleType.allCases.map { $0 }, header: nil)
                    } else {
                        let grouped = viewModel.groupedModules(service: service, userGoals: userGoals)

                        if !grouped.recommended.isEmpty {
                            moduleList(grouped.recommended, header: "RECOMMENDED FOR YOU")
                        }

                        moduleList(grouped.other, header: grouped.recommended.isEmpty ? nil : "ALL MODULES")
                    }
                }
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.bottom, DesignTokens.spacing32)
            }

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DesignTokens.bgElevated)
                    .clipShape(Circle())
            }
            .padding(.top, DesignTokens.spacing12)
            .padding(.trailing, DesignTokens.spacing16)
        }
        .sheet(item: $viewModel.selectedModule) { moduleType in
            DeepProfileModuleFlow(moduleType: moduleType)
                .environment(appState)
        }
        .sheet(isPresented: $showBaselineProfile) {
            if let profile = appState.currentUser {
                BaselineProfileSheet(
                    viewModel: BaselineProfileViewModel(profile: profile),
                    onSave: handleBaselineProfileSave
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
            Text(isAllComplete ? "Profile Complete" : "Health Profile")
                .font(DesignTokens.headlineFont)
                .foregroundStyle(DesignTokens.textPrimary)

            Text(isAllComplete
                 ? "Your profile is fully built. Recommendations are at peak personalization."
                 : "Complete modules to refine your supplement plan.")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.trailing, DesignTokens.spacing32) // room for xmark
    }

    // MARK: - General Profile Row

    private var generalProfileRow: some View {
        Button {
            HapticManager.impact(.light)
            showBaselineProfile = true
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                        .fill(DesignTokens.accentEnergy.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DesignTokens.accentEnergy)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spacing2) {
                    Text("General Profile")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text("Completed")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.positive)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DesignTokens.positive)
            }
            .padding(DesignTokens.spacing12)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Baseline Profile Save

    private func handleBaselineProfileSave(updatedProfile: UserProfile, needsRegeneration: Bool) {
        appState.currentUser = updatedProfile

        let storage = LocalStorageService()
        try? storage.saveProfile(updatedProfile)

        if needsRegeneration {
            let engine = RecommendationEngine()
            let newPlan = engine.generatePlan(for: updatedProfile)
            appState.activePlan = newPlan
            try? storage.savePlan(newPlan)
        }
    }

    // MARK: - Module List

    private func moduleList(_ modules: [DeepProfileModuleType], header: String?) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            if let header {
                Text(header)
                    .font(DesignTokens.sectionHeader)
                    .foregroundStyle(DesignTokens.textTertiary)
                    .tracking(1.0)
                    .padding(.top, DesignTokens.spacing8)
            }

            ForEach(Array(modules.enumerated()), id: \.element.id) { index, moduleType in
                moduleRow(for: moduleType)
                    .opacity(appearedRows.contains(moduleType.id) ? 1 : 0)
                    .offset(y: appearedRows.contains(moduleType.id) ? 0 : 8)
                    .onAppear {
                        let delay = Double(index) * 0.04
                        let _ = withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                            appearedRows.insert(moduleType.id)
                        }
                    }
            }
        }
    }

    // MARK: - Module Row

    private func moduleRow(for moduleType: DeepProfileModuleType) -> some View {
        let isCompleted = service.isModuleCompleted(moduleType)
        let isRecommended = viewModel.isRecommended(moduleType, userGoals: userGoals)

        return Button {
            HapticManager.impact(.light)
            viewModel.selectedModule = moduleType
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                        .fill(moduleType.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: moduleType.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(moduleType.accentColor)
                }

                // Text
                VStack(alignment: .leading, spacing: DesignTokens.spacing2) {
                    Text(moduleType.displayName)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    if isRecommended && !isCompleted {
                        Text("Recommended")
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(DesignTokens.accentEnergy)
                            .padding(.horizontal, DesignTokens.spacing4)
                            .padding(.vertical, 2)
                            .background(DesignTokens.accentEnergy.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text(isCompleted ? "Completed" : "\(moduleType.questionCount) questions \u{00B7} \(moduleType.estimatedTimeLabel)")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(isCompleted ? DesignTokens.positive : DesignTokens.textTertiary)
                }

                Spacer()

                // Status indicator
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignTokens.positive)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
            .padding(DesignTokens.spacing12)
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
