import Foundation

@Observable
class DeepProfileService {
    private(set) var completedModules: [DeepProfileModuleType: DeepProfileModule] = [:]
    private var dataStore: DataStore

    init(dataStore: DataStore = LocalStorageService()) {
        self.dataStore = dataStore
    }

    // MARK: - Computed

    var completedCount: Int {
        completedModules.count
    }

    var totalCount: Int {
        DeepProfileModuleType.allCases.count
    }

    var completionProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var isComplete: Bool {
        completedCount == totalCount
    }

    var hasStarted: Bool {
        completedCount > 0
    }

    var nextIncompleteModule: DeepProfileModuleType? {
        DeepProfileModuleType.allCases.first { !isModuleCompleted($0) }
    }

    // MARK: - Operations

    func loadCompletedModules() {
        do {
            let modules = try dataStore.getDeepProfileModules()
            var dict: [DeepProfileModuleType: DeepProfileModule] = [:]
            for module in modules {
                dict[module.moduleId] = module
            }
            completedModules = dict
        } catch {
            completedModules = [:]
        }
    }

    func saveModule(_ module: DeepProfileModule) {
        do {
            try dataStore.saveDeepProfileModule(module)
            completedModules[module.moduleId] = module
        } catch {
            // Silently fail — local storage unlikely to throw
        }
    }

    func responses(for moduleType: DeepProfileModuleType) -> [String: ResponseValue]? {
        completedModules[moduleType]?.responses
    }

    func isModuleCompleted(_ moduleType: DeepProfileModuleType) -> Bool {
        completedModules[moduleType] != nil
    }

    func deleteModule(_ moduleType: DeepProfileModuleType) {
        do {
            try dataStore.deleteDeepProfileModule(moduleType)
            completedModules.removeValue(forKey: moduleType)
        } catch {
            // Silently fail
        }
    }

    // MARK: - Flattened Profile

    func flattenedProfile() -> [String: ResponseValue] {
        var result: [String: ResponseValue] = [:]
        for (_, module) in completedModules {
            for (key, value) in module.responses {
                result[key] = value
            }
        }
        return result
    }

    func formattedForPrompt() -> String {
        guard !completedModules.isEmpty else { return "" }

        var lines: [String] = ["## Deep Health Profile"]

        for moduleType in DeepProfileModuleType.allCases {
            guard let module = completedModules[moduleType] else { continue }

            lines.append("")
            lines.append("### \(moduleType.displayName)")

            for (key, value) in module.responses.sorted(by: { $0.key < $1.key }) {
                let formattedKey = key.replacingOccurrences(of: "_", with: " ").capitalized
                switch value {
                case .string(let str):
                    lines.append("- \(formattedKey): \(str)")
                case .strings(let strs):
                    lines.append("- \(formattedKey): \(strs.joined(separator: ", "))")
                }
            }
        }

        return lines.joined(separator: "\n")
    }
}
