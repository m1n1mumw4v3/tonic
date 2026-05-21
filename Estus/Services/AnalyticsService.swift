import Foundation
import PostHog

/// Thin wrapper around PostHog providing typed events, identify/reset, and a
/// no-op fallback when no real API key is configured (so dev builds work without
/// touching xcconfig). PostHog's SDK is thread-safe; this wrapper isn't actor-
/// isolated so call sites in view models and services don't need awaits.
final class AnalyticsService {
    static let shared = AnalyticsService()

    private(set) var isEnabled = false

    private init() {}

    // MARK: - Lifecycle

    func start() {
        let key = AppConfiguration.postHogAPIKey
        guard isProductionKey(key) else {
            print("ℹ️ [Analytics] PostHog disabled — placeholder API key. Set POSTHOG_API_KEY in xcconfig to enable.")
            return
        }

        let host = AppConfiguration.postHogHost.absoluteString
        let config = PostHogConfig(apiKey: key, host: host)
        config.captureApplicationLifecycleEvents = true
        // Manual capture is more reliable than autocapture for SwiftUI screens.
        config.captureScreenViews = false
        PostHogSDK.shared.setup(config)
        isEnabled = true
        print("✅ [Analytics] PostHog initialized")
    }

    // MARK: - Identity

    func identify(profile: UserProfile, email: String?) {
        guard isEnabled else { return }
        let distinctId = (profile.userId ?? profile.id).uuidString
        var props: [String: Any] = [
            "age": profile.age,
            "sex": profile.sex.rawValue,
            "diet_type": profile.dietType.rawValue,
            "health_goals": profile.healthGoals.map(\.rawValue),
            "goal_count": profile.healthGoals.count
        ]
        if let email { props["email"] = email }
        if !profile.firstName.isEmpty { props["first_name"] = profile.firstName }
        PostHogSDK.shared.identify(distinctId, userProperties: props)
    }

    func reset() {
        guard isEnabled else { return }
        PostHogSDK.shared.reset()
    }

    // MARK: - Capture

    func capture(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        PostHogSDK.shared.capture(event.name, properties: event.properties)
    }

    // MARK: - Helpers

    /// Real PostHog project keys are prefixed `phc_`. Anything else (e.g. the
    /// `your-posthog-api-key` placeholder shipped in `Debug.xcconfig.example`)
    /// means analytics should stay off rather than crash or 401-spam.
    private func isProductionKey(_ key: String) -> Bool {
        key.hasPrefix("phc_") && key.count > 10
    }
}

// MARK: - Event Taxonomy

enum AnalyticsEvent {
    case signedUp(method: AnalyticsAuthMethod)
    case signedIn(method: AnalyticsAuthMethod)
    case signedOut
    case accountDeleted
    case onboardingStarted
    case onboardingCompleted(goalCount: Int, healthGoals: [String])
    case planGenerated(supplementCount: Int, source: AnalyticsPlanSource)
    case paywallShown(source: String)
    case subscribed(plan: String, source: String)
    case checkInCompleted(wellbeingScore: Double, supplementsLogged: Int, supplementsTotal: Int)
    case supplementLogged(name: String, taken: Bool, source: AnalyticsLogSource)

    var name: String {
        switch self {
        case .signedUp:             return "signed_up"
        case .signedIn:             return "signed_in"
        case .signedOut:            return "signed_out"
        case .accountDeleted:       return "account_deleted"
        case .onboardingStarted:    return "onboarding_started"
        case .onboardingCompleted:  return "onboarding_completed"
        case .planGenerated:        return "plan_generated"
        case .paywallShown:         return "paywall_shown"
        case .subscribed:           return "subscribed"
        case .checkInCompleted:     return "check_in_completed"
        case .supplementLogged:     return "supplement_logged"
        }
    }

    var properties: [String: Any] {
        switch self {
        case .signedOut, .accountDeleted, .onboardingStarted:
            return [:]
        case .signedUp(let method), .signedIn(let method):
            return ["method": method.rawValue]
        case .onboardingCompleted(let goalCount, let healthGoals):
            return ["goal_count": goalCount, "health_goals": healthGoals]
        case .planGenerated(let supplementCount, let source):
            return ["supplement_count": supplementCount, "source": source.rawValue]
        case .paywallShown(let source):
            return ["source": source]
        case .subscribed(let plan, let source):
            return ["plan": plan, "source": source]
        case .checkInCompleted(let wellbeingScore, let supplementsLogged, let supplementsTotal):
            return [
                "wellbeing_score": wellbeingScore,
                "supplements_logged": supplementsLogged,
                "supplements_total": supplementsTotal
            ]
        case .supplementLogged(let name, let taken, let source):
            return [
                "supplement_name": name,
                "taken": taken,
                "source": source.rawValue
            ]
        }
    }
}

enum AnalyticsAuthMethod: String {
    case email
    case apple
    case google
}

enum AnalyticsPlanSource: String {
    case onboarding
    case regenerate
}

enum AnalyticsLogSource: String {
    case today
    case backfill
}
