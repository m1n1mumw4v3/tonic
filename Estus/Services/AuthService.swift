import Foundation
import Supabase
import Auth

@Observable
class AuthService {
    var currentSession: Session?
    var isLoading: Bool = true
    var authError: String?

    var isAuthenticated: Bool {
        currentSession != nil
    }

    var supabaseUserId: UUID? {
        currentSession?.user.id
    }

    var userEmail: String? {
        currentSession?.user.email
    }

    private var client: SupabaseClient {
        AppConfiguration.supabaseClient
    }

    // MARK: - Auth State Listener

    @MainActor
    func startListening() async {
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .initialSession:
                currentSession = session
                isLoading = false
            case .signedIn:
                currentSession = session
            case .signedOut:
                currentSession = nil
            case .tokenRefreshed:
                currentSession = session
            default:
                break
            }
        }
    }

    // MARK: - Email Auth

    @MainActor
    func signUp(email: String, password: String) async throws {
        authError = nil
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            currentSession = response.session
        } catch {
            authError = mapAuthError(error)
            throw error
        }
    }

    @MainActor
    func signIn(email: String, password: String) async throws {
        authError = nil
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            currentSession = session
        } catch {
            authError = mapAuthError(error)
            throw error
        }
    }

    // MARK: - Apple Sign In

    @MainActor
    func signInWithApple(idToken: String, fullName: PersonNameComponents?) async throws {
        authError = nil
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )
            currentSession = session

            // Apple only provides the full name on first sign-in, so persist it
            if let fullName, let givenName = fullName.givenName {
                let displayName = [givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                try? await client.auth.update(user: UserAttributes(data: [
                    "full_name": .string(displayName)
                ]))
            }
        } catch {
            authError = mapAuthError(error)
            throw error
        }
    }

    // MARK: - Google Sign In (OAuth)

    @MainActor
    func signInWithGoogle() async throws {
        authError = nil
        do {
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "com.estus.app://auth-callback")
            )
        } catch {
            authError = mapAuthError(error)
            throw error
        }
    }

    // MARK: - Sign Out

    @MainActor
    func signOut() async {
        do {
            try await client.auth.signOut()
            currentSession = nil
            authError = nil
        } catch {
            print("⚠️ [AuthService] Sign out error: \(error)")
            // Clear local session even if server call fails
            currentSession = nil
        }
    }

    // MARK: - Deep Link Handling

    @MainActor
    func handleDeepLink(_ url: URL) async {
        do {
            let session = try await client.auth.session(from: url)
            currentSession = session
        } catch {
            print("⚠️ [AuthService] Deep link handling error: \(error)")
            authError = mapAuthError(error)
        }
    }

    // MARK: - Error Mapping

    private func mapAuthError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()

        if message.contains("email already registered") || message.contains("user already registered") {
            return "An account with this email already exists. Try signing in instead."
        }
        if message.contains("invalid login credentials") || message.contains("invalid credentials") {
            return "Invalid email or password. Please try again."
        }
        if message.contains("email not confirmed") {
            return "Please check your email to confirm your account."
        }
        if message.contains("network") || message.contains("connection") || message.contains("offline") {
            return "Network error. Please check your connection and try again."
        }
        if message.contains("rate limit") || message.contains("too many requests") {
            return "Too many attempts. Please wait a moment and try again."
        }
        if message.contains("weak password") || message.contains("password") {
            return "Password must be at least 8 characters."
        }

        return "Something went wrong. Please try again."
    }
}
