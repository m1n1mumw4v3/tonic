import SwiftUI

struct AllergiesScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @FocusState private var isCustomFieldFocused: Bool
    @State private var isOtherExpanded = false

    private static let allergyOptions: [(name: String, icon: String)] = [
        ("Shellfish", "🦐"),
        ("Soy", "🫘"),
        ("Gluten", "🌾"),
        ("Dairy", "🥛"),
        ("Tree Nuts", "🌰"),
        ("Fish", "🐟"),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacing12),
        GridItem(.flexible(), spacing: DesignTokens.spacing12),
    ]

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        // Header
                        HeadlineText(text: "Any known allergies\nor sensitivities?")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, DesignTokens.spacing24)

                        // No known allergies option
                        noKnownAllergiesTile()

                        // Divider
                        Rectangle()
                            .fill(DesignTokens.borderDefault)
                            .frame(height: 1)

                        // Allergy grid + Other allergies (consistent spacing)
                        VStack(spacing: DesignTokens.spacing12) {
                            LazyVGrid(columns: columns, spacing: DesignTokens.spacing12) {
                                ForEach(Self.allergyOptions, id: \.name) { option in
                                    allergyCard(for: option.name, icon: option.icon)
                                }
                            }

                            // Other allergies tile (full width)
                            otherAllergiesTile()
                        }

                        // Disclaimer
                        HStack(alignment: .top, spacing: DesignTokens.spacing8) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(DesignTokens.textSecondary)
                                .padding(.top, 2)

                            Text("We check for known interactions, but always consult your doctor before taking anything new.")
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing24)
                }
                .scrollDismissesKeyboard(.interactively)

                // CTA
                CTAButton(title: "Continue", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onAppear {
            if !viewModel.customAllergyText.isEmpty {
                isOtherExpanded = true
            }
        }
    }

    // MARK: - Allergy Card

    @ViewBuilder
    private func allergyCard(for allergy: String, icon: String) -> some View {
        let isSelected = viewModel.allergies.contains(allergy)

        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    viewModel.allergies.remove(allergy)
                } else {
                    viewModel.noKnownAllergies = false
                    viewModel.allergies.insert(allergy)
                }
            }
        } label: {
            VStack(spacing: DesignTokens.spacing8) {
                HStack {
                    Text(icon)
                        .font(.system(size: 20))

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? DesignTokens.accentClarity : DesignTokens.textTertiary)
                }

                Text(allergy)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.spacing12)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .background(isSelected ? DesignTokens.accentGut.opacity(0.15) : DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(isSelected ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }

    // MARK: - No Known Allergies Tile

    @ViewBuilder
    private func noKnownAllergiesTile() -> some View {
        let isSelected = viewModel.noKnownAllergies

        Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.noKnownAllergies.toggle()
                if viewModel.noKnownAllergies {
                    viewModel.allergies.removeAll()
                    viewModel.customAllergyText = ""
                    isOtherExpanded = false
                }
            }
        } label: {
            HStack(spacing: DesignTokens.spacing8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? DesignTokens.positive : DesignTokens.textTertiary)

                Text("No known allergies")
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? DesignTokens.accentClarity : DesignTokens.textTertiary)
            }
            .padding(DesignTokens.spacing12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? DesignTokens.accentGut.opacity(0.15) : DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(isSelected ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }

    // MARK: - Other Allergies Tile

    @ViewBuilder
    private func otherAllergiesTile() -> some View {
        let hasCustomText = !viewModel.customAllergyText.trimmingCharacters(in: .whitespaces).isEmpty
        let isActive = isOtherExpanded || hasCustomText

        VStack(spacing: 0) {
            Button {
                HapticManager.selection()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOtherExpanded.toggle()
                    if isOtherExpanded {
                        viewModel.noKnownAllergies = false
                        isCustomFieldFocused = true
                    }
                }
            } label: {
                HStack(spacing: DesignTokens.spacing8) {
                    Text("✏️")
                        .font(.system(size: 20))

                    Text("Other allergies")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(isActive ? DesignTokens.textPrimary : DesignTokens.textSecondary)

                    Spacer()

                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isActive ? DesignTokens.accentClarity : DesignTokens.textTertiary)
                }
                .padding(DesignTokens.spacing12)
            }

            if isOtherExpanded {
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    TextField("", text: Bindable(viewModel).customAllergyText, prompt: Text("e.g. Sesame, Latex...").foregroundStyle(DesignTokens.textSecondary), axis: .vertical)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(2...4)
                        .padding(DesignTokens.spacing12)
                        .background(DesignTokens.bgDeepest)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                        .focused($isCustomFieldFocused)

                    Text("Separate multiple allergies with commas.")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.horizontal, DesignTokens.spacing12)
                .padding(.bottom, DesignTokens.spacing12)
            }
        }
        .frame(maxWidth: .infinity)
        .background(isActive ? DesignTokens.accentGut.opacity(0.15) : DesignTokens.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(isActive ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: isActive ? 1.5 : 1)
        )
    }
}

#Preview {
    AllergiesScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
