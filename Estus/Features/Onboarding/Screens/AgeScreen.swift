import SwiftUI

struct AgeScreen: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let now = Date()
        let minDate = calendar.date(byAdding: .year, value: -100, to: now)!
        let maxDate = calendar.date(byAdding: .year, value: -18, to: now)!
        return minDate...maxDate
    }()

    var body: some View {
        ZStack {
            DesignTokens.bgDeepest.ignoresSafeArea()

            VStack(spacing: 0) {
                HeadlineText(text: "What's your date of birth?")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.top, DesignTokens.spacing24)

                Spacer()

                DatePicker(
                    "",
                    selection: Bindable(viewModel).dateOfBirth,
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.light)
                .padding(.horizontal, DesignTokens.spacing24)

                Spacer()

                CTAButton(title: "Next", style: .primary, action: onContinue)
                    .padding(.horizontal, DesignTokens.spacing24)
                    .padding(.bottom, DesignTokens.spacing48)
            }
        }
    }
}

#Preview {
    AgeScreen(viewModel: OnboardingViewModel(), onContinue: {})
}
