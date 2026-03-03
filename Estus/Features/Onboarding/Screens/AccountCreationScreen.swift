import SwiftUI
import AuthenticationServices

struct AccountCreationScreen: View {
    @Environment(AppState.self) private var appState
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var showEmailForm = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var focusedField: Field?
    @State private var errorMessage: String?
    @State private var showSignInSheet = false
    @State private var showPreview = false
    @State private var isAuthenticating = false

    private enum Field: Hashable {
        case email, password, confirmPassword
    }

    // MARK: - Computed Properties

    private var weakestDimensions: [WellnessDimension] {
        let scores: [(WellnessDimension, Double)] = [
            (.sleep, viewModel.baselineSleep),
            (.energy, viewModel.baselineEnergy),
            (.clarity, viewModel.baselineClarity),
            (.mood, viewModel.baselineMood),
            (.gut, viewModel.baselineGut)
        ]
        let sorted = scores.sorted { $0.1 < $1.1 }
        return [sorted[0].0, sorted[1].0]
    }

    private var insightText: String {
        let allEqual = viewModel.baselineSleep == viewModel.baselineEnergy
            && viewModel.baselineEnergy == viewModel.baselineClarity
            && viewModel.baselineClarity == viewModel.baselineMood
            && viewModel.baselineMood == viewModel.baselineGut
        if allEqual {
            return "Your plan will be balanced across all wellness dimensions."
        }
        let dims = weakestDimensions
        return "Your \(dims[0].label.lowercased()) and \(dims[1].label.lowercased()) scores have the most room for growth."
    }

    private var sortedGoals: [HealthGoal] {
        Array(viewModel.healthGoals).sorted { $0.rawValue < $1.rawValue }
    }

    private var snapshotLabel: String {
        "YOUR BASELINE"
    }

    private var isEmailValid: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private var isPasswordValid: Bool {
        password.count >= 8
    }

    private var doPasswordsMatch: Bool {
        password == confirmPassword && !confirmPassword.isEmpty
    }

    private var isFormValid: Bool {
        isEmailValid && isPasswordValid && doPasswordsMatch
    }

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignTokens.spacing24) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                        HeadlineText(text: "Ready to build your plan")
                        Text("Create an account and we'll get started.")
                            .font(DesignTokens.bodyFont)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing16)

                    // Wellbeing preview
                    VStack(spacing: DesignTokens.spacing24) {
                        WellbeingScoreRing(
                            sleepScore: Int(viewModel.baselineSleep),
                            energyScore: Int(viewModel.baselineEnergy),
                            clarityScore: Int(viewModel.baselineClarity),
                            moodScore: Int(viewModel.baselineMood),
                            gutScore: Int(viewModel.baselineGut),
                            size: 160,
                            lineWidth: 12,
                            animated: true
                        )

                        if !sortedGoals.isEmpty {
                            VStack(alignment: .leading, spacing: DesignTokens.spacing8) {
                                Text("YOUR GOALS")
                                    .font(DesignTokens.labelMono)
                                    .tracking(1.5)
                                    .foregroundStyle(DesignTokens.textTertiary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: DesignTokens.spacing8) {
                                        ForEach(sortedGoals, id: \.self) { goal in
                                            goalPill(for: goal)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.vertical, DesignTokens.spacing8)
                    .opacity(showPreview ? 1 : 0)
                    .offset(y: showPreview ? 0 : 20)

                    // Error banner
                    if let errorMessage {
                        Text(errorMessage)
                            .font(DesignTokens.captionFont)
                            .foregroundStyle(.white)
                            .padding(DesignTokens.spacing12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(DesignTokens.negative)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                            .padding(.horizontal, DesignTokens.spacing24)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if !showEmailForm {
                        // Auth buttons
                        VStack(spacing: DesignTokens.spacing12) {
                            // Sign in with Apple
                            AppleSignInButton(label: "Continue with Apple") { request in
                                request.requestedScopes = [.email, .fullName]
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .disabled(isAuthenticating)

                            // Sign in with Google
                            Button(action: handleGoogleSignIn) {
                                HStack(spacing: DesignTokens.spacing8) {
                                    if isAuthenticating {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image("GoogleLogo")
                                            .renderingMode(.original)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                    }
                                    Text("Continue with Google")
                                        .font(DesignTokens.ctaFont)
                                        .tracking(0.32)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                        .stroke(DesignTokens.borderDefault, lineWidth: 1)
                                )
                            }
                            .buttonStyle(CTAPressStyle())
                            .disabled(isAuthenticating)

                            // Email option
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmailForm = true
                                }
                            }) {
                                HStack(spacing: DesignTokens.spacing8) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 18))
                                    Text("Continue with Email")
                                        .font(DesignTokens.ctaFont)
                                        .tracking(0.32)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                        .stroke(DesignTokens.borderDefault, lineWidth: 1)
                                )
                            }
                            .buttonStyle(CTAPressStyle())
                            .disabled(isAuthenticating)
                        }
                        .padding(.horizontal, DesignTokens.spacing24)
                        .transition(.opacity)
                    } else {
                        // Email form
                        VStack(spacing: DesignTokens.spacing16) {
                            // Email field
                            TextField("", text: $email, prompt: Text("Email address").foregroundStyle(DesignTokens.textSecondary))
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .padding(DesignTokens.spacing16)
                                .background(DesignTokens.bgSurface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                        .stroke(
                                            focusedField == .email ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                                            lineWidth: 1
                                        )
                                )
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .onTapGesture { focusedField = .email }

                            // Password field
                            VStack(alignment: .leading, spacing: DesignTokens.spacing4) {
                                SecureField("", text: $password, prompt: Text("Password").foregroundStyle(DesignTokens.textSecondary))
                                    .font(DesignTokens.bodyFont)
                                    .foregroundStyle(DesignTokens.textPrimary)
                                    .padding(DesignTokens.spacing16)
                                    .background(DesignTokens.bgSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                            .stroke(
                                                focusedField == .password ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                                                lineWidth: 1
                                            )
                                    )
                                    .textContentType(.newPassword)
                                    .onTapGesture { focusedField = .password }

                                Text("At least 8 characters")
                                    .font(DesignTokens.captionFont)
                                    .foregroundStyle(DesignTokens.textTertiary)
                                    .padding(.leading, DesignTokens.spacing4)
                            }

                            // Confirm password field
                            SecureField("", text: $confirmPassword, prompt: Text("Confirm password").foregroundStyle(DesignTokens.textSecondary))
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .padding(DesignTokens.spacing16)
                                .background(DesignTokens.bgSurface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                        .stroke(
                                            focusedField == .confirmPassword ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                                            lineWidth: 1
                                        )
                                )
                                .textContentType(.newPassword)
                                .onTapGesture { focusedField = .confirmPassword }

                            // Create account CTA
                            CTAButton(title: isAuthenticating ? "Creating account..." : "Create account", style: .primary, action: handleEmailSignUp)
                                .opacity(isFormValid && !isAuthenticating ? 1.0 : 0.4)
                                .disabled(!isFormValid || isAuthenticating)

                            // Back to other sign-in options
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showEmailForm = false
                                }
                            }) {
                                Text("Other sign-in options")
                                    .font(DesignTokens.bodyFont)
                                    .foregroundStyle(DesignTokens.textSecondary)
                            }
                        }
                        .padding(.horizontal, DesignTokens.spacing24)
                        .transition(.opacity)
                    }

                    Spacer(minLength: DesignTokens.spacing16)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: DesignTokens.spacing12) {
                    // Sign in link
                    Button(action: { showSignInSheet = true }) {
                        HStack(spacing: DesignTokens.spacing4) {
                            Text("Already have an account?")
                                .foregroundStyle(DesignTokens.textTertiary)
                            Text("Sign in")
                                .underline()
                                .foregroundStyle(DesignTokens.accentClarity)
                        }
                        .font(DesignTokens.captionFont)
                    }

                    Text(termsAttributedString)
                        .font(DesignTokens.captionFont)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.spacing24)
                }
                .padding(.top, DesignTokens.spacing12)
                .padding(.bottom, DesignTokens.spacing16)
                .frame(maxWidth: .infinity)
                .background(DesignTokens.bgDeepest)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    showPreview = true
                }
            }
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInSheet(appState: appState, viewModel: viewModel, onSignIn: {
                showSignInSheet = false
                onContinue()
            })
        }
    }

    // MARK: - Goal Pill

    @ViewBuilder
    private func goalPill(for goal: HealthGoal) -> some View {
        HStack(spacing: DesignTokens.spacing4) {
            Image(systemName: goal.icon)
                .font(.system(size: 11))
            Text(goal.shortLabel)
                .font(DesignTokens.captionFont)
        }
        .foregroundStyle(goal.accentColor)
        .padding(.horizontal, DesignTokens.spacing12)
        .padding(.vertical, DesignTokens.spacing8)
        .background(goal.accentColor.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(goal.accentColor.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Terms Attributed String

    private var termsAttributedString: AttributedString {
        var full = AttributedString("By continuing, you agree to our Terms of Service and Privacy Policy")
        full.foregroundColor = UIColor(DesignTokens.textTertiary)

        if let termsRange = full.range(of: "Terms of Service") {
            full[termsRange].underlineStyle = .single
        }
        if let privacyRange = full.range(of: "Privacy Policy") {
            full[privacyRange].underlineStyle = .single
        }

        return full
    }

    // MARK: - Auth Handlers

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                withAnimation { errorMessage = "Unable to process Apple sign-in. Please try again." }
                return
            }

            let fullName = credential.fullName

            isAuthenticating = true
            Task {
                defer { isAuthenticating = false }
                do {
                    try await appState.authService.signInWithApple(idToken: idToken, fullName: fullName)
                    viewModel.accountCreated = true
                    viewModel.accountProvider = "apple"
                    if let email = appState.authService.userEmail {
                        viewModel.accountEmail = email
                    }
                    onContinue()
                } catch {
                    withAnimation {
                        errorMessage = appState.authService.authError ?? "Sign in failed. Please try again."
                    }
                }
            }

        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            withAnimation {
                errorMessage = "Sign in failed. Please try again."
            }
        }
    }

    private func handleGoogleSignIn() {
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            do {
                try await appState.authService.signInWithGoogle()
                viewModel.accountCreated = true
                viewModel.accountProvider = "google"
                if let email = appState.authService.userEmail {
                    viewModel.accountEmail = email
                }
                onContinue()
            } catch {
                withAnimation {
                    errorMessage = appState.authService.authError ?? "Sign in failed. Please try again."
                }
            }
        }
    }

    private func handleEmailSignUp() {
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            do {
                try await appState.authService.signUp(email: email, password: password)
                viewModel.accountCreated = true
                viewModel.accountEmail = email
                viewModel.accountProvider = "email"
                onContinue()
            } catch {
                withAnimation {
                    errorMessage = appState.authService.authError ?? "Sign up failed. Please try again."
                }
            }
        }
    }
}

// MARK: - Sign In Sheet

private struct SignInSheet: View {
    var appState: AppState
    var viewModel: OnboardingViewModel
    let onSignIn: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var focusedField: Field?
    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    private enum Field: Hashable {
        case email, password
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bgDeepest.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.spacing24) {
                        Spacer()
                            .frame(height: DesignTokens.spacing24)

                        HeadlineText(text: "Welcome back")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignTokens.spacing24)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(DesignTokens.captionFont)
                                .foregroundStyle(.white)
                                .padding(DesignTokens.spacing12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DesignTokens.negative)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusSmall))
                                .padding(.horizontal, DesignTokens.spacing24)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        VStack(spacing: DesignTokens.spacing16) {
                            // Email
                            TextField("", text: $email, prompt: Text("Email address").foregroundStyle(DesignTokens.textSecondary))
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .padding(DesignTokens.spacing16)
                                .background(DesignTokens.bgSurface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                        .stroke(
                                            focusedField == .email ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                                            lineWidth: 1
                                        )
                                )
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .onTapGesture { focusedField = .email }

                            // Password
                            SecureField("", text: $password, prompt: Text("Password").foregroundStyle(DesignTokens.textSecondary))
                                .font(DesignTokens.bodyFont)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .padding(DesignTokens.spacing16)
                                .background(DesignTokens.bgSurface)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                        .stroke(
                                            focusedField == .password ? DesignTokens.accentClarity : DesignTokens.borderDefault,
                                            lineWidth: 1
                                        )
                                )
                                .textContentType(.password)
                                .onTapGesture { focusedField = .password }

                            // Sign in CTA
                            CTAButton(title: isAuthenticating ? "Signing in..." : "Sign in", style: .primary) {
                                handleEmailSignIn()
                            }
                            .opacity(isFormValid && !isAuthenticating ? 1.0 : 0.4)
                            .disabled(!isFormValid || isAuthenticating)
                        }
                        .padding(.horizontal, DesignTokens.spacing24)

                        // Alternative sign-in options
                        VStack(spacing: DesignTokens.spacing12) {
                            dividerRow

                            AppleSignInButton(label: "Sign in with Apple") { request in
                                request.requestedScopes = [.email, .fullName]
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .disabled(isAuthenticating)

                            Button(action: handleGoogleSignIn) {
                                HStack(spacing: DesignTokens.spacing8) {
                                    Image("GoogleLogo")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                    Text("Continue with Google")
                                        .font(DesignTokens.ctaFont)
                                        .tracking(0.32)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .foregroundStyle(DesignTokens.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                                        .stroke(DesignTokens.borderDefault, lineWidth: 1)
                                )
                            }
                            .buttonStyle(CTAPressStyle())
                            .disabled(isAuthenticating)
                        }
                        .padding(.horizontal, DesignTokens.spacing24)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {}
                        .font(DesignTokens.bodyFont)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
            .interactiveDismissDisabled(false)
        }
    }

    private var dividerRow: some View {
        HStack(spacing: DesignTokens.spacing12) {
            Rectangle()
                .fill(DesignTokens.borderDefault)
                .frame(height: 1)
            Text("or")
                .font(DesignTokens.captionFont)
                .foregroundStyle(DesignTokens.textTertiary)
            Rectangle()
                .fill(DesignTokens.borderDefault)
                .frame(height: 1)
        }
        .padding(.vertical, DesignTokens.spacing4)
    }

    // MARK: - Auth Handlers

    private func handleEmailSignIn() {
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            do {
                try await appState.authService.signIn(email: email, password: password)
                viewModel.accountCreated = true
                viewModel.accountEmail = email
                viewModel.accountProvider = "email"
                onSignIn()
            } catch {
                withAnimation {
                    errorMessage = appState.authService.authError ?? "Sign in failed. Please try again."
                }
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                withAnimation { errorMessage = "Unable to process Apple sign-in. Please try again." }
                return
            }

            let fullName = credential.fullName

            isAuthenticating = true
            Task {
                defer { isAuthenticating = false }
                do {
                    try await appState.authService.signInWithApple(idToken: idToken, fullName: fullName)
                    viewModel.accountCreated = true
                    viewModel.accountProvider = "apple"
                    if let email = appState.authService.userEmail {
                        viewModel.accountEmail = email
                    }
                    onSignIn()
                } catch {
                    withAnimation {
                        errorMessage = appState.authService.authError ?? "Sign in failed. Please try again."
                    }
                }
            }

        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            withAnimation {
                errorMessage = "Sign in failed. Please try again."
            }
        }
    }

    private func handleGoogleSignIn() {
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            do {
                try await appState.authService.signInWithGoogle()
                viewModel.accountCreated = true
                viewModel.accountProvider = "google"
                if let email = appState.authService.userEmail {
                    viewModel.accountEmail = email
                }
                onSignIn()
            } catch {
                withAnimation {
                    errorMessage = appState.authService.authError ?? "Sign in failed. Please try again."
                }
            }
        }
    }
}

// MARK: - Custom Apple Sign In Button

private struct AppleSignInButton: View {
    let label: String
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    init(
        label: String,
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
    ) {
        self.label = label
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }

    var body: some View {
        ZStack {
            // Hidden native button to trigger Apple Sign In
            SignInWithAppleButton(.continue, onRequest: onRequest, onCompletion: onCompletion)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
                .opacity(0.011) // Nearly invisible but still tappable

            // Custom visual overlay
            HStack(spacing: DesignTokens.spacing8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 22, weight: .medium))
                Text(label)
                    .font(DesignTokens.ctaFont)
                    .tracking(0.32)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(DesignTokens.textPrimary)
            .foregroundStyle(DesignTokens.bgDeepest)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
            .allowsHitTesting(false)
        }
        .buttonStyle(CTAPressStyle())
    }
}

#Preview {
    AccountCreationScreen(viewModel: OnboardingViewModel(), onContinue: {})
        .environment(AppState())
}
