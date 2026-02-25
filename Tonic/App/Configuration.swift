import Foundation
import Supabase

enum SupabaseConfig {
    static let supabaseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL not set. Copy Secrets.xcconfig.template to Secrets.xcconfig and fill in your values.")
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not set. Copy Secrets.xcconfig.template to Secrets.xcconfig and fill in your values.")
        }
        return key
    }()

    static let supabaseClient = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )
}
