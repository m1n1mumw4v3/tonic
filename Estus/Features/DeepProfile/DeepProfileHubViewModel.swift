import SwiftUI

@Observable
class DeepProfileHubViewModel {
    var selectedModule: DeepProfileModuleType?

    func orderedModules(service: DeepProfileService, userGoals: [HealthGoal]) -> [DeepProfileModuleType] {
        let recommended = recommendedModules(userGoals: userGoals)
        let allModules = DeepProfileModuleType.allCases

        // Recommended first (incomplete), then others incomplete, then completed
        let incompleteRecommended = allModules.filter { recommended.contains($0) && !service.isModuleCompleted($0) }
        let incompleteOther = allModules.filter { !recommended.contains($0) && !service.isModuleCompleted($0) }
        let completed = allModules.filter { service.isModuleCompleted($0) }

        return incompleteRecommended + incompleteOther + completed
    }

    func recommendedModules(userGoals: [HealthGoal]) -> Set<DeepProfileModuleType> {
        var recommended = Set<DeepProfileModuleType>()
        for moduleType in DeepProfileModuleType.allCases {
            let hasMatchingGoal = moduleType.relatedGoals.contains { userGoals.contains($0) }
            if hasMatchingGoal {
                recommended.insert(moduleType)
            }
        }
        return recommended
    }

    func isRecommended(_ moduleType: DeepProfileModuleType, userGoals: [HealthGoal]) -> Bool {
        recommendedModules(userGoals: userGoals).contains(moduleType)
    }

    func groupedModules(service: DeepProfileService, userGoals: [HealthGoal]) -> (recommended: [DeepProfileModuleType], other: [DeepProfileModuleType]) {
        let recommendedSet = recommendedModules(userGoals: userGoals)
        let allModules = DeepProfileModuleType.allCases

        let recommended = allModules.filter { recommendedSet.contains($0) && !service.isModuleCompleted($0) }
        let other = allModules.filter { !recommendedSet.contains($0) && !service.isModuleCompleted($0) }
            + allModules.filter { service.isModuleCompleted($0) }

        return (recommended: recommended, other: other)
    }
}
