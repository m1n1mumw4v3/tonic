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
    var products: [RankedProduct]? = nil
    var productsLoading: Bool = false
    var doseRange: (low: Double, high: Double, limit: Double?)? = nil
    var dosageUnit: String? = nil
    var recommendedDosageMg: Double? = nil
    var userDosageMg: Binding<Double?>? = nil
    var onDosageCommit: ((Double?) -> Void)? = nil
    var onEvidenceInfoTapped: ((EvidenceLevel) -> Void)? = nil
    var onShopTapped: (() -> Void)? = nil
    var onProductTapped: ((RankedProduct) -> Void)? = nil
    var onSeeAllProductsTapped: (() -> Void)? = nil
    var onRemoveTapped: (() -> Void)? = nil
    var onRestoreTapped: (() -> Void)? = nil
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
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusCard)
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusCard))
        .overlay(alignment: .topTrailing) {
            if expansionMode == .inline && !showBottomLearnMore {
                chevronHint
                    .padding(.top, DesignTokens.spacing24)
                    .padding(.trailing, DesignTokens.spacing16)
            }
        }
        .shadow(color: DesignTokens.cardShadowColor, radius: DesignTokens.cardShadowRadius, x: 0, y: DesignTokens.cardShadowY)
    }

    // MARK: - Collapsed Row

    private var collapsedRow: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
            // Top row: name + trailing accessories
            HStack(alignment: .center, spacing: DesignTokens.spacing8) {
                Image("EstusSuppIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(
                        accentColors.count > 1
                            ? AnyShapeStyle(LinearGradient(
                                colors: accentColors,
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                              ))
                            : AnyShapeStyle(accentColors.first ?? DesignTokens.textSecondary)
                    )

                Text(supplement.name)
                    .font(.custom("Geist-Regular", size: 20))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .strikethrough(!isIncluded, color: DesignTokens.textTertiary)
                    .lineLimit(1)
                    .layoutPriority(1)

                Spacer()

                trailingAccessoryView

                if !menuActions.isEmpty {
                    kebabMenu
                }

            }

            if !inlineGoals.isEmpty {
                HStack(alignment: .bottom) {
                    inlineGoalChips

                    Spacer()

                    Text(supplement.displayDosage)
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.top, 4)
            } else {
                HStack {
                    Spacer()
                    Text(supplement.displayDosage)
                        .font(DesignTokens.labelMono)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
        }
    }

    // MARK: - Inline Goal Chips

    private var inlineGoalChips: some View {
        HStack(spacing: 6) {
            ForEach(inlineGoals) { goal in
                Text(goal.shortLabel)
                    .font(DesignTokens.labelMono)
                    .fixedSize()
                    .foregroundStyle(goal.chipColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(goal.chipColor, lineWidth: 1)
                    )
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
                            .foregroundStyle(goal.chipColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(goal.chipColor, lineWidth: 1)
                            )
                    }
                    if overflowChipCount > 0 {
                        Text("+\(overflowChipCount)")
                            .font(DesignTokens.smallMono)
                            .foregroundStyle(DesignTokens.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(DesignTokens.textTertiary, lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 2)
            }
        case .toggle:
            EmptyView()
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
            Spacer().frame(height: 0)

            // Why it's in your plan
            infoSection(icon: "person", label: "Why it's in your plan", text: supplement.whyInYourPlan)

            // How and when to take it
            howAndWhenSection

            // Editable dosage range (only when catalog data is available)
            dosageEditorSection

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

            // Research level
            evidenceSection

            // Product carousel or shop button
            productSection

            // Remove or restore
            if let onRestoreTapped {
                planActionButton(
                    icon: "plus.circle",
                    title: "Add back to my plan",
                    tint: DesignTokens.positive,
                    action: onRestoreTapped
                )
            } else if let onRemoveTapped {
                planActionButton(
                    icon: "trash",
                    title: "Remove from plan",
                    tint: DesignTokens.negative,
                    action: onRemoveTapped
                )
            }
        }
    }

    private func planActionButton(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.custom("Geist-Regular", size: 14))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.top, DesignTokens.spacing4)
            .padding(.bottom, DesignTokens.spacing12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, -DesignTokens.spacing4)
    }

    // MARK: - Evidence Section

    @ViewBuilder
    private var evidenceSection: some View {
        if let evidence = supplement.evidenceDisplay, !evidence.isEmpty {
            let level = supplement.evidenceLevel ?? .moderate
            let chipColor: Color = switch level {
            case .strong: DesignTokens.positive
            case .moderate: DesignTokens.info
            case .emerging: DesignTokens.accentEnergy
            }
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacing8) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 18, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Research level")
                        .font(.custom("Geist-Regular", size: 16))
                        .foregroundStyle(DesignTokens.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: level.icon)
                            .font(.system(size: 10))
                            .foregroundStyle(chipColor)
                        Text(evidence)
                            .font(DesignTokens.labelMono)
                            .foregroundStyle(chipColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(chipColor.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Info Section

    @ViewBuilder
    private func infoSection(icon: String, label: String, text: String?) -> some View {
        if let text = text, !text.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacing8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .frame(width: 18, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.custom("Geist-Regular", size: 16))
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text(text)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Dosage Editor Section

    @ViewBuilder
    private var dosageEditorSection: some View {
        if let range = doseRange,
           let unit = dosageUnit,
           let recommended = recommendedDosageMg,
           let userBinding = userDosageMg {
            DosageRangeEditor(
                low: range.low,
                high: range.high,
                limit: range.limit,
                recommended: recommended,
                unit: unit,
                step: Double.niceStep(low: range.low, high: range.high),
                value: Binding(
                    get: { userBinding.wrappedValue ?? recommended },
                    set: { newValue in
                        let cleaned: Double? = abs(newValue - recommended) < 0.0001 ? nil : newValue
                        userBinding.wrappedValue = cleaned
                    }
                ),
                onCommit: { newValue in
                    let cleaned: Double? = abs(newValue - recommended) < 0.0001 ? nil : newValue
                    onDosageCommit?(cleaned)
                }
            )
        }
    }

    // MARK: - How and When Section

    private var howAndWhenSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacing8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 14))
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(width: 18, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                Text("How and when to take it")
                    .font(.custom("Geist-Regular", size: 16))
                    .foregroundStyle(DesignTokens.textPrimary)

                HStack(spacing: 6) {
                    timingChip(label: supplement.timing.label, icon: timingIcon)

                    if supplement.timing.isFoodRelated {
                        // Already a food-related timing, no extra chip needed
                    } else {
                        // Show a food instruction chip if timing implies one
                        timingChip(label: foodInstruction, icon: "fork.knife")
                    }
                }
            }
        }
    }

    private var timingIcon: String {
        switch supplement.timing {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .bedtime: return "moon"
        case .withFood: return "fork.knife"
        case .emptyStomach: return "stomach"
        }
    }

    private var foodInstruction: String {
        switch supplement.timing {
        case .morning, .afternoon: return "With food"
        case .evening: return "With dinner"
        case .bedtime: return "Without food"
        case .withFood: return "With food"
        case .emptyStomach: return "Empty stomach"
        }
    }

    private func timingChip(label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(DesignTokens.smallMono)
        }
        .foregroundStyle(DesignTokens.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(DesignTokens.bgElevated)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(DesignTokens.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Product Section

    @ViewBuilder
    private var productSection: some View {
        if let products, !products.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.spacing8) {
                    Image(systemName: "bag")
                        .font(.system(size: 14))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .frame(width: 18, alignment: .center)
                    Text("Top products")
                        .font(.custom("Geist-Regular", size: 16))
                        .foregroundStyle(DesignTokens.textPrimary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: DesignTokens.spacing12) {
                        ForEach(products.prefix(3)) { rankedProduct in
                            InlineProductCardView(
                                rankedProduct: rankedProduct,
                                onTap: {
                                    onProductTapped?(rankedProduct)
                                }
                            )
                        }

                        if products.count > 3 || onSeeAllProductsTapped != nil {
                            SeeAllProductCard(
                                supplementName: supplement.name,
                                onTap: onSeeAllProductsTapped
                            )
                        }
                    }
                    .padding(.horizontal, 1)
                    .padding(.trailing, DesignTokens.spacing16)
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, -DesignTokens.spacing16)
                .padding(.leading, DesignTokens.spacing16)
            }
        } else if productsLoading {
            HStack(spacing: DesignTokens.spacing8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(DesignTokens.textTertiary)
                Text("Loading products...")
                    .font(DesignTokens.captionFont)
                    .foregroundStyle(DesignTokens.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DesignTokens.spacing8)
        } else if let onShopTapped {
            shopProductsButton(action: onShopTapped)
        }
    }

    // MARK: - Shop Products Button

    private func shopProductsButton(action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bag")
                    .font(.system(size: 14))
                Text("Shop Products")
                    .font(.custom("Geist-Regular", size: 16))
            }
            .foregroundStyle(DesignTokens.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DesignTokens.textPrimary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
        Image(systemName: "chevron.down")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(DesignTokens.textSecondary)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isExpanded)
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
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusCard))
            .allowsHitTesting(false)
        }
    }
}
