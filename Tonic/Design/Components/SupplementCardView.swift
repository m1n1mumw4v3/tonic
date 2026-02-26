import SwiftUI

// MARK: - Configuration Types

enum SupplementCardTrailingAccessory {
    case goalChips([HealthGoal])
    case toggle(isOn: Bool, action: () -> Void)
}

enum SupplementCardExpansionMode {
    case inline
    case none
}

enum SupplementCardDetailLevel {
    case standard   // 5 sections: why, timeline, lookFor, form, category
    case full       // + dosageRationale + interactionNote
}

struct SupplementCardMenuAction {
    let title: String
    let icon: String
    let role: ButtonRole?
    let action: () -> Void

    init(_ title: String, icon: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }
}

// MARK: - SupplementCardView

struct SupplementCardView: View {
    let supplement: PlanSupplement
    var trailingAccessory: SupplementCardTrailingAccessory = .goalChips([])
    var expansionMode: SupplementCardExpansionMode = .inline
    var detailLevel: SupplementCardDetailLevel = .standard
    var menuActions: [SupplementCardMenuAction] = []
    var inlineGoals: [HealthGoal] = []
    var isIncluded: Bool = true
    var isExpanded: Bool = false
    var showBottomLearnMore: Bool = false
    var onEvidenceInfoTapped: ((EvidenceLevel) -> Void)? = nil
    var onTap: (() -> Void)? = nil

    private var matchedHealthGoals: [HealthGoal] {
        switch trailingAccessory {
        case .goalChips(let goals):
            return goals.filter { supplement.matchedGoals.contains($0.rawValue) }
        case .toggle:
            return []
        }
    }

    private var visibleChipGoals: [HealthGoal] {
        Array(matchedHealthGoals.prefix(2))
    }

    private var overflowChipCount: Int {
        max(matchedHealthGoals.count - 2, 0)
    }

    private var accentColors: [Color] {
        // For goal chips mode, derive from matched goals
        switch trailingAccessory {
        case .goalChips(let goals):
            return goals.filter { supplement.matchedGoals.contains($0.rawValue) }
                .map(\.accentColor)
        case .toggle:
            // For toggle mode, also derive from supplement's matched goals using all known goals
            let allGoals = HealthGoal.allCases
            return allGoals.filter { supplement.matchedGoals.contains($0.rawValue) }
                .map(\.accentColor)
        }
    }

    private var tier: SupplementTier {
        supplement.tier
    }

    var body: some View {
        if expansionMode == .inline, let onTap = onTap {
            Button(action: onTap) {
                cardContent
            }
            .buttonStyle(.plain)
        } else {
            cardContent
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(spacing: 0) {
            // Collapsed row
            collapsedRow

            // Expanded content
            if expansionMode == .inline && isExpanded {
                expandedContent
                    .transition(
                        .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                    )
            }

            // Bottom-centered learn more
            if expansionMode == .inline && showBottomLearnMore {
                bottomLearnMore
                    .padding(.top, isExpanded ? DesignTokens.spacing8 : DesignTokens.spacing12)
            }
        }
        .padding(DesignTokens.spacing16)
        .background(cardBackground)
        .opacity(isIncluded ? 1.0 : 0.5)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            accentBar
        }
        .overlay(alignment: .leading) {
            coreGlow
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
    }

    // MARK: - Collapsed Row

    private var collapsedRow: some View {
        HStack(alignment: .center, spacing: DesignTokens.spacing8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(supplement.name)
                    .font(DesignTokens.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .strikethrough(!isIncluded, color: DesignTokens.textTertiary)
                    .lineLimit(1)

                HStack(spacing: DesignTokens.spacing8) {
                    Text(supplement.dosage)
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.info)

                    Text("\u{00B7}")
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text(supplement.timing.label)
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                if !inlineGoals.isEmpty {
                    inlineGoalChips
                        .padding(.top, 4)
                }
            }

            Spacer()

            trailingAccessoryView

            if !menuActions.isEmpty {
                kebabMenu
            }

            if expansionMode == .inline && !showBottomLearnMore {
                chevronHint
            }
        }
    }

    // MARK: - Inline Goal Chips

    private var inlineGoalChips: some View {
        HStack(spacing: 6) {
            ForEach(inlineGoals) { goal in
                HStack(spacing: 3) {
                    Image(systemName: goal.icon)
                        .font(.system(size: 9))
                    Text(goal.shortLabel)
                        .font(DesignTokens.smallMono)
                }
                .fixedSize()
                .foregroundStyle(goal.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(goal.accentColor.opacity(0.12))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Trailing Accessory

    @ViewBuilder
    private var trailingAccessoryView: some View {
        switch trailingAccessory {
        case .goalChips:
            if !matchedHealthGoals.isEmpty && inlineGoals.isEmpty {
                HStack(spacing: 4) {
                    ForEach(visibleChipGoals) { goal in
                        Text(goal.shortLabel)
                            .font(DesignTokens.smallMono)
                            .fixedSize()
                            .foregroundStyle(goal.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(goal.accentColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    if overflowChipCount > 0 {
                        Text("+\(overflowChipCount)")
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(DesignTokens.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(DesignTokens.textTertiary.opacity(0.10))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
        case .toggle(let isOn, let action):
            SupplementToggle(isOn: isOn, action: action)
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Spacer().frame(height: 0)

            // Evidence quality
            evidenceChip

            // Why it's in your plan
            infoSection(icon: "person.fill", label: "Why it's in your plan", text: supplement.whyInYourPlan)

            // Dosage rationale (full detail only)
            if detailLevel == .full {
                infoSection(icon: "scalemass", label: "Dosage rationale", text: supplement.dosageRationale)
            }

            // When to expect results
            infoSection(icon: "clock", label: "When to expect results", text: supplement.expectedTimeline)

            // What to look for
            infoSection(icon: "eye", label: "What to look for", text: supplement.whatToLookFor)

            // Form & bioavailability
            infoSection(icon: "pills", label: "Form & bioavailability", text: supplement.formAndBioavailability)

            // Interactions & synergies (full detail only)
            if detailLevel == .full {
                infoSection(icon: "arrow.triangle.2.circlepath", label: "Interactions & synergies", text: supplement.interactionNote)
            }

            // Category badge
            categoryBadge
        }
    }

    // MARK: - Evidence Chip

    @ViewBuilder
    private var evidenceChip: some View {
        if let evidence = supplement.evidenceDisplay, !evidence.isEmpty {
            let level = supplement.evidenceLevel ?? .moderate
            let chipColor: Color = switch level {
            case .strong: DesignTokens.positive
            case .moderate: DesignTokens.info
            case .emerging: DesignTokens.accentEnergy
            }
            HStack(spacing: 6) {
                Image(systemName: level.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(chipColor)
                Text(evidence)
                    .font(DesignTokens.labelMono)
                    .foregroundStyle(DesignTokens.textPrimary)

                if let onEvidenceInfoTapped {
                    Button {
                        HapticManager.selection()
                        onEvidenceInfoTapped(level)
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Learn about \(evidence)")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(chipColor.opacity(0.08))
            .clipShape(Capsule())
        }
    }

    // MARK: - Info Section

    @ViewBuilder
    private func infoSection(icon: String, label: String, text: String?) -> some View {
        if let text = text, !text.isEmpty {
            HStack(alignment: .top, spacing: DesignTokens.spacing8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 18, height: 18, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DesignTokens.captionFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text(text)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Category Badge

    private var categoryBadge: some View {
        HStack(spacing: DesignTokens.spacing8) {
            Image(systemName: "tag")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 18, alignment: .center)

            Text(SupplementCatalog.categoryLabel(for: supplement.category))
                .font(DesignTokens.labelMono)
                .foregroundStyle(DesignTokens.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(DesignTokens.bgElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(DesignTokens.borderDefault, lineWidth: 1)
                )
        }
    }

    // MARK: - Kebab Menu

    private var kebabMenu: some View {
        Menu {
            ForEach(Array(menuActions.enumerated()), id: \.offset) { _, action in
                Button(role: action.role) {
                    action.action()
                } label: {
                    Label(action.title, systemImage: action.icon)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DesignTokens.textTertiary)
                .rotationEffect(.degrees(90))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Chevron Hint

    private var chevronHint: some View {
        HStack(spacing: 4) {
            Text("MORE")
                .font(DesignTokens.smallMono)
                .foregroundStyle(DesignTokens.textTertiary)
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignTokens.textTertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isExpanded)
        }
    }

    private var bottomLearnMore: some View {
        HStack(spacing: 4) {
            Text("LEARN MORE")
                .font(DesignTokens.smallMono)
                .foregroundStyle(DesignTokens.textTertiary)
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignTokens.textTertiary)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isExpanded)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        if tier == .supporting {
            DesignTokens.bgSurface.opacity(0.7)
        } else {
            DesignTokens.bgSurface
        }
    }

    // MARK: - Accent Bar

    @ViewBuilder
    private var accentBar: some View {
        if tier == .core, accentColors.count > 1 {
            UnevenRoundedRectangle(
                topLeadingRadius: DesignTokens.radiusMedium,
                bottomLeadingRadius: DesignTokens.radiusMedium
            )
            .fill(
                LinearGradient(
                    colors: accentColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 5)
        } else if tier == .core, let color = accentColors.first {
            UnevenRoundedRectangle(
                topLeadingRadius: DesignTokens.radiusMedium,
                bottomLeadingRadius: DesignTokens.radiusMedium
            )
            .fill(color)
            .frame(width: 5)
        } else if tier == .targeted, let color = accentColors.first {
            UnevenRoundedRectangle(
                topLeadingRadius: DesignTokens.radiusMedium,
                bottomLeadingRadius: DesignTokens.radiusMedium
            )
            .fill(color)
            .frame(width: 3)
        }
    }

    // MARK: - Core Glow

    @ViewBuilder
    private var coreGlow: some View {
        if tier == .core, let color = accentColors.first {
            RadialGradient(
                colors: [color.opacity(0.04), Color.clear],
                center: .leading,
                startRadius: 0,
                endRadius: 120
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .allowsHitTesting(false)
        }
    }
}
