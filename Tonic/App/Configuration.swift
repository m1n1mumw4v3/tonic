import Foundation
import Supabase

enum AppConfiguration {

    // MARK: - Supabase Client

    static let supabaseClient = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )

    // MARK: - Supabase

    static let supabaseURL: URL = {
        guard let string = Bundle.main.infoDictionary?["SupabaseURL"] as? String,
              let url = URL(string: string) else {
            fatalError("Missing or invalid SUPABASE_URL — check your xcconfig file")
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String, !key.isEmpty else {
            fatalError("Missing SUPABASE_ANON_KEY — check your xcconfig file")
        }
        return key
    }()

    // MARK: - RevenueCat

    static let revenueCatAPIKey: String = {
        guard let key = Bundle.main.infoDictionary?["RevenueCatAPIKey"] as? String, !key.isEmpty else {
            fatalError("Missing REVENUECAT_API_KEY — check your xcconfig file")
        }
        return key
    }()

    // MARK: - PostHog

    static let postHogAPIKey: String = {
        guard let key = Bundle.main.infoDictionary?["PostHogAPIKey"] as? String, !key.isEmpty else {
            fatalError("Missing POSTHOG_API_KEY — check your xcconfig file")
        }
        return key
    }()

    static let postHogHost: URL = {
        guard let string = Bundle.main.infoDictionary?["PostHogHost"] as? String,
              let url = URL(string: string) else {
            fatalError("Missing or invalid POSTHOG_HOST — check your xcconfig file")
        }
        return url
    }()
}
