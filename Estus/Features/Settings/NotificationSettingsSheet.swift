import SwiftUI
import UserNotifications

struct NotificationSettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var morningEnabled: Bool
    @State private var eveningEnabled: Bool
    @State private var morningTime: Date
    @State private var eveningTime: Date
    @State private var morningExpanded = false
    @State private var eveningExpanded = false
    @State private var isSaving = false

    init(profile: UserProfile) {
        _morningEnabled = State(initialValue: profile.morningReminderEnabled)
        _eveningEnabled = State(initialValue: profile.eveningReminderEnabled)
        _morningTime = State(initialValue: profile.morningReminderTime)
        _eveningTime = State(initialValue: profile.eveningReminderTime)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bgDeepest.ignoresSafeArea()

                VStack(spacing: DesignTokens.spacing24) {
                    VStack(spacing: DesignTokens.spacing12) {
                        timeSlotCard(
                            label: "MORNING",
                            icon: "sun.max.fill",
                            tint: DesignTokens.accentEnergy,
                            time: $morningTime,
                            enabled: $morningEnabled,
                            expanded: $morningExpanded
                        )

                        timeSlotCard(
                            label: "EVENING",
                            icon: "moon.fill",
                            tint: DesignTokens.accentSleep,
                            time: $eveningTime,
                            enabled: $eveningEnabled,
                            expanded: $eveningExpanded
                        )
                    }

                    CTAButton(title: "Save", style: .primary) {
                        guard !isSaving else { return }
                        isSaving = true
                        Task {
                            await saveAndReschedule()
                            isSaving = false
                            dismiss()
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.top, DesignTokens.spacing16)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveAndReschedule() async {
        guard var profile = appState.currentUser else { return }
        profile.morningReminderEnabled = morningEnabled
        profile.eveningReminderEnabled = eveningEnabled
        profile.morningReminderTime = morningTime
        profile.eveningReminderTime = eveningTime
        profile.updatedAt = Date()

        appState.currentUser = profile
        try? LocalStorageService().saveProfile(profile)

        // Request permission if not yet granted
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            await NotificationService.requestAuthorization()
        }

        NotificationService.scheduleNotifications(for: profile)
    }

    // MARK: - Time Slot Card

    private func timeSlotCard(
        label: String,
        icon: String,
        tint: Color,
        time: Binding<Date>,
        enabled: Binding<Bool>,
        expanded: Binding<Bool>
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundStyle(tint)

                        Text(label)
                            .font(DesignTokens.sectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    HStack(spacing: DesignTokens.spacing4) {
                        Text(time.wrappedValue.formatted(date: .omitted, time: .shortened))
                            .font(DesignTokens.titleFont)
                            .foregroundStyle(enabled.wrappedValue ? DesignTokens.textPrimary : DesignTokens.textTertiary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(enabled.wrappedValue ? DesignTokens.textSecondary : DesignTokens.textTertiary)
                            .rotationEffect(.degrees(expanded.wrappedValue ? 90 : 0))
                    }
                }

                Spacer()

                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(DesignTokens.accentGut)
                    .onChange(of: enabled.wrappedValue) { _, newValue in
                        HapticManager.selection()
                        if !newValue {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expanded.wrappedValue = false
                            }
                        }
                    }
            }
            .padding(DesignTokens.spacing16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if !enabled.wrappedValue {
                        enabled.wrappedValue = true
                    }
                    expanded.wrappedValue.toggle()
                }
                HapticManager.impact(.light)
            }

            if expanded.wrappedValue {
                Divider()
                    .background(DesignTokens.borderSubtle)

                DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.light)
                    .padding(.horizontal, DesignTokens.spacing16)
                    .padding(.vertical, DesignTokens.spacing8)
                    .onChange(of: time.wrappedValue) {
                        HapticManager.impact(.light)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(enabled.wrappedValue ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: 1)
        )
    }
}
