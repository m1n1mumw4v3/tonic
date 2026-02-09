import SwiftUI

struct MedicationsScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var showingMedicationPicker = false
    @State private var showError = false

    /// All display pills: known selections + parsed custom entries.
    private var allPills: [String] {
        var pills = Array(viewModel.medications).sorted()
        if !viewModel.customMedicationText.isEmpty {
            pills.append(contentsOf: viewModel.customMedicationText
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty })
        }
        return pills
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DesignTokens.spacing32) {
                        // Header
                        HeadlineText(text: "Any medications we\nshould know about?")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, DesignTokens.spacing24)

                        // Yes / No toggle buttons
                        HStack(spacing: DesignTokens.spacing12) {
                            toggleButton(label: "Yes", isActive: viewModel.takingMedications) {
                                HapticManager.selection()
                                viewModel.takingMedications = true
                                showingMedicationPicker = true
                            }

                            toggleButton(label: "No", isActive: !viewModel.takingMedications) {
                                HapticManager.selection()
                                viewModel.takingMedications = false
                                viewModel.medications = []
                                viewModel.customMedicationText = ""
                                showError = false
                            }
                        }

                        // Medication chips + CTA (shown when "Yes")
                        if viewModel.takingMedications {
                            VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                                if !allPills.isEmpty {
                                    Text("YOUR MEDICATIONS")
                                        .font(DesignTokens.sectionHeader)
                                        .foregroundStyle(DesignTokens.textSecondary)
                                        .tracking(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    FlowLayout(spacing: DesignTokens.spacing8) {
                                        ForEach(allPills, id: \.self) { name in
                                            RemovableChip(name: name) {
                                                HapticManager.selection()
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    removePill(name)
                                                }
                                            }
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: allPills)
                                }

                                Button {
                                    HapticManager.selection()
                                    showingMedicationPicker = true
                                } label: {
                                    HStack(spacing: DesignTokens.spacing8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Medications")
                                    }
                                    .font(DesignTokens.bodyFont)
                                    .fontWeight(.medium)
                                    .foregroundStyle(DesignTokens.accentClarity)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                            .stroke(DesignTokens.accentClarity, lineWidth: 1.5)
                                    )
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing24)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.takingMedications)
                }

                // Error + CTA pinned below scroll
                VStack(spacing: DesignTokens.spacing12) {
                    if showError {
                        Text("Please add your medications above, or select 'No' if you're not currently taking any.")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(Color(hex: "#FF6B6B"))
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    CTAButton(title: "Continue", style: .primary) {
                        if viewModel.takingMedications && allPills.isEmpty {
                            HapticManager.notification(.warning)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showError = true
                            }
                        } else {
                            onContinue()
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.spacing24)
                .padding(.bottom, DesignTokens.spacing48)
            }
        }
        .onChange(of: allPills) {
            if !allPills.isEmpty { showError = false }
        }
        .sheet(isPresented: $showingMedicationPicker) {
            MedicationPickerSheet(
                selectedMedications: Bindable(viewModel).medications,
                customMedicationText: Bindable(viewModel).customMedicationText
            )
        }
    }

    /// Removes a pill — from known selections first, then from custom text.
    private func removePill(_ name: String) {
        if viewModel.medications.contains(name) {
            viewModel.medications.remove(name)
        } else {
            let parts = viewModel.customMedicationText
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0 != name }
            viewModel.customMedicationText = parts.joined(separator: ", ")
        }
    }

    // MARK: - Toggle Button

    @ViewBuilder
    private func toggleButton(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(DesignTokens.bodyFont)
                .fontWeight(.medium)
                .foregroundStyle(isActive ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isActive ? DesignTokens.bgElevated : DesignTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(
                            isActive ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                            lineWidth: isActive ? 1.5 : 1
                        )
                )
        }
    }
}

#Preview {
    MedicationsScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
