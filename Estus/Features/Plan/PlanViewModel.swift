import SwiftUI

@Observable
class PlanViewModel {
    private var appState: AppState?
    var userName: String = ""
    var lastRemovedSupplement: PlanSupplement?
    var productsBySupplementId: [UUID: [RankedProduct]] = [:]
    var loadingProductIds: Set<UUID> = []

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

    // MARK: - Product Cache

    var detailProductCache: [UUID: RankedProduct] = [:]

    func cacheProduct(_ product: RankedProduct) {
        detailProductCache[product.id] = product
    }

    func findProduct(by id: UUID) -> RankedProduct? {
        if let cached = detailProductCache[id] {
            return cached
        }
        for products in productsBySupplementId.values {
            if let found = products.first(where: { $0.id == id }) {
                return found
            }
        }
        return nil
    }

    // MARK: - Product Loading

    func products(for supplement: PlanSupplement) -> [RankedProduct]? {
        guard let supplementId = supplement.supplementId else { return nil }
        return productsBySupplementId[supplementId]
    }

    func isLoadingProducts(for supplement: PlanSupplement) -> Bool {
        guard let supplementId = supplement.supplementId else { return false }
        return loadingProductIds.contains(supplementId)
    }

    func loadProducts(for supplement: PlanSupplement) {
        guard let supplementId = supplement.supplementId else {
            print("[Products] No supplementId for \(supplement.name)")
            return
        }
        guard productsBySupplementId[supplementId] == nil,
              !loadingProductIds.contains(supplementId) else {
            print("[Products] Already cached/loading for \(supplement.name) (\(supplementId))")
            return
        }

        print("[Products] Fetching for \(supplement.name) (\(supplementId))")
        loadingProductIds.insert(supplementId)

        Task {
            do {
                let service = SupplementService()
                let fetched = try await service.fetchProducts(forSupplementId: supplementId)
                print("[Products] Got \(fetched.count) products for \(supplement.name)")
                await MainActor.run {
                    productsBySupplementId[supplementId] = fetched
                    loadingProductIds.remove(supplementId)
                }
            } catch {
                print("[Products] Error for \(supplement.name): \(error)")
                await MainActor.run {
                    productsBySupplementId[supplementId] = []
                    loadingProductIds.remove(supplementId)
                }
            }
        }
    }
}
