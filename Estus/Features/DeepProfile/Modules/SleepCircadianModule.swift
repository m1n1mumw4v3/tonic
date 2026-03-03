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
                id: "sleep_shift_work",
                text: "Do you do shift work or work overnight?",
                inputType: .singleSelect([
                    SelectOption(value: "no", label: "No"),
                    SelectOption(value: "yes_nights", label: "Yes, nights"),
                    SelectOption(value: "yes_rotating", label: "Yes, rotating"),
                ])
            ),
            DeepProfileQuestion(
                id: "sleep_restless_legs",
                text: "Do you experience restless legs or an urge to move your legs at night?",
                inputType: .singleSelect([
                    SelectOption(value: "frequently", label: "Frequently"),
                    SelectOption(value: "sometimes", label: "Sometimes"),
                    SelectOption(value: "rarely", label: "Rarely"),
                    SelectOption(value: "never", label: "Never"),
                ])
            ),
            DeepProfileQuestion(
                id: "sleep_bedroom_temp",
                text: "How would you describe your bedroom temperature?",
                inputType: .singleSelect([
                    SelectOption(value: "warm", label: "Warm"),
                    SelectOption(value: "cool", label: "Cool"),
                    SelectOption(value: "variable", label: "Variable"),
                ])
            ),
            DeepProfileQuestion(
                id: "sleep_last_caffeine",
                text: "When do you typically have your last caffeinated drink?",
                inputType: .singleSelect([
                    SelectOption(value: "before_noon", label: "Before noon"),
                    SelectOption(value: "early_afternoon", label: "Early afternoon"),
                    SelectOption(value: "late_afternoon", label: "Late afternoon"),
                    SelectOption(value: "evening", label: "Evening"),
                    SelectOption(value: "no_caffeine", label: "No caffeine"),
                ])
            ),
            DeepProfileQuestion(
                id: "sleep_racing_thoughts",
                text: "Do racing thoughts keep you awake at night?",
                inputType: .singleSelect([
                    SelectOption(value: "most_nights", label: "Most nights"),
                    SelectOption(value: "several_weekly", label: "Several nights a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely", label: "Rarely or never"),
                ])
            ),
        ]
    )
}
