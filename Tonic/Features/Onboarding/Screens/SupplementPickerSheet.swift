import SwiftUI

struct SupplementPickerSheet: View {
    @Binding var selectedSupplements: Set<String>
    @Binding var customSupplementText: String
    var kb: KnowledgeBaseProvider
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @FocusState private var isOtherFieldFocused: Bool

    private var isOtherSelected: Bool {
        !customSupplementText.isEmpty
    }

    private var filteredGroups: [(category: String, label: String, supplements: [Supplement])] {
        if searchText.isEmpty {
            return kb.supplementsByCategory
        }
        let query = searchText.lowercased()
        return kb.supplementsByCategory.compactMap { group in
            let filtered = group.supplements.filter { $0.name.lowercased().contains(query) }
            guard !filtered.isEmpty else { return nil }
            return (category: group.category, label: group.label, supplements: filtered)
        }
    }

    private var showOtherRow: Bool {
        searchText.isEmpty || "other".contains(searchText.lowercased())
    }

    private var totalSelectionCount: Int {
        var count = selectedSupplements.count
        if !customSupplementText.isEmpty {
            count += customSupplementText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .count
        }
        return count
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Add Supplements")
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.top, DesignTokens.spacing20)
                .padding(.bottom, DesignTokens.spacing16)

                // Search bar
                HStack(spacing: DesignTokens.spacing8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(DesignTokens.textTertiary)

                    TextField("Search supplements...", text: $searchText)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                }
                .padding(DesignTokens.spacing12)
                .background(DesignTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(DesignTokens.borderDefault, lineWidth: 1)
                )
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.bottom, DesignTokens.spacing16)

                // Supplement list
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredGroups, id: \.category) { group in
                            // Section header
                            Text(group.label.uppercased())
                                .font(DesignTokens.sectionHeader)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .tracking(1)
                                .padding(.horizontal, DesignTokens.spacing20)
                                .padding(.top, DesignTokens.spacing16)
                                .padding(.bottom, DesignTokens.spacing8)

                            ForEach(group.supplements) { supplement in
                                supplementRow(supplement)
                            }
                        }

                        // "Other" row
                        if showOtherRow {
                            Text("OTHER")
                                .font(DesignTokens.sectionHeader)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .tracking(1)
                                .padding(.horizontal, DesignTokens.spacing20)
                                .padding(.top, DesignTokens.spacing16)
                                .padding(.bottom, DesignTokens.spacing8)

                            otherRow
                        }
                    }
                    .padding(.bottom, totalSelectionCount > 0 ? 80 : DesignTokens.spacing32)
                }
                .overlay(alignment: .bottom) {
                    if totalSelectionCount > 0 {
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [
                                    .clear,
                                    DesignTokens.bgDeepest,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 40)
                            .allowsHitTesting(false)

                            CTAButton(title: "Add \(totalSelectionCount) Supplement\(totalSelectionCount == 1 ? "" : "s")", style: .primary) {
                                dismiss()
                            }
                            .padding(.horizontal, DesignTokens.spacing20)
                            .padding(.bottom, DesignTokens.spacing8)
                            .background(DesignTokens.bgDeepest)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.2), value: totalSelectionCount)
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Supplement Row

    private func supplementRow(_ supplement: Supplement) -> some View {
        let isSelected = selectedSupplements.contains(supplement.name)

        return Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedSupplements.remove(supplement.name)
                } else {
                    selectedSupplements.insert(supplement.name)
                }
            }
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(supplement.name)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Text(supplement.commonDosageRange)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DesignTokens.accentClarity : DesignTokens.textTertiary)
            }
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.vertical, DesignTokens.spacing12)
            .background(isSelected ? DesignTokens.bgElevated : Color.clear)
        }
    }

    // MARK: - Other Row

    private var otherRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                HapticManager.selection()
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isOtherSelected {
                        customSupplementText = ""
                    } else {
                        isOtherFieldFocused = true
                    }
                }
            } label: {
                HStack(spacing: DesignTokens.spacing12) {
                    Text("Other")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)

                    Spacer()

                    Image(systemName: isOtherSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isOtherSelected ? DesignTokens.accentClarity : DesignTokens.textTertiary)
                }
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.vertical, DesignTokens.spacing12)
                .background(isOtherSelected ? DesignTokens.bgElevated : Color.clear)
            }

            // Custom text field (always visible so tapping Other focuses it)
            if isOtherSelected || isOtherFieldFocused {
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    TextField(
                        "",
                        text: $customSupplementText,
                        prompt: Text("e.g. Turmeric, Spirulina...").foregroundStyle(DesignTokens.textSecondary),
                        axis: .vertical
                    )
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(2...4)
                    .padding(DesignTokens.spacing16)
                    .background(DesignTokens.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                            .stroke(
                                isOtherFieldFocused ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                                lineWidth: 1
                            )
                    )
                    .focused($isOtherFieldFocused)

                    Text("Separate with commas")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.horizontal, DesignTokens.spacing20)
                .padding(.vertical, DesignTokens.spacing12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
