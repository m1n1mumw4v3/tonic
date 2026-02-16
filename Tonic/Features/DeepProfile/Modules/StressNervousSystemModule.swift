import Foundation

enum StressNervousSystemModule {
    static let config = DeepProfileModuleConfig(
        type: .stressNervousSystem,
        introDescription: "Understanding your stress patterns helps us recommend the right adaptogens, calming agents, and nervous system support.",
        questions: [
            DeepProfileQuestion(
                id: "stress_physical_symptoms",
                text: "Which physical stress symptoms do you experience regularly?",
                inputType: .multiSelect([
                    SelectOption(value: "tension_headaches", label: "Tension headaches"),
                    SelectOption(value: "jaw_clenching", label: "Jaw clenching / teeth grinding"),
                    SelectOption(value: "muscle_tension", label: "Neck / shoulder tension"),
                    SelectOption(value: "racing_heart", label: "Racing heart"),
                    SelectOption(value: "shallow_breathing", label: "Shallow breathing"),
                    SelectOption(value: "none", label: "None of these"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_anxiety_frequency",
                text: "How often do you feel anxious or on edge?",
                inputType: .singleSelect([
                    SelectOption(value: "daily", label: "Daily"),
                    SelectOption(value: "several_weekly", label: "Several times a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely", label: "Rarely"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_recovery_method",
                text: "What's your primary way of unwinding?",
                inputType: .singleSelect([
                    SelectOption(value: "exercise", label: "Exercise / physical activity"),
                    SelectOption(value: "meditation", label: "Meditation / breathwork"),
                    SelectOption(value: "social", label: "Socializing"),
                    SelectOption(value: "entertainment", label: "TV / gaming / scrolling"),
                    SelectOption(value: "nature", label: "Time in nature"),
                    SelectOption(value: "nothing", label: "I don't have a go-to method"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_caffeine_sensitivity",
                text: "How sensitive are you to caffeine?",
                subtext: "Affects adaptogens and stimulant-adjacent recommendations",
                inputType: .singleSelect([
                    SelectOption(value: "very_sensitive", label: "Very sensitive (jittery, can't sleep)"),
                    SelectOption(value: "moderate", label: "Moderate (fine with 1-2 cups)"),
                    SelectOption(value: "low", label: "Low (can drink coffee anytime)"),
                    SelectOption(value: "unsure", label: "Not sure"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_sleep_racing_mind",
                text: "Do racing thoughts keep you awake at night?",
                inputType: .singleSelect([
                    SelectOption(value: "most_nights", label: "Most nights"),
                    SelectOption(value: "several_weekly", label: "Several nights a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely", label: "Rarely or never"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_burnout_level",
                text: "How close to burnout do you feel right now?",
                inputType: .singleSelect([
                    SelectOption(value: "burned_out", label: "I'm already there"),
                    SelectOption(value: "close", label: "Getting close"),
                    SelectOption(value: "managing", label: "Managing, but stretched thin"),
                    SelectOption(value: "balanced", label: "Feeling balanced"),
                ])
            ),
        ]
    )
}
