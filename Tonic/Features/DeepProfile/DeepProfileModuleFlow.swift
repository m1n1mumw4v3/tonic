import SwiftUI

struct DeepProfileModuleFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let moduleType: DeepProfileModuleType
    @State private var viewModel: DeepProfileFlowViewModel?
    @State private var showCompletion = false
    @State private var navigatingForward = true

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            if let vm = viewModel {
                if showCompletion {
                    DeepProfileCompletionScreen(moduleType: moduleType) {
                        dismiss()
                    }
                    .transition(.opacity)
                } else if vm.showIntro {
                    DeepProfileIntroScreen(config: vm.config) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            vm.dismissIntro()
                        }
                    } onDismiss: {
                        dismiss()
                    }
                    .transition(.opacity)
                } else if let question = vm.currentQuestion {
                    VStack(spacing: 0) {
                        // Navigation bar
                        HStack(spacing: DesignTokens.spacing12) {
                            if vm.canGoBack {
                                Button {
                                    navigatingForward = false
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        vm.goBack()
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(DesignTokens.textPrimary)
                                }
                            } else {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(DesignTokens.textSecondary)
                                }
                            }

                            SpectrumBar(progress: vm.progress)
                                .tint(moduleType.accentColor)

                            Text(vm.stepLabel)
                                .font(DesignTokens.labelMono)
                                .foregroundStyle(DesignTokens.textTertiary)
                        }
                        .padding(.horizontal, DesignTokens.spacing16)
                        .padding(.top, DesignTokens.spacing8)

                        DeepProfileQuestionScreen(
                            question: question,
                            accentColor: moduleType.accentColor,
                            viewModel: vm,
                            onComplete: {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    showCompletion = true
                                }
                                saveModule()
                            }
                        )
                        .id(question.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: navigatingForward ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: navigatingForward ? .leading : .trailing).combined(with: .opacity)
                        ))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel?.currentQuestionIndex)
        .animation(.easeInOut(duration: 0.35), value: showCompletion)
        .onAppear {
            guard let profile = appState.currentUser else { return }
            let existing = appState.deepProfileService.responses(for: moduleType)
            viewModel = DeepProfileFlowViewModel(
                moduleType: moduleType,
                userProfile: profile,
                existingResponses: existing
            )
        }
    }

    private func saveModule() {
        guard let vm = viewModel else { return }
        let module = vm.buildModule()
        appState.deepProfileService.saveModule(module)
        HapticManager.notification(.success)
    }
}
