import SwiftUI

struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var hubViewModel = DeepProfileHubViewModel()
    @State private var showBaselineProfile = false
    @State private var showNotificationSettings = false
    @State private var isHealthKitConnecting = false
    @State private var showHealthKitUnavailable = false
    @State private var showSignOutConfirmation = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bgDeepest.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // User header with close button overlay
                        ZStack(alignment: .topTrailing) {
                            userHeader

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
                        }

                        // Health Profile section
                        healthProfileSection

                        // Other settings (placeholders)
                        settingsSection(title: "ACCOUNT") {
                            settingsRow(icon: "person.circle", label: "Profile")
                            settingsRow(icon: "creditcard", label: "Subscription")

                            Button { showSignOutConfirmation = true } label: {
                                HStack(spacing: DesignTokens.spacing12) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16))
                                        .foregroundStyle(DesignTokens.negative)
                                        .frame(width: 24)

                                    Text("Sign out")
                                        .font(DesignTokens.bodyFont)
                                        .foregroundStyle(DesignTokens.negative)

                                    Spacer()
                                }
                                .padding(.vertical, DesignTokens.spacing12)
                                .padding(.horizontal, DesignTokens.spacing16)
                            }
                            .buttonStyle(.plain)
                        }

                        settingsSection(title: "PREFERENCES") {
                            Button { showNotificationSettings = true } label: {
                                settingsRow(icon: "bell", label: "Notifications")
                            }
                            .buttonStyle(.plain)
                            appleHealthRow
                        }

                        settingsSection(title: "ABOUT") {
                            settingsRow(icon: "doc.text", label: "Privacy Policy")
                            settingsRow(icon: "doc.text", label: "Terms of Service")
                            settingsRow(icon: "info.circle", label: "Version 1.0.0")
                        }
                    }
                    .padding(.horizontal, DesignTokens.screenMargin)
                    .padding(.bottom, DesignTokens.spacing32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotificationSettings) {
                if let profile = appState.currentUser {
                    NotificationSettingsSheet(profile: profile)
                        .environment(appState)
                }
            }
            .alert("Apple Health Unavailable", isPresented: $showHealthKitUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Apple Health is not available on this device.")
            }
            .alert("Sign out?", isPresented: $showSignOutConfirmation) {
                Button("Sign out", role: .destructive) {
                    Task { await appState.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to access your plan and data.")
            }
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

            if isEditingName {
                HStack(alignment: .center, spacing: DesignTokens.spacing4) {
                    TextField("Name", text: $editedName)
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .fixedSize()
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            saveName()
                        }
                        .onChange(of: nameFieldFocused) { _, focused in
                            if !focused {
                                saveName()
                            }
                        }

                    Button {
                        saveName()
                    } label: {
                        Text("SAVE")
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(DesignTokens.positive)
                            .padding(.horizontal, DesignTokens.spacing8)
                            .padding(.vertical, DesignTokens.spacing4)
                            .background(DesignTokens.positive.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: editedName)
            } else {
                HStack(spacing: DesignTokens.spacing4) {
                    Text(appState.userName)
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .onTapGesture {
                    editedName = appState.userName
                    isEditingName = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        nameFieldFocused = true
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignTokens.spacing12)
    }

    private func saveName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            appState.currentUser?.firstName = trimmed
            if let profile = appState.currentUser {
                try? LocalStorageService().saveProfile(profile)
            }
        }
        isEditingName = false
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
            }
        }
    }

    // MARK: - Apple Health Row

    private var appleHealthRow: some View {
        let isConnected = appState.currentUser?.healthKitEnabled == true

        return Button {
            Task { await toggleHealthKit() }
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 24)

                Text("Apple Health")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)

                Spacer()

                if isHealthKitConnecting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(isConnected ? "Connected" : "Off")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(isConnected ? DesignTokens.positive : DesignTokens.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .padding(.vertical, DesignTokens.spacing12)
            .padding(.horizontal, DesignTokens.spacing16)
        }
        .buttonStyle(.plain)
        .disabled(isHealthKitConnecting)
    }

    private func toggleHealthKit() async {
        let isCurrentlyConnected = appState.currentUser?.healthKitEnabled == true

        if isCurrentlyConnected {
            // Disconnect
            appState.currentUser?.healthKitEnabled = false
            appState.currentUser?.healthMetrics = nil
            if let profile = appState.currentUser {
                try? LocalStorageService().saveProfile(profile)
            }
        } else {
            guard HealthKitService.isAvailable else {
                showHealthKitUnavailable = true
                return
            }

            isHealthKitConnecting = true
            defer { isHealthKitConnecting = false }

            let authorized = await appState.healthKitService.requestAuthorization()
            guard authorized else {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    await UIApplication.shared.open(url)
                }
                return
            }

            appState.currentUser?.healthKitEnabled = true
            let metrics = await appState.healthKitService.fetchAllMetrics()
            appState.currentUser?.healthMetrics = metrics

            if let profile = appState.currentUser {
                try? LocalStorageService().saveProfile(profile)
            }
        }
    }

    // MARK: - Baseline Profile Save Handler

    private func handleBaselineProfileSave(updatedProfile: UserProfile, needsRegeneration: Bool) {
        appState.currentUser = updatedProfile

        let storage = LocalStorageService()
        try? storage.saveProfile(updatedProfile)

        if needsRegeneration {
            let engine = RecommendationEngine(
                catalog: appState.supplementCatalog,
                drugInteractions: appState.drugInteractions,
                medications: appState.medications,
                deepProfileModules: Array(appState.deepProfileService.completedModules.values)
            )
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
