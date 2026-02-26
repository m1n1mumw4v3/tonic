import SwiftUI

struct CurrentSuppsScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @Environment(KnowledgeBaseProvider.self) private var kb
    @State private var showingSupplementPicker = false
    @State private var showError = false

    /// All display pills: known selections + parsed custom entries.
    private var allPills: [String] {
        var pills = Array(viewModel.currentSupplements).sorted()
        if !viewModel.customSupplementText.isEmpty {
            pills.append(contentsOf: viewModel.customSupplementText
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
                        HeadlineText(text: "Are you currently taking any supplements?")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, DesignTokens.spacing24)

                        // Yes / No toggle buttons
                        HStack(spacing: DesignTokens.spacing12) {
                            toggleButton(label: "Yes", isActive: viewModel.takingSupplements) {
                                HapticManager.selection()
                                viewModel.takingSupplements = true
                                showingSupplementPicker = true
                            }

                            toggleButton(label: "No", isActive: !viewModel.takingSupplements) {
                                HapticManager.selection()
                                viewModel.takingSupplements = false
                                viewModel.currentSupplements = []
                                viewModel.customSupplementText = ""
                                showError = false
                            }
                        }

                        // Supplement chips + CTA (shown when "Yes")
                        if viewModel.takingSupplements {
                            VStack(alignment: .leading, spacing: DesignTokens.spacing12) {
                                if !allPills.isEmpty {
                                    Text("YOUR SUPPLEMENTS")
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
                                    showingSupplementPicker = true
                                } label: {
                                    HStack(spacing: DesignTokens.spacing8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Supplements")
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
                    .animation(.easeInOut(duration: 0.25), value: viewModel.takingSupplements)
                }

                // Error + CTA
                VStack(spacing: DesignTokens.spacing12) {
                    if showError {
                        Text("Please add your supplements above, or select 'No' if you're not currently taking any.")
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(DesignTokens.negative)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    CTAButton(title: "Continue", style: .primary) {
                        if viewModel.takingSupplements && allPills.isEmpty {
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
        .sheet(isPresented: $showingSupplementPicker) {
            SupplementPickerSheet(
                selectedSupplements: Bindable(viewModel).currentSupplements,
                customSupplementText: Bindable(viewModel).customSupplementText,
                kb: kb
            )
        }
    }

    /// Removes a pill — from known selections first, then from custom text.
    private func removePill(_ name: String) {
        if viewModel.currentSupplements.contains(name) {
            viewModel.currentSupplements.remove(name)
        } else {
            // Remove from custom text
            let parts = viewModel.customSupplementText
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0 != name }
            viewModel.customSupplementText = parts.joined(separator: ", ")
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
                .background(isActive ? DesignTokens.accentGut.opacity(0.15) : DesignTokens.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(isActive ? DesignTokens.accentGut : DesignTokens.borderDefault, lineWidth: isActive ? 1.5 : 1)
                )
        }
    }
}

#Preview {
    CurrentSuppsScreenPreview()
}

private struct CurrentSuppsScreenPreview: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var kb = KnowledgeBaseProvider()

    var body: some View {
        CurrentSuppsScreen(viewModel: viewModel, onContinue: {})
            .environment(kb)
    }
}
