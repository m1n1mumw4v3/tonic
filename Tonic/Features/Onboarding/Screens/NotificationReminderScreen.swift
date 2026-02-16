import SwiftUI

struct NotificationReminderScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var morningExpanded = false
    @State private var eveningExpanded = false

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
                            HeadlineText(text: "Set up your reminders.")

                            Text("Building a routine is easier with reminders. Set up daily nudges to stay on track.")
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, DesignTokens.spacing24)

                        // Notification preview bubble
                        notificationPreview
                            .padding(.horizontal, DesignTokens.spacing32)

                        // Time slot cards
                        VStack(spacing: DesignTokens.spacing12) {
                            timeSlotCard(
                                label: "MORNING",
                                icon: "sun.max.fill",
                                tint: DesignTokens.accentEnergy,
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
                        onContinue()
                    }

                    Button {
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
        VStack(spacing: 0) {
            // Dynamic Island
            Capsule()
                .fill(Color.black)
                .frame(width: 76, height: 22)
                .padding(.top, 10)

            // Status bar
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
            .padding(.top, 6)

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

                    Text("Ample")
                        .font(DesignTokens.bodyFont.bold())
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    Text("now")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Text("Time to take your AM supplements!")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
            }
            .padding(DesignTokens.spacing16)
            .background(DesignTokens.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .padding(.horizontal, 12)

            Spacer()
                .frame(height: 10)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    DesignTokens.bgSurface.opacity(0.6),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28))
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 2)
        // Extend the side lines down to meet the morning card
        .padding(.bottom, DesignTokens.spacing24)
        .overlay(
            PhoneFrameShape(cornerRadius: 28)
                .stroke(DesignTokens.borderDefault, lineWidth: 1.5)
        )
        .padding(.bottom, -DesignTokens.spacing24)
    }

    // MARK: - Encouragement Tip

    private var encouragementTip: some View {
        HStack(spacing: DesignTokens.spacing12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundStyle(DesignTokens.accentEnergy)

            VStack(alignment: .leading, spacing: 2) {
                Text("Daily reminders make you")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
                + Text(" 2x more likely")
                    .font(DesignTokens.captionFont.bold())
                    .foregroundStyle(DesignTokens.textPrimary)

                Text("to stay consistent with your routine.")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textSecondary)
            }
        }
        .padding(DesignTokens.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
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

                // Right: toggle
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
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(enabled.wrappedValue ? DesignTokens.accentClarity : DesignTokens.borderDefault, lineWidth: 1)
        )
    }
}

// MARK: - Phone Frame Shape (open bottom)

private struct PhoneFrameShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start at bottom-left, draw up the left side
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        // Top-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        // Top-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        // Down the right side
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

#Preview {
    NotificationReminderScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
