import SwiftUI

@Observable
class PlanViewModel {
    var activePlan: SupplementPlan?
    var userName: String = ""

    var morningSupplements: [PlanSupplement] {
        activePlan?.supplements.filter {
            $0.timing == .morning || $0.timing == .emptyStomach || $0.timing == .withFood
        } ?? []
    }

    var eveningSupplements: [PlanSupplement] {
        activePlan?.supplements.filter {
            $0.timing == .evening || $0.timing == .bedtime || $0.timing == .afternoon
        } ?? []
    }

    var planDateString: String {
        guard let plan = activePlan else { return "" }
        return plan.createdAt.fullDateString
    }

    func load(appState: AppState) {
        activePlan = appState.activePlan
        userName = appState.userName
    }
}
