import SwiftUI

struct PillboxGrid: View {
    let supplements: [PlanSupplement]
    let supplementStates: [UUID: Bool]
    let onToggle: (UUID) -> Void
    let allJustCompleted: Bool

    private static let amTimings: Set<SupplementTiming> = [.emptyStomach, .morning, .withFood]
    private static let pmTimings: Set<SupplementTiming> = [.afternoon, .evening, .bedtime]

    private var amSupplements: [PlanSupplement] {
        supplements
            .filter { Self.amTimings.contains($0.timing) }
            .sorted { $0.timing.sortOrder < $1.timing.sortOrder }
    }

    private var pmSupplements: [PlanSupplement] {
        supplements
            .filter { Self.pmTimings.contains($0.timing) }
            .sorted { $0.timing.sortOrder < $1.timing.sortOrder }
    }

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.spacing8),
        GridItem(.flexible(), spacing: DesignTokens.spacing8),
    ]

    var body: some View {
        pillboxContent
            .onChange(of: allJustCompleted) { _, completed in
                if completed {
                    HapticManager.notification(.success)
                }
            }
    }

    // MARK: - Pillbox Content

    private var pillboxContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: DesignTokens.spacing16) {
                // AM Section
                if !amSupplements.isEmpty {
                    sectionHeader(icon: "sun.max.fill", label: "AM", tint: DesignTokens.accentEnergy)

                    LazyVGrid(columns: columns, spacing: DesignTokens.spacing8) {
                        ForEach(Array(amSupplements.enumerated()), id: \.element.id) { index, supplement in
                            compartmentView(for: supplement)
                        }
                    }
                    .padding(DesignTokens.spacing8)
                }

                // Hinge divider between AM and PM
                if !amSupplements.isEmpty && !pmSupplements.isEmpty {
                    hingeDivider
                        .padding(.vertical, DesignTokens.spacing4)
                }

                // PM Section
                if !pmSupplements.isEmpty {
                    sectionHeader(icon: "moon.fill", label: "PM", tint: DesignTokens.accentSleep)

                    LazyVGrid(columns: columns, spacing: DesignTokens.spacing8) {
                        ForEach(Array(pmSupplements.enumerated()), id: \.element.id) { index, supplement in
                            compartmentView(for: supplement)
                        }
                    }
                    .padding(DesignTokens.spacing8)
                }
            }
            .padding(DesignTokens.spacing16)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                    .fill(DesignTokens.bgSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusLarge)
                    .stroke(DesignTokens.borderDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, label: String, tint: Color) -> some View {
        HStack(spacing: DesignTokens.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
            Text(label)
                .font(DesignTokens.sectionHeader)
                .tracking(1.5)
            Spacer()
        }
        .foregroundStyle(tint)
    }

    // MARK: - Hinge Divider

    private var hingeDivider: some View {
        Rectangle()
            .fill(DesignTokens.borderDefault)
            .frame(height: 1)
            .padding(.horizontal, DesignTokens.spacing8)
    }

    // MARK: - Compartment

    @ViewBuilder
    private func compartmentView(for supplement: PlanSupplement) -> some View {
        PillboxCompartment(
            supplement: supplement,
            isTaken: supplementStates[supplement.id] ?? false,
            onToggle: { onToggle(supplement.id) }
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var states: [UUID: Bool] = [:]
        @State private var allDone = false

        private let supplements: [PlanSupplement] = {
            func make(_ name: String, _ dosage: String, _ timing: SupplementTiming) -> PlanSupplement {
                PlanSupplement(name: name, dosage: dosage, timing: timing)
            }
            return [
                // AM
                make("L-Theanine", "200mg", .emptyStomach),
                make("Omega-3 (EPA/DHA)", "1000mg", .morning),
                make("Vitamin D3 + K2", "5000 IU", .withFood),
                make("Ashwagandha KSM-66", "600mg", .withFood),
                make("Vitamin B Complex", "1 cap", .morning),
                // PM
                make("Magnesium Glycinate", "400mg", .evening),
                make("Tart Cherry Extract", "500mg", .evening),
                make("Melatonin", "0.5mg", .bedtime),
            ]
        }()

        var body: some View {
            ScrollView {
                PillboxGrid(
                    supplements: supplements,
                    supplementStates: states,
                    onToggle: { id in
                        states[id] = !(states[id] ?? false)
                        let allTaken = supplements.allSatisfy { states[$0.id] ?? false }
                        allDone = allTaken
                    },
                    allJustCompleted: allDone
                )
                .padding(.horizontal, DesignTokens.spacing16)
                .padding(.top, DesignTokens.spacing24)
            }
            .background(DesignTokens.bgDeepest)
        }
    }

    return PreviewWrapper()
}
