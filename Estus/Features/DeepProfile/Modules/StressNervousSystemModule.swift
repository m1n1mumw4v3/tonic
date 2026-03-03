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
                id: "stress_panic_attacks",
                text: "Have you ever experienced panic attacks?",
                inputType: .singleSelect([
                    SelectOption(value: "yes_currently", label: "Yes, currently"),
                    SelectOption(value: "yes_past", label: "Yes, in the past"),
                    SelectOption(value: "no", label: "No"),
                    SelectOption(value: "not_sure", label: "Not sure"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_psych_medications",
                text: "Are you currently taking any psychiatric medications?",
                subtext: "Important for safe supplement recommendations — some supplements interact with these medications",
                inputType: .singleSelect([
                    SelectOption(value: "ssri_snri", label: "SSRI / SNRI"),
                    SelectOption(value: "benzodiazepine", label: "Benzodiazepine"),
                    SelectOption(value: "buspirone", label: "Buspirone"),
                    SelectOption(value: "other", label: "Other"),
                    SelectOption(value: "none", label: "None"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_emotional_resilience",
                text: "How would you describe your emotional resilience right now?",
                inputType: .singleSelect([
                    SelectOption(value: "strong", label: "Strong"),
                    SelectOption(value: "adequate", label: "Adequate"),
                    SelectOption(value: "fragile", label: "Fragile"),
                    SelectOption(value: "depleted", label: "Depleted"),
                ])
            ),
            DeepProfileQuestion(
                id: "stress_chronic_tension",
                text: "Do you carry chronic muscle tension (neck, shoulders, jaw)?",
                inputType: .singleSelect([
                    SelectOption(value: "frequently", label: "Frequently"),
                    SelectOption(value: "sometimes", label: "Sometimes"),
                    SelectOption(value: "rarely", label: "Rarely"),
                    SelectOption(value: "never", label: "Never"),
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
