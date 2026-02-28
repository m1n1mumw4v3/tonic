import SwiftUI

struct MedicationPickerSheet: View {
    @Binding var selectedMedicationIds: Set<UUID>
    @Binding var selectedMedications: Set<String>
    @Binding var customMedicationText: String
    var onOptOut: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @State private var searchText = ""
    @State private var activeCategory: String? = nil

    // MARK: - Data Sources

    private var dbMedications: [DBMedication] {
        appState.medications
    }

    private var useSupabase: Bool {
        !dbMedications.isEmpty
    }

    // MARK: - Computed Properties

    private var totalSelectionCount: Int {
        var count = useSupabase ? selectedMedicationIds.count : selectedMedications.count
        if !customMedicationText.isEmpty {
            count += customMedicationText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .count
        }
        return count
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespaces).lowercased()
    }

    /// All selected display names for chips
    private var selectedDisplayNames: [String] {
        var names: [String] = []
        if useSupabase {
            names = dbMedications
                .filter { selectedMedicationIds.contains($0.id) }
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { $0.displayName }
        } else {
            names = Array(selectedMedications).sorted()
        }
        // Add custom entries
        if !customMedicationText.isEmpty {
            let customs = customMedicationText
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            names.append(contentsOf: customs)
        }
        return names
    }

    // MARK: - Supabase filtered results

    private var filteredDBMedications: [DBMedication] {
        var source = dbMedications
        if let cat = activeCategory {
            source = source.filter { $0.displayCategory == cat }
        }
        if isSearching {
            let query = searchQuery
            source = source.filter { med in
                med.displayName.lowercased().contains(query)
                    || med.genericName.lowercased().contains(query)
                    || (med.brandNames ?? []).contains(where: { $0.lowercased().contains(query) })
                    || (med.drugClass?.lowercased().contains(query) ?? false)
            }
        }
        return source.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Static filtered results

    private var filteredStaticMedications: [Medication] {
        var source = MedicationKnowledgeBase.allMedications
        if let cat = activeCategory {
            source = source.filter { $0.category == cat }
        }
        if isSearching {
            let query = searchQuery
            source = source.filter { med in
                med.name.lowercased().contains(query)
                    || (med.genericName?.lowercased().contains(query) ?? false)
                    || (med.drugClass?.lowercased().contains(query) ?? false)
            }
        }
        return source
    }

    private var filteredResultCount: Int {
        useSupabase ? filteredDBMedications.count : filteredStaticMedications.count
    }

    private var hasResults: Bool {
        filteredResultCount > 0
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                selectionChips
                searchBar
                scrollableContent
            }

            // Bottom CTA overlay
            if totalSelectionCount > 0 {
                VStack {
                    Spacer()
                    bottomCTA
                }
            }
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("Add Medications")
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
    }

    // MARK: - Selection Chips

    @ViewBuilder
    private var selectionChips: some View {
        if !selectedDisplayNames.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.spacing8) {
                    ForEach(selectedDisplayNames, id: \.self) { name in
                        RemovableChip(name: name) {
                            HapticManager.selection()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                removeSelection(name)
                            }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, DesignTokens.spacing20)
            }
            .padding(.bottom, DesignTokens.spacing12)
            .animation(.easeInOut(duration: 0.2), value: selectedDisplayNames)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DesignTokens.spacing8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignTokens.textTertiary)

            TextField("Search by name or brand...", text: $searchText)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
            }
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
        .onChange(of: searchText) {
            // Clear category filter when searching
            if isSearching && activeCategory != nil {
                activeCategory = nil
            }
        }
    }

    // MARK: - Scrollable Content

    private var scrollableContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if isSearching {
                    searchResultsContent
                } else if activeCategory != nil {
                    categoryDrillDownContent
                } else {
                    defaultContent
                }
            }
            .padding(.bottom, totalSelectionCount > 0 ? 100 : DesignTokens.spacing32)
        }
    }

    // MARK: - State 1: Default (no search, no category filter)

    @ViewBuilder
    private var defaultContent: some View {
        // Instructional text
        Text("Start typing a medication name, or browse by category:")
            .font(DesignTokens.captionFont)
            .foregroundStyle(DesignTokens.textSecondary)
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.bottom, DesignTokens.spacing12)

        // Category pills
        categoryPillsView
            .padding(.bottom, DesignTokens.spacing16)

        // Full catalog organized by category
        if useSupabase {
            let grouped = Dictionary(grouping: dbMedications) { $0.displayCategory }
            let orderedCategories = MedicationKnowledgeBase.allCategories.filter { grouped[$0] != nil }
            ForEach(orderedCategories, id: \.self) { category in
                sectionHeader(category.uppercased())
                ForEach(grouped[category]!.sorted { $0.sortOrder < $1.sortOrder }) { med in
                    dbMedicationRow(med)
                }
            }
        } else {
            ForEach(MedicationKnowledgeBase.medicationsByCategory, id: \.category) { group in
                sectionHeader(group.category.uppercased())
                ForEach(group.medications, id: \.name) { med in
                    staticMedicationRow(med)
                }
            }
        }

        // Opt-out link (only when no selections)
        if totalSelectionCount == 0 {
            optOutLink
        }
    }

    // MARK: - State 2: Search Results

    @ViewBuilder
    private var searchResultsContent: some View {
        if hasResults {
            sectionHeader("\(filteredResultCount) RESULT\(filteredResultCount == 1 ? "" : "S")")

            if useSupabase {
                ForEach(filteredDBMedications) { med in
                    dbMedicationRow(med, highlightQuery: searchQuery)
                }
            } else {
                ForEach(filteredStaticMedications, id: \.name) { med in
                    staticMedicationRow(med, highlightQuery: searchQuery)
                }
            }
        } else {
            // State 4: No results
            noResultsContent
        }

        // Custom add row
        customAddRow
    }

    // MARK: - State 4: No Results

    @ViewBuilder
    private var noResultsContent: some View {
        VStack(spacing: DesignTokens.spacing8) {
            Text("No medications match \"\(searchText.trimmingCharacters(in: .whitespaces))\"")
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)

            Text("You can add it manually below")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.spacing24)
        .padding(.horizontal, DesignTokens.spacing20)
    }

    // MARK: - State 5: Category Drill-Down

    @ViewBuilder
    private var categoryDrillDownContent: some View {
        // Active category pill
        activeCategoryPill
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.bottom, DesignTokens.spacing16)

        let count = filteredResultCount
        if let cat = activeCategory {
            sectionHeader("\(cat.uppercased()) \u{2014} \(count) MEDICATION\(count == 1 ? "" : "S")")
        }

        if useSupabase {
            ForEach(filteredDBMedications) { med in
                dbMedicationRow(med)
            }
        } else {
            ForEach(filteredStaticMedications, id: \.name) { med in
                staticMedicationRow(med)
            }
        }
    }

    // MARK: - Category Pills

    private var categoryPillsView: some View {
        FlowLayout(spacing: DesignTokens.spacing8) {
            ForEach(MedicationKnowledgeBase.categoryPills) { pill in
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCategory = pill.label
                    }
                } label: {
                    Text(pill.label)
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .padding(.horizontal, DesignTokens.spacing12)
                        .padding(.vertical, DesignTokens.spacing8)
                        .background(DesignTokens.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusFull)
                                .stroke(DesignTokens.borderDefault, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, DesignTokens.spacing20)
    }

    private var activeCategoryPill: some View {
        Group {
            if let cat = activeCategory, let pill = MedicationKnowledgeBase.categoryPills.first(where: { $0.label == cat }) {
                Button {
                    HapticManager.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeCategory = nil
                    }
                } label: {
                    HStack(spacing: DesignTokens.spacing4) {
                        Text(pill.label)
                            .font(DesignTokens.captionFont)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.horizontal, DesignTokens.spacing12)
                    .padding(.vertical, DesignTokens.spacing8)
                    .background(DesignTokens.accentLongevity)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(DesignTokens.sectionHeader)
            .foregroundStyle(DesignTokens.accentLongevity)
            .tracking(1)
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.top, DesignTokens.spacing16)
            .padding(.bottom, DesignTokens.spacing8)
    }

    // MARK: - Supabase Medication Row

    private func dbMedicationRow(_ medication: DBMedication, highlightQuery: String? = nil) -> some View {
        let isSelected = selectedMedicationIds.contains(medication.id)

        return Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedMedicationIds.remove(medication.id)
                    selectedMedications.remove(medication.displayName)
                } else {
                    selectedMedicationIds.insert(medication.id)
                    selectedMedications.insert(medication.displayName)
                }
            }
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                VStack(alignment: .leading, spacing: 2) {
                    // Main text: displayName (brandNames[0])
                    if let query = highlightQuery, !query.isEmpty {
                        highlightedText(medication.displayName, query: query)
                    } else {
                        Text(medication.displayName)
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }

                    // Subtitle: drugClass
                    if let drugClass = medication.drugClass {
                        Text(drugClass)
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DesignTokens.accentLongevity : DesignTokens.textTertiary)
            }
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.vertical, DesignTokens.spacing12)
            .background(isSelected ? DesignTokens.accentLongevity.opacity(0.08) : Color.clear)
        }
    }

    // MARK: - Static Medication Row

    private func staticMedicationRow(_ medication: Medication, highlightQuery: String? = nil) -> some View {
        let isSelected = selectedMedications.contains(medication.name)
        let displayText: String = {
            if let generic = medication.genericName {
                return "\(medication.name) (\(generic))"
            }
            return medication.name
        }()

        return Button {
            HapticManager.selection()
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedMedications.remove(medication.name)
                } else {
                    selectedMedications.insert(medication.name)
                }
            }
        } label: {
            HStack(spacing: DesignTokens.spacing12) {
                VStack(alignment: .leading, spacing: 2) {
                    if let query = highlightQuery, !query.isEmpty {
                        highlightedText(displayText, query: query)
                    } else {
                        Text(displayText)
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }

                    if let drugClass = medication.drugClass {
                        Text(drugClass)
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? DesignTokens.accentLongevity : DesignTokens.textTertiary)
            }
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.vertical, DesignTokens.spacing12)
            .background(isSelected ? DesignTokens.accentLongevity.opacity(0.08) : Color.clear)
        }
    }

    // MARK: - Custom Add Row

    @ViewBuilder
    private var customAddRow: some View {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if isSearching && !trimmed.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                Button {
                    HapticManager.selection()
                    addCustomMedication(trimmed)
                } label: {
                    HStack(spacing: DesignTokens.spacing8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DesignTokens.accentLongevity)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add \"\(trimmed)\" as custom medication")
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.accentLongevity)

                            Text("Won't be checked for interactions")
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(DesignTokens.textTertiary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, DesignTokens.spacing20)
                    .padding(.vertical, DesignTokens.spacing12)
                }

                // Info card when no results
                if !hasResults {
                    infoCard
                        .padding(.horizontal, DesignTokens.spacing20)
                        .padding(.top, DesignTokens.spacing8)
                }
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(DesignTokens.info)

            Text("For medications we don't recognize, we recommend consulting your healthcare provider about supplement interactions.")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(DesignTokens.spacing16)
        .background(DesignTokens.info.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, DesignTokens.bgDeepest],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .allowsHitTesting(false)

            CTAButton(title: "Add \(totalSelectionCount) Medication\(totalSelectionCount == 1 ? "" : "s")", style: .primary) {
                dismiss()
            }
            .padding(.horizontal, DesignTokens.spacing20)
            .padding(.bottom, DesignTokens.spacing8)
            .background(DesignTokens.bgDeepest)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.2), value: totalSelectionCount)
    }

    // MARK: - Opt-Out Link

    private var optOutLink: some View {
        Button {
            HapticManager.selection()
            onOptOut?()
            dismiss()
        } label: {
            Text("I'm not taking any medications")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textSecondary)
                .underline()
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.spacing16)
        }
        .padding(.horizontal, DesignTokens.spacing20)
    }

    // MARK: - Helpers

    private func removeSelection(_ name: String) {
        // Try removing from known medications first
        if selectedMedications.contains(name) {
            selectedMedications.remove(name)
            if let med = dbMedications.first(where: { $0.displayName == name }) {
                selectedMedicationIds.remove(med.id)
            }
        } else {
            // Remove from custom text
            let parts = customMedicationText
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0 != name }
            customMedicationText = parts.joined(separator: ", ")
        }
    }

    private func addCustomMedication(_ name: String) {
        if customMedicationText.isEmpty {
            customMedicationText = name
        } else {
            customMedicationText += ", \(name)"
        }
        searchText = ""
    }

    // MARK: - Match Highlighting

    private func highlightedText(_ text: String, query: String) -> some View {
        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()

        guard let range = lowerText.range(of: lowerQuery) else {
            return Text(text)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textPrimary)
        }

        let startIndex = text.index(text.startIndex, offsetBy: lowerText.distance(from: lowerText.startIndex, to: range.lowerBound))
        let endIndex = text.index(startIndex, offsetBy: lowerQuery.count)

        let before = String(text[text.startIndex..<startIndex])
        let match = String(text[startIndex..<endIndex])
        let after = String(text[endIndex..<text.endIndex])

        return Text(before)
            .font(DesignTokens.bodyFont)
            .foregroundStyle(DesignTokens.textPrimary)
        + Text(match)
            .font(DesignTokens.bodyFont)
            .fontWeight(.semibold)
            .foregroundStyle(DesignTokens.accentLongevity)
        + Text(after)
            .font(DesignTokens.bodyFont)
            .foregroundStyle(DesignTokens.textPrimary)
    }
}
