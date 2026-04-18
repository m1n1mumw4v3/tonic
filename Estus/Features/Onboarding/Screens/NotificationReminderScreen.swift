import SwiftUI

struct NotificationReminderScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var morningExpanded = false
    @State private var eveningExpanded = false
    @State private var isRequesting = false

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.spacing24) {
                        Spacer()
                            .frame(height: DesignTokens.spacing8)

                        // Header
                        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                            HeadlineText(text: "Set up your reminders")

                            Text("Building a routine is easier with reminders. Set up daily nudges to stay on track.")
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, DesignTokens.spacing24)

                        // Notification preview bubble
                        notificationPreview
                            .padding(.horizontal, DesignTokens.spacing32)
                            .padding(.bottom, -DesignTokens.spacing24)

                        // Time slot cards
                        VStack(spacing: DesignTokens.spacing12) {
                            timeSlotCard(
                                label: "MORNING",
                                icon: "sun.max.fill",
                                tint: Color(hex: "#FAC655"),
                                time: Bindable(viewModel).morningReminderTime,
                                enabled: Bindable(viewModel).morningReminderEnabled,
                                expanded: $morningExpanded
                            )

                            timeSlotCard(
                                label: "EVENING",
                                icon: "moon.fill",
                                tint: DesignTokens.accentSleep,
                                time: Bindable(viewModel).eveningReminderTime,
                                enabled: Bindable(viewModel).eveningReminderEnabled,
                                expanded: $eveningExpanded
                            )
                        }
                        .padding(.horizontal, DesignTokens.spacing24)

                        // Encouragement tip
                        encouragementTip
                            .padding(.horizontal, DesignTokens.spacing24)
                    }
                }

                Spacer()

                // CTAs
                VStack(spacing: DesignTokens.spacing8) {
                    CTAButton(title: "Continue", style: .primary) {
                        guard !isRequesting else { return }
                        isRequesting = true
                        Task {
                            await NotificationService.requestAuthorization()
                            isRequesting = false
                            onContinue()
                        }
                    }

                    Button {
                        viewModel.morningReminderEnabled = false
                        viewModel.eveningReminderEnabled = false
                        onContinue()
                    } label: {
                        Text("Skip for now")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignTokens.spacing32)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing8)
            }
        }
    }

    // MARK: - Notification Preview (Phone Mockup)

    private var notificationPreview: some View {
        let bezelWidth: CGFloat = 6
        let outerRadius: CGFloat = 44
        let innerRadius = outerRadius - bezelWidth

        return VStack(spacing: 0) {
            // Status bar — padded down to clear the floating dynamic island
            HStack {
                Text("9:41")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.textSecondary)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "cellularbars")
                        .font(.system(size: 12))
                    Image(systemName: "wifi")
                        .font(.system(size: 12))
                    Image(systemName: "battery.75percent")
                        .font(.system(size: 14))
                }
                .foregroundStyle(DesignTokens.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 44)

            Spacer()
                .frame(height: 20)

            // Notification bubble
            VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                HStack(spacing: DesignTokens.spacing8) {
                    // App icon
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignTokens.bgSurface)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("A")
                                .font(DesignTokens.pixelIconSmall)
                                .foregroundStyle(DesignTokens.accentClarity)
                        )

                    Text("Estus")
                        .font(DesignTokens.bodyFont.bold())
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    Text("now")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Text("☀️ Time to take your AM supplements!")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(DesignTokens.spacing16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .padding(.horizontal, 12)

            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity)
        .background(DesignTokens.bgDeepest)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: innerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: innerRadius,
                style: .continuous
            )
        )
        .padding(.horizontal, bezelWidth)
        .padding(.top, bezelWidth)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: outerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: outerRadius,
                style: .continuous
            )
            .fill(Color.black)
        )
        .overlay(alignment: .top) {
            // Dynamic Island floats over the screen
            Capsule()
                .fill(Color.black)
                .frame(width: 100, height: 28)
                .padding(.top, bezelWidth + 8)
        }
        .overlay(
            // Subtle top highlight on the bezel for depth
            UnevenRoundedRectangle(
                topLeadingRadius: outerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: outerRadius,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.white.opacity(0)],
                    startPoint: .top,
                    endPoint: .center
                ),
                lineWidth: 1
            )
        )
        // Side bezel extensions — slide behind the morning card below
        .overlay(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color.black)
                .frame(width: bezelWidth, height: 60)
                .offset(y: 60)
        }
        .overlay(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color.black)
                .frame(width: bezelWidth, height: 60)
                .offset(y: 60)
        }
        .shadow(color: .black.opacity(0.18), radius: 28, y: 10)
    }

    // MARK: - Encouragement Tip

    private var encouragementTip: some View {
        VStack(spacing: 2) {
            (Text(Image(systemName: "lightbulb.fill"))
                .font(DesignTokens.captionFont)
                .foregroundStyle(Color(hex: "#FAC655"))
            + Text(" Daily reminders make you")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
            + Text(" 2x more likely")
                .font(DesignTokens.captionFont.bold())
                .foregroundStyle(DesignTokens.textPrimary))

            Text("to stay consistent with your routine.")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
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
            // Main row
            HStack {
                // Left: label + time
                VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
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

                // Right: toggle
                Toggle("", isOn: enabled)
                    .labelsHidden()
                    .tint(DesignTokens.onboardingSelected)
                    .accessibilityLabel("\(label) reminder")
                    .accessibilityValue(enabled.wrappedValue ? "On" : "Off")
                    .onChange(of: enabled.wrappedValue) { _, newValue in
                        HapticManager.selection()
                        if !newValue {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expanded.wrappedValue = false
                            }
                        }
                    }
            }
            .padding(.leading, 26)
            .padding(.trailing, DesignTokens.spacing16)
            .padding(.vertical, DesignTokens.spacing16)
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

            // Expandable date picker
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
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(enabled.wrappedValue ? DesignTokens.onboardingSelected : DesignTokens.borderDefault, lineWidth: 1)
        )
    }
}

#Preview {
    NotificationReminderScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
