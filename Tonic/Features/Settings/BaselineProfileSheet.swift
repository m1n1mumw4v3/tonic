import SwiftUI

struct BaselineProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: BaselineProfileViewModel
    let onSave: (UserProfile, Bool) -> Void

    @State private var showSupplementPicker = false
    @State private var showMedicationPicker = false
    @State private var showMaxGoalError = false

    // Height/Weight local state
    private enum HeightUnit: String, CaseIterable {
        case ft, cm
    }
    private enum WeightUnit: String, CaseIterable {
        case lbs, kg
    }

    @State private var heightUnit: HeightUnit = .ft
    @State private var selectedTotalInches: Int = 68
    @State private var selectedCm: Int = 173

    @State private var weightUnit: WeightUnit = .lbs
    @State private var selectedLbs: Int = 160
    @State private var selectedKg: Int = 73

    private let heightImperialOptions: [Int] = Array(36...95)
    private let heightMetricOptions: [Int] = Array(91...241)
    private let weightImperialOptions: [Int] = Array(60...500)
    private let weightMetricOptions: [Int] = Array(27...227)

    private let goalColumns = [
        GridItem(.flexible(), spacing: DesignTokens.spacing12),
        GridItem(.flexible(), spacing: DesignTokens.spacing12)
    ]

    private static let commonAllergies: [(name: String, icon: String)] = [
        ("Shellfish", "🦐"),
        ("Soy", "🫘"),
        ("Gluten", "🌾"),
        ("Dairy", "🥛"),
        ("Tree Nuts", "🌰"),
        ("Fish", "🐟"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bgDeepest.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        personalSection
                        goalsSection
                        supplementsSection
                        lifestyleSection
                        wellnessSection
                    }
                    .padding(.horizontal, DesignTokens.spacing16)
                    .padding(.vertical, DesignTokens.spacing16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("Baseline Profile")
                        .font(DesignTokens.titleFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        syncHeightWeight()
                        let updatedProfile = viewModel.applyChanges()
                        let needsRegen = viewModel.needsPlanRegeneration
                        onSave(updatedProfile, needsRegen)
                        dismiss()
                    }
                    .font(DesignTokens.ctaFont)
                    .foregroundStyle(viewModel.hasChanges ? DesignTokens.accentClarity : DesignTokens.textTertiary)
                    .disabled(!viewModel.hasChanges)
                }
            }
            .toolbarBackground(DesignTokens.bgSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .interactiveDismissDisabled(viewModel.hasChanges)
        .sheet(isPresented: $showSupplementPicker) {
            SupplementPickerSheet(
                selectedSupplements: Bindable(viewModel).currentSupplements,
                customSupplementText: Bindable(viewModel).customSupplementText
            )
        }
        .sheet(isPresented: $showMedicationPicker) {
            MedicationPickerSheet(
                selectedMedications: Bindable(viewModel).medications,
                customMedicationText: Bindable(viewModel).customMedicationText
            )
        }
        .onAppear {
            // Sync height local state
            let totalInches = viewModel.heightFeet * 12 + viewModel.heightInches
            selectedTotalInches = totalInches
            selectedCm = viewModel.heightCm
            // Sync weight local state
            selectedLbs = viewModel.weightLbs
            selectedKg = viewModel.weightKg
        }
    }

    // MARK: - Personal Section

    private var personalSection: some View {
        sectionContainer(title: "PERSONAL") {
            VStack(spacing: DesignTokens.spacing16) {
                // Name
                fieldRow(label: "Name") {
                    TextField("First name", text: Bindable(viewModel).firstName)
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .multilineTextAlignment(.trailing)
                }

                Divider().background(DesignTokens.borderDefault)

                // Age
                fieldRow(label: "Age") {
                    Stepper(
                        "\(viewModel.age)",
                        value: Bindable(viewModel).age,
                        in: 18...100
                    )
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(DesignTokens.textPrimary)
                }

                Divider().background(DesignTokens.borderDefault)

                // Sex
                fieldRow(label: "Sex") {
                    Picker("Sex", selection: Bindable(viewModel).sex) {
                        ForEach(Sex.allCases) { sex in
                            Text(sex.label).tag(sex)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignTokens.textPrimary)
                }

                if viewModel.sex == .female {
                    Divider().background(DesignTokens.borderDefault)

                    fieldRow(label: "Pregnant") {
                        Toggle("", isOn: Bindable(viewModel).isPregnant)
                            .labelsHidden()
                            .tint(DesignTokens.accentSkin)
                    }

                    Divider().background(DesignTokens.borderDefault)

                    fieldRow(label: "Breastfeeding") {
                        Toggle("", isOn: Bindable(viewModel).isBreastfeeding)
                            .labelsHidden()
                            .tint(DesignTokens.accentSkin)
                    }
                }

                Divider().background(DesignTokens.borderDefault)

                // Height
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    HStack {
                        Text("Height")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                        Spacer()
                        Text(heightDisplayText)
                            .font(DesignTokens.dataMono)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }

                    ZStack(alignment: .trailing) {
                        Group {
                            if heightUnit == .ft {
                                ScrollWheelPicker(
                                    selection: $selectedTotalInches,
                                    items: heightImperialOptions,
                                    label: { totalInches in
                                        let feet = totalInches / 12
                                        let inches = totalInches % 12
                                        return "\(feet)'\(inches)\""
                                    },
                                    itemHeight: 44,
                                    visibleItemCount: 3
                                )
                            } else {
                                ScrollWheelPicker(
                                    selection: $selectedCm,
                                    items: heightMetricOptions,
                                    label: { "\($0)" },
                                    itemHeight: 44,
                                    visibleItemCount: 3
                                )
                            }
                        }

                        UnitPicker(selection: $heightUnit, label: { $0.rawValue })
                            .onChange(of: heightUnit) { oldUnit, newUnit in
                                convertHeight(from: oldUnit, to: newUnit)
                            }
                    }
                }

                Divider().background(DesignTokens.borderDefault)

                // Weight
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    HStack {
                        Text("Weight")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                        Spacer()
                        Text(weightDisplayText)
                            .font(DesignTokens.dataMono)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }

                    ZStack(alignment: .trailing) {
                        Group {
                            if weightUnit == .lbs {
                                ScrollWheelPicker(
                                    selection: $selectedLbs,
                                    items: weightImperialOptions,
                                    label: { "\($0)" },
                                    itemHeight: 44,
                                    visibleItemCount: 3
                                )
                            } else {
                                ScrollWheelPicker(
                                    selection: $selectedKg,
                                    items: weightMetricOptions,
                                    label: { "\($0)" },
                                    itemHeight: 44,
                                    visibleItemCount: 3
                                )
                            }
                        }

                        UnitPicker(selection: $weightUnit, label: { $0.rawValue })
                            .onChange(of: weightUnit) { oldUnit, newUnit in
                                convertWeight(from: oldUnit, to: newUnit)
                            }
                    }
                }
            }
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        sectionContainer(title: "HEALTH GOALS") {
            VStack(spacing: DesignTokens.spacing12) {
                LazyVGrid(columns: goalColumns, spacing: DesignTokens.spacing12) {
                    ForEach(HealthGoal.allCases) { goal in
                        goalCard(for: goal)
                    }
                }

                if viewModel.healthGoals.isEmpty {
                    Text("Select at least one goal")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.negative)
                }

                if showMaxGoalError {
                    Text("You can select up to \(HealthGoal.maxSelection) goals for a focused plan.")
                        .font(DesignTokens.captionFont)
                        .foregroundStyle(DesignTokens.negative)
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onChange(of: viewModel.healthGoals.count) {
            if !viewModel.isAtGoalLimit {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMaxGoalError = false
                }
            }
        }
    }

    // MARK: - Supplements & Medications Section

    private var supplementsSection: some View {
        sectionContainer(title: "SUPPLEMENTS & MEDICATIONS") {
            VStack(alignment: .leading, spacing: DesignTokens.spacing16) {
                // Current supplements
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    HStack {
                        Text("Current Supplements")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                        Spacer()
                        Toggle("", isOn: Bindable(viewModel).takingSupplements)
                            .labelsHidden()
                            .tint(DesignTokens.accentClarity)
                    }

                    if viewModel.takingSupplements {
                        let allSupps = allSupplementNames
                        if !allSupps.isEmpty {
                            FlowLayout(spacing: DesignTokens.spacing8) {
                                ForEach(allSupps, id: \.self) { name in
                                    RemovableChip(name: name) {
                                        viewModel.currentSupplements.remove(name)
                                    }
                                }
                            }
                        }

                        Button {
                            showSupplementPicker = true
                        } label: {
                            Label("Add Supplement", systemImage: "plus.circle.fill")
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.accentClarity)
                        }
                    }
                }

                Divider().background(DesignTokens.borderDefault)

                // Medications
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    HStack {
                        Text("Medications")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                        Spacer()
                        Toggle("", isOn: Bindable(viewModel).takingMedications)
                            .labelsHidden()
                            .tint(DesignTokens.accentClarity)
                    }

                    if viewModel.takingMedications {
                        let allMeds = allMedicationNames
                        if !allMeds.isEmpty {
                            FlowLayout(spacing: DesignTokens.spacing8) {
                                ForEach(allMeds, id: \.self) { name in
                                    RemovableChip(name: name) {
                                        viewModel.medications.remove(name)
                                    }
                                }
                            }
                        }

                        Button {
                            showMedicationPicker = true
                        } label: {
                            Label("Add Medication", systemImage: "plus.circle.fill")
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.accentClarity)
                        }
                    }
                }

                Divider().background(DesignTokens.borderDefault)

                // Allergies
                VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                    Text("Allergies")
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textSecondary)

                    FlowLayout(spacing: DesignTokens.spacing8) {
                        ForEach(Self.commonAllergies, id: \.name) { allergy in
                            allergyChip(name: allergy.name, icon: allergy.icon)
                        }
                    }

                    let customAllergies = Array(viewModel.allergies).filter { name in
                        !Self.commonAllergies.contains(where: { $0.name == name })
                    }
                    if !customAllergies.isEmpty {
                        FlowLayout(spacing: DesignTokens.spacing8) {
                            ForEach(customAllergies, id: \.self) { name in
                                RemovableChip(name: name) {
                                    viewModel.allergies.remove(name)
                                }
                            }
                        }
                    }

                    TextField(
                        "",
                        text: Bindable(viewModel).customAllergyText,
                        prompt: Text("Other allergies (comma separated)")
                            .foregroundStyle(DesignTokens.textTertiary),
                        axis: .vertical
                    )
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineLimit(1...3)
                    .padding(DesignTokens.spacing12)
                    .background(DesignTokens.bgDeepest)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                            .stroke(DesignTokens.borderDefault, lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Lifestyle Section

    private var lifestyleSection: some View {
        sectionContainer(title: "LIFESTYLE") {
            VStack(spacing: DesignTokens.spacing16) {
                // Diet
                fieldRow(label: "Diet") {
                    Picker("Diet", selection: Bindable(viewModel).dietType) {
                        ForEach(DietType.allCases) { diet in
                            Text(diet.label).tag(diet)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignTokens.textPrimary)
                }

                Divider().background(DesignTokens.borderDefault)

                // Exercise
                fieldRow(label: "Exercise") {
                    Picker("Exercise", selection: Bindable(viewModel).exerciseFrequency) {
                        ForEach(ExerciseFrequency.allCases) { freq in
                            Text(freq.label).tag(freq)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignTokens.textPrimary)
                }

                Divider().background(DesignTokens.borderDefault)

                // Coffee
                fieldRow(label: "Coffee (cups/day)") {
                    Stepper(
                        "\(viewModel.coffeeCupsDaily)",
                        value: Bindable(viewModel).coffeeCupsDaily,
                        in: 0...10
                    )
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(DesignTokens.textPrimary)
                }

                Divider().background(DesignTokens.borderDefault)

                // Tea
                fieldRow(label: "Tea (cups/day)") {
                    Stepper(
                        "\(viewModel.teaCupsDaily)",
                        value: Bindable(viewModel).teaCupsDaily,
                        in: 0...10
                    )
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(DesignTokens.textPrimary)
                }

                Divider().background(DesignTokens.borderDefault)

                // Energy Drinks
                fieldRow(label: "Energy drinks/day") {
                    Stepper(
                        "\(viewModel.energyDrinksDaily)",
                        value: Bindable(viewModel).energyDrinksDaily,
                        in: 0...10
                    )
                    .font(DesignTokens.dataMono)
                    .foregroundStyle(DesignTokens.textPrimary)
                }

                Divider().background(DesignTokens.borderDefault)

                // Alcohol
                fieldRow(label: "Alcohol") {
                    Picker("Alcohol", selection: Bindable(viewModel).alcoholWeekly) {
                        ForEach(AlcoholIntake.allCases) { intake in
                            Text(intake.label).tag(intake)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignTokens.textPrimary)
                }

                Divider().background(DesignTokens.borderDefault)

                // Stress
                fieldRow(label: "Stress Level") {
                    Picker("Stress", selection: Bindable(viewModel).stressLevel) {
                        ForEach(StressLevel.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignTokens.textPrimary)
                }
            }
        }
    }

    // MARK: - Wellness Section

    private var wellnessSection: some View {
        sectionContainer(title: "BASELINE WELLNESS") {
            VStack(spacing: DesignTokens.spacing16) {
                WellnessSlider(
                    dimension: .sleep,
                    value: Bindable(viewModel).baselineSleep,
                    lowLabel: WellnessDimension.sleep.lowLabel,
                    highLabel: WellnessDimension.sleep.highLabel
                )
                WellnessSlider(
                    dimension: .energy,
                    value: Bindable(viewModel).baselineEnergy,
                    lowLabel: WellnessDimension.energy.lowLabel,
                    highLabel: WellnessDimension.energy.highLabel
                )
                WellnessSlider(
                    dimension: .clarity,
                    value: Bindable(viewModel).baselineClarity,
                    lowLabel: WellnessDimension.clarity.lowLabel,
                    highLabel: WellnessDimension.clarity.highLabel
                )
                WellnessSlider(
                    dimension: .mood,
                    value: Bindable(viewModel).baselineMood,
                    lowLabel: WellnessDimension.mood.lowLabel,
                    highLabel: WellnessDimension.mood.highLabel
                )
                WellnessSlider(
                    dimension: .gut,
                    value: Bindable(viewModel).baselineGut,
                    lowLabel: WellnessDimension.gut.lowLabel,
                    highLabel: WellnessDimension.gut.highLabel
                )
            }
        }
    }

    // MARK: - Helpers

    private func sectionContainer(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
            Text(title)
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
                .foregroundStyle(DesignTokens.textSecondary)

            VStack(alignment: .leading, spacing: 0) {
                content()
                    .padding(DesignTokens.spacing16)
            }
            .background(DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
        }
    }

    private func fieldRow(label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.bodyFont)
                .foregroundStyle(DesignTokens.textSecondary)
            Spacer()
            content()
        }
    }

    @ViewBuilder
    private func goalCard(for goal: HealthGoal) -> some View {
        let isSelected = viewModel.healthGoals.contains(goal)
        let accent = goal.accentColor

        Button {
            if isSelected {
                if viewModel.healthGoals.count > 1 {
                    viewModel.healthGoals.remove(goal)
                    HapticManager.selection()
                }
            } else if viewModel.isAtGoalLimit {
                HapticManager.notification(.warning)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMaxGoalError = true
                }
            } else {
                viewModel.healthGoals.insert(goal)
                HapticManager.selection()
            }
        } label: {
            VStack(spacing: DesignTokens.spacing8) {
                HStack {
                    Image(systemName: goal.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? accent : DesignTokens.textSecondary)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? accent : DesignTokens.textTertiary)
                }

                Text(goal.label)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DesignTokens.spacing12)
            .frame(height: 88)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(isSelected ? DesignTokens.bgElevated : DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(
                        isSelected ? accent : DesignTokens.borderDefault,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .opacity(!isSelected && viewModel.isAtGoalLimit ? 0.4 : 1.0)
        }
    }

    @ViewBuilder
    private func allergyChip(name: String, icon: String) -> some View {
        let isSelected = viewModel.allergies.contains(name)

        Button {
            HapticManager.selection()
            if isSelected {
                viewModel.allergies.remove(name)
            } else {
                viewModel.allergies.insert(name)
            }
        } label: {
            HStack(spacing: DesignTokens.spacing4) {
                Text(icon)
                    .font(.system(size: 14))
                Text(name)
                    .font(DesignTokens.bodyFont)
                    .foregroundStyle(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
            }
            .padding(.horizontal, DesignTokens.spacing12)
            .padding(.vertical, DesignTokens.spacing8)
            .background(isSelected ? DesignTokens.bgElevated : DesignTokens.bgSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusFull))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusFull)
                    .stroke(
                        isSelected ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    // MARK: - Computed Helpers

    private var allSupplementNames: [String] {
        Array(viewModel.currentSupplements).sorted()
    }

    private var allMedicationNames: [String] {
        Array(viewModel.medications).sorted()
    }

    private var heightDisplayText: String {
        if heightUnit == .ft {
            let feet = selectedTotalInches / 12
            let inches = selectedTotalInches % 12
            return "\(feet)'\(inches)\""
        } else {
            return "\(selectedCm) cm"
        }
    }

    private var weightDisplayText: String {
        if weightUnit == .lbs {
            return "\(selectedLbs) lbs"
        } else {
            return "\(selectedKg) kg"
        }
    }

    // MARK: - Height/Weight Conversion

    private func convertHeight(from oldUnit: HeightUnit, to newUnit: HeightUnit) {
        guard oldUnit != newUnit else { return }
        if newUnit == .cm {
            selectedCm = Int(round(Double(selectedTotalInches) * 2.54))
        } else {
            selectedTotalInches = Int(round(Double(selectedCm) / 2.54))
        }
    }

    private func convertWeight(from oldUnit: WeightUnit, to newUnit: WeightUnit) {
        guard oldUnit != newUnit else { return }
        if newUnit == .kg {
            selectedKg = Int(round(Double(selectedLbs) * 0.453592))
        } else {
            selectedLbs = Int(round(Double(selectedKg) / 0.453592))
        }
    }

    private func syncHeightWeight() {
        // Sync height to viewModel
        if heightUnit == .ft {
            viewModel.heightFeet = selectedTotalInches / 12
            viewModel.heightInches = selectedTotalInches % 12
            viewModel.heightCm = Int(round(Double(selectedTotalInches) * 2.54))
        } else {
            let totalInches = Int(round(Double(selectedCm) / 2.54))
            viewModel.heightFeet = totalInches / 12
            viewModel.heightInches = totalInches % 12
            viewModel.heightCm = selectedCm
        }

        // Sync weight to viewModel
        if weightUnit == .lbs {
            viewModel.weightLbs = selectedLbs
            viewModel.weightKg = Int(round(Double(selectedLbs) * 0.453592))
        } else {
            viewModel.weightKg = selectedKg
            viewModel.weightLbs = Int(round(Double(selectedKg) / 0.453592))
        }
    }
}
