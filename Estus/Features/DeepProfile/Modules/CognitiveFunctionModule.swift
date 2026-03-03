import Foundation

enum CognitiveFunctionModule {
    static let config = DeepProfileModuleConfig(
        type: .cognitiveFunction,
        introDescription: "Your cognitive patterns help us recommend the right nootropics, focus aids, and neuroprotective compounds.",
        questions: [
            DeepProfileQuestion(
                id: "cognitive_focus_duration",
                text: "How long can you typically focus on a single task without distraction?",
                inputType: .singleSelect([
                    SelectOption(value: "under_15", label: "Under 15 minutes"),
                    SelectOption(value: "15_30", label: "15-30 minutes"),
                    SelectOption(value: "30_60", label: "30-60 minutes"),
                    SelectOption(value: "60_plus", label: "60+ minutes"),
                ])
            ),
            DeepProfileQuestion(
                id: "cognitive_brain_fog",
                text: "How often do you experience brain fog?",
                subtext: "Difficulty thinking clearly, feeling mentally sluggish",
                inputType: .singleSelect([
                    SelectOption(value: "daily", label: "Daily"),
                    SelectOption(value: "several_weekly", label: "Several times a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely", label: "Rarely or never"),
                ])
            ),
            DeepProfileQuestion(
                id: "cognitive_memory",
                text: "Have you noticed changes in your memory recently?",
                inputType: .singleSelect([
                    SelectOption(value: "significant_decline", label: "Noticeable decline"),
                    SelectOption(value: "slight_decline", label: "Slight decline"),
                    SelectOption(value: "stable", label: "About the same"),
                    SelectOption(value: "improving", label: "Improving"),
                ])
            ),
            DeepProfileQuestion(
                id: "cognitive_train_of_thought",
                text: "How easily do you lose your train of thought mid-task?",
                inputType: .singleSelect([
                    SelectOption(value: "very_easily", label: "Very easily"),
                    SelectOption(value: "somewhat_easily", label: "Somewhat easily"),
                    SelectOption(value: "not_very", label: "Not very easily"),
                    SelectOption(value: "rarely", label: "Rarely"),
                ])
            ),
            DeepProfileQuestion(
                id: "cognitive_adhd",
                text: "Have you been diagnosed with or suspect you have ADHD?",
                inputType: .singleSelect([
                    SelectOption(value: "yes_diagnosed", label: "Yes, diagnosed"),
                    SelectOption(value: "suspect", label: "I suspect so"),
                    SelectOption(value: "no", label: "No"),
                ])
            ),
            DeepProfileQuestion(
                id: "cognitive_sleep_hours",
                text: "How many hours of sleep do you average per night?",
                inputType: .singleSelect([
                    SelectOption(value: "under_5", label: "Under 5 hours"),
                    SelectOption(value: "5_6", label: "5-6 hours"),
                    SelectOption(value: "6_7", label: "6-7 hours"),
                    SelectOption(value: "7_8", label: "7-8 hours"),
                    SelectOption(value: "over_8", label: "Over 8 hours"),
                ])
            ),
            DeepProfileQuestion(
                id: "cognitive_peak_hours",
                text: "When is your mental sharpness at its peak?",
                inputType: .singleSelect([
                    SelectOption(value: "early_morning", label: "Early morning (6-9 AM)"),
                    SelectOption(value: "late_morning", label: "Late morning (9 AM-12 PM)"),
                    SelectOption(value: "afternoon", label: "Afternoon (12-5 PM)"),
                    SelectOption(value: "evening", label: "Evening (5-10 PM)"),
                    SelectOption(value: "no_pattern", label: "No consistent pattern"),
                ])
            ),
            DeepProfileQuestion(
                id: "cognitive_caffeine_reliance",
                text: "How reliant are you on caffeine for mental performance?",
                inputType: .singleSelect([
                    SelectOption(value: "cant_function", label: "Can't function without it"),
                    SelectOption(value: "helps_a_lot", label: "Helps a lot"),
                    SelectOption(value: "mild_boost", label: "Mild boost"),
                    SelectOption(value: "dont_use", label: "I don't use caffeine"),
                ])
            ),
        ]
    )
}
