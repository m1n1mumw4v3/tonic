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
                id: "cognitive_work_type",
                text: "What best describes your daily cognitive demands?",
                inputType: .singleSelect([
                    SelectOption(value: "creative", label: "Creative / ideation work"),
                    SelectOption(value: "analytical", label: "Analytical / problem-solving"),
                    SelectOption(value: "communication", label: "Communication / meetings-heavy"),
                    SelectOption(value: "mixed", label: "Mixed — all of the above"),
                    SelectOption(value: "physical", label: "Primarily physical work"),
                ])
            ),
        ]
    )
}
