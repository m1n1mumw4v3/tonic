import SwiftUI

@Observable
class DeepProfileFlowViewModel {
    let moduleType: DeepProfileModuleType
    let config: DeepProfileModuleConfig
    let userProfile: UserProfile

    var responses: [String: ResponseValue] = [:]
    var currentQuestionIndex: Int = 0
    var isComplete: Bool = false
    var showIntro: Bool = true

    // Auto-advance delay for singleSelect
    private let autoAdvanceDelay: TimeInterval = 0.35

    init(moduleType: DeepProfileModuleType, userProfile: UserProfile, existingResponses: [String: ResponseValue]? = nil) {
        self.moduleType = moduleType
        self.config = DeepProfileModuleRegistry.config(for: moduleType)
        self.userProfile = userProfile

        if let existing = existingResponses {
            self.responses = existing
            self.showIntro = false
        }
    }

    // MARK: - Active Questions (filtered by conditions)

    var activeQuestions: [DeepProfileQuestion] {
        config.questions.filter { question in
            guard let condition = question.condition else { return true }
            return condition.evaluate(userProfile, responses)
        }
    }

    var totalActiveQuestions: Int {
        activeQuestions.count
    }

    var currentQuestion: DeepProfileQuestion? {
        guard currentQuestionIndex < activeQuestions.count else { return nil }
        return activeQuestions[currentQuestionIndex]
    }

    var progress: CGFloat {
        guard totalActiveQuestions > 0 else { return 0 }
        return CGFloat(currentQuestionIndex) / CGFloat(totalActiveQuestions)
    }

    var stepLabel: String {
        "\(currentQuestionIndex + 1) of \(totalActiveQuestions)"
    }

    var canGoBack: Bool {
        currentQuestionIndex > 0
    }

    // MARK: - Actions

    func selectSingleAnswer(_ value: String, completion: @escaping () -> Void) {
        guard let question = currentQuestion else { return }
        responses[question.id] = .string(value)
        HapticManager.selection()

        // Auto-advance after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + autoAdvanceDelay) { [weak self] in
            self?.advanceOrComplete(completion: completion)
        }
    }

    func toggleMultiSelectAnswer(_ value: String) {
        guard let question = currentQuestion else { return }
        var current = responses[question.id]?.stringsValue ?? []

        // If "none" variant selected, clear others
        if value.lowercased().contains("none") {
            current = [value]
        } else {
            // Remove any "none" variant
            current.removeAll { $0.lowercased().contains("none") }
            if current.contains(value) {
                current.removeAll { $0 == value }
            } else {
                current.append(value)
            }
        }

        responses[question.id] = current.isEmpty ? nil : .strings(current)
        HapticManager.selection()
    }

    func setTimeAnswer(_ date: Date) {
        guard let question = currentQuestion else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        responses[question.id] = .string(formatter.string(from: date))
    }

    func setNumericAnswer(_ value: Int) {
        guard let question = currentQuestion else { return }
        responses[question.id] = .string(String(value))
    }

    func setSliderAnswer(_ value: Int) {
        guard let question = currentQuestion else { return }
        responses[question.id] = .string(String(value))
    }

    func goNext(completion: @escaping () -> Void) {
        advanceOrComplete(completion: completion)
    }

    func goBack() {
        guard canGoBack else { return }
        currentQuestionIndex -= 1
    }

    func skipQuestion(completion: @escaping () -> Void) {
        advanceOrComplete(completion: completion)
    }

    func dismissIntro() {
        showIntro = false
    }

    // MARK: - Helpers

    func selectedSingleValue(for questionId: String) -> String? {
        responses[questionId]?.stringValue
    }

    func selectedMultiValues(for questionId: String) -> [String] {
        responses[questionId]?.stringsValue ?? []
    }

    func hasAnswer(for questionId: String) -> Bool {
        responses[questionId] != nil
    }

    func buildModule() -> DeepProfileModule {
        DeepProfileModule(moduleId: moduleType, responses: responses)
    }

    private func advanceOrComplete(completion: @escaping () -> Void) {
        if currentQuestionIndex + 1 < activeQuestions.count {
            currentQuestionIndex += 1
        } else {
            isComplete = true
            completion()
        }
    }
}
