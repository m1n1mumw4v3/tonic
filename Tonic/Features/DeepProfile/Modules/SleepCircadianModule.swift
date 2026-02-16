import Foundation

enum SleepCircadianModule {
    static let config = DeepProfileModuleConfig(
        type: .sleepCircadian,
        introDescription: "Understanding your sleep patterns helps us recommend the right compounds, dosages, and timing to improve sleep quality.",
        disclaimer: "This is not a sleep disorder screening. Consult a healthcare provider for persistent sleep issues.",
        questions: [
            DeepProfileQuestion(
                id: "sleep_bedtime",
                text: "What time do you usually go to bed?",
                inputType: .timeInput
            ),
            DeepProfileQuestion(
                id: "sleep_waketime",
                text: "What time do you usually wake up?",
                inputType: .timeInput
            ),
            DeepProfileQuestion(
                id: "sleep_onset_latency",
                text: "How long does it typically take you to fall asleep?",
                inputType: .singleSelect([
                    SelectOption(value: "under_10", label: "Under 10 minutes"),
                    SelectOption(value: "10_20", label: "10-20 minutes"),
                    SelectOption(value: "20_40", label: "20-40 minutes"),
                    SelectOption(value: "40_60", label: "40-60 minutes"),
                    SelectOption(value: "over_60", label: "Over 60 minutes"),
                ])
            ),
            DeepProfileQuestion(
                id: "sleep_wake_frequency",
                text: "How often do you wake up during the night?",
                inputType: .singleSelect([
                    SelectOption(value: "rarely", label: "Rarely or never"),
                    SelectOption(value: "once", label: "Once"),
                    SelectOption(value: "twice", label: "Twice"),
                    SelectOption(value: "three_plus", label: "3 or more times"),
                ])
            ),
            DeepProfileQuestion(
                id: "sleep_quality_perception",
                text: "How refreshed do you feel when you wake up?",
                inputType: .singleSelect([
                    SelectOption(value: "very_refreshed", label: "Very refreshed"),
                    SelectOption(value: "somewhat_refreshed", label: "Somewhat refreshed"),
                    SelectOption(value: "neutral", label: "Neutral"),
                    SelectOption(value: "somewhat_groggy", label: "Somewhat groggy"),
                    SelectOption(value: "very_groggy", label: "Very groggy"),
                ])
            ),
            DeepProfileQuestion(
                id: "sleep_screen_exposure",
                text: "Do you use screens (phone, TV, laptop) within an hour of bedtime?",
                inputType: .singleSelect([
                    SelectOption(value: "always", label: "Almost always"),
                    SelectOption(value: "often", label: "Often"),
                    SelectOption(value: "sometimes", label: "Sometimes"),
                    SelectOption(value: "rarely", label: "Rarely"),
                    SelectOption(value: "never", label: "Never"),
                ])
            ),
        ]
    )
}
