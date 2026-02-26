import SwiftUI

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(KnowledgeBaseProvider.self) private var kb
    @State private var hubViewModel = DeepProfileHubViewModel()
    @State private var showBaselineProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bgDeepest.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // User header
                        userHeader

                        // Health Profile section
                        healthProfileSection

                        // Other settings (placeholders)
                        settingsSection(title: "ACCOUNT") {
                            settingsRow(icon: "person.circle", label: "Profile")
                            settingsRow(icon: "creditcard", label: "Subscription")
                        }

                        settingsSection(title: "PREFERENCES") {
                            settingsRow(icon: "bell", label: "Notifications")
                            settingsRow(icon: "heart.text.square", label: "Apple Health")
                        }

                        settingsSection(title: "ABOUT") {
                            settingsRow(icon: "doc.text", label: "Privacy Policy")
                            settingsRow(icon: "doc.text", label: "Terms of Service")
                            settingsRow(icon: "info.circle", label: "Version 1.0.0")
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing16)
                    .padding(.bottom, DesignTokens.spacing32)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - User Header

    private var userHeader: some View {
        VStack(spacing: DesignTokens.spacing8) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(DesignTokens.bgElevated)
                    .frame(width: 64, height: 64)

                Text(appState.userName.prefix(1).uppercased())
                    .font(DesignTokens.headlineFont)
                    .foregroundStyle(DesignTokens.textPrimary)
            }

            Text(appState.userName)
                .font(DesignTokens.titleFont)
                .foregroundStyle(DesignTokens.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignTokens.spacing16)
    }

    // MARK: - Health Profile

    private var healthProfileSection: some View {
        let service = appState.deepProfileService

        let baselineAdjustedProgress = Double(service.completedCount + 1) / Double(service.totalCount + 1)

        return VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                Text("HEALTH PROFILE")
                    .font(DesignTokens.sectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(DesignTokens.textSecondary)

                Text("Answer a few questions to sharpen your plan.")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textTertiary)
            }

            // Progress summary
            HStack(spacing: DesignTokens.spacing8) {
                SpectrumBar(progress: baselineAdjustedProgress)
                    .frame(height: 3)

                Text("\(service.completedCount + 1) of \(service.totalCount + 1) modules")
                    .font(DesignTokens.labelMono)
                    .foregroundStyle(DesignTokens.textTertiary)
            }

            // Baseline profile (always complete — from onboarding)
            baselineProfileRow

            // Module list
            ForEach(hubViewModel.orderedModules(
                service: service,
                userGoals: appState.currentUser?.healthGoals ?? []
            )) { moduleType in
                settingsModuleRow(for: moduleType)
            }
        }
        .sheet(item: $hubViewModel.selectedModule) { moduleType in
            DeepProfileModuleFlow(moduleType: moduleType)
                .environment(appState)
        }
    }

    private var baselineProfileRow: some View {
        Button {
            showBaselineProfile = true
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                Image(systemName: "person.text.rectangle")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 24)

                HStack(spacing: DesignTokens.spacing4) {
                    Text("Baseline Profile")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.positive)
            }
            .padding(.vertical, DesignTokens.spacing12)
            .padding(.horizontal, DesignTokens.spacing16)
        }
        .buttonStyle(.plain)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .sheet(isPresented: $showBaselineProfile) {
            if let profile = appState.currentUser {
                BaselineProfileSheet(
                    viewModel: BaselineProfileViewModel(profile: profile),
                    onSave: handleBaselineProfileSave
                )
                .environment(kb)
            }
        }
    }

    // MARK: - Baseline Profile Save Handler

    private func handleBaselineProfileSave(updatedProfile: UserProfile, needsRegeneration: Bool) {
        appState.currentUser = updatedProfile

        let storage = LocalStorageService()
        try? storage.saveProfile(updatedProfile)

        if needsRegeneration {
            let engine = RecommendationEngine(kb: kb)
            let newPlan = engine.generatePlan(for: updatedProfile)
            appState.activePlan = newPlan
            try? storage.savePlan(newPlan)
        }
    }

    private func settingsModuleRow(for moduleType: DeepProfileModuleType) -> some View {
        let isCompleted = appState.deepProfileService.isModuleCompleted(moduleType)

        return Button {
            hubViewModel.selectedModule = moduleType
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                Image(systemName: moduleType.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(moduleType.accentColor)
                    .frame(width: 24)

                HStack(spacing: DesignTokens.spacing4) {
                    Text(moduleType.displayName)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.positive)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.textTertiary.opacity(0.4))
                }
            }
            .padding(.vertical, DesignTokens.spacing12)
            .padding(.horizontal, DesignTokens.spacing16)
        }
        .buttonStyle(.plain)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Generic Settings Helpers

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            Text(title)
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            VStack(spacing: 0) {
                content()
            }
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
        }
    }

    private func settingsRow(icon: String, label: String) -> some View {
        HStack(spacing: DesignTokens.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DesignTokens.textTertiary)
        }
        .padding(.vertical, DesignTokens.spacing12)
        .padding(.horizontal, DesignTokens.spacing16)
    }
}
