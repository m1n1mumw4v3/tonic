import SwiftUI

@Observable
class PlanViewModel {
    private var appState: AppState?
    var userName: String = ""
    var lastRemovedSupplement: PlanSupplement?

    var activePlan: SupplementPlan? {
        get { appState?.activePlan }
        set { appState?.activePlan = newValue }
    }

    var morningSupplements: [PlanSupplement] {
        activePlan?.supplements.filter {
            !$0.isRemoved && ($0.timing == .morning || $0.timing == .emptyStomach || $0.timing == .withFood)
        } ?? []
    }

    var eveningSupplements: [PlanSupplement] {
        activePlan?.supplements.filter {
            !$0.isRemoved && ($0.timing == .evening || $0.timing == .bedtime || $0.timing == .afternoon)
        } ?? []
    }

    var removedSupplements: [PlanSupplement] {
        activePlan?.supplements.filter(\.isRemoved) ?? []
    }

    var planDateString: String {
        guard let plan = activePlan else { return "" }
        return plan.createdAt.fullDateString
    }

    var planVersionLabel: String {
        guard let plan = activePlan, plan.version > 1 else { return "" }
        return " · V\(plan.version)"
    }

    func load(appState: AppState) {
        self.appState = appState
        userName = appState.userName
    }

    func removeSupplement(_ supplement: PlanSupplement) {
        guard var plan = activePlan,
              let index = plan.supplements.firstIndex(where: { $0.id == supplement.id }) else { return }
        plan.supplements[index].isRemoved = true
        lastRemovedSupplement = supplement
        activePlan = plan
    }

    func addSupplements(_ newSupplements: [PlanSupplement]) {
        guard var plan = activePlan else { return }
        plan.supplements.append(contentsOf: newSupplements)
        // Re-sort by tier then timing
        plan.supplements.sort { a, b in
            if a.tier.sortOrder != b.tier.sortOrder {
                return a.tier.sortOrder < b.tier.sortOrder
            }
            return a.timing.sortOrder < b.timing.sortOrder
        }
        for i in plan.supplements.indices {
            plan.supplements[i].sortOrder = i
        }
        plan.version += 1
        activePlan = plan
    }

    func undoRemoval() {
        guard let removed = lastRemovedSupplement,
              var plan = activePlan,
              let index = plan.supplements.firstIndex(where: { $0.id == removed.id }) else { return }
        plan.supplements[index].isRemoved = false
        lastRemovedSupplement = nil
        activePlan = plan
    }

    func restoreSupplement(_ supplement: PlanSupplement) {
        guard var plan = activePlan,
              let index = plan.supplements.firstIndex(where: { $0.id == supplement.id }) else { return }
        plan.supplements[index].isRemoved = false
        activePlan = plan
    }
}
