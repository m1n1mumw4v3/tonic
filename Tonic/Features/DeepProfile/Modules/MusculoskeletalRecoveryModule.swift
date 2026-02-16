import Foundation

enum MusculoskeletalRecoveryModule {
    static let config = DeepProfileModuleConfig(
        type: .musculoskeletalRecovery,
        introDescription: "Your movement patterns and recovery needs help us dial in performance supplements, joint support, and recovery aids.",
        questions: [
            DeepProfileQuestion(
                id: "recovery_exercise_type",
                text: "What type of exercise do you primarily do?",
                inputType: .singleSelect([
                    SelectOption(value: "strength", label: "Strength / resistance training"),
                    SelectOption(value: "cardio", label: "Cardio / endurance"),
                    SelectOption(value: "hiit", label: "HIIT / CrossFit-style"),
                    SelectOption(value: "yoga_mobility", label: "Yoga / Pilates / mobility"),
                    SelectOption(value: "sports", label: "Sports / recreational"),
                    SelectOption(value: "mixed", label: "Mixed"),
                ])
            ),
            DeepProfileQuestion(
                id: "recovery_soreness",
                text: "How quickly do you recover from workouts?",
                inputType: .singleSelect([
                    SelectOption(value: "next_day", label: "Ready the next day"),
                    SelectOption(value: "two_days", label: "Need about 2 days"),
                    SelectOption(value: "three_plus", label: "Takes 3+ days"),
                    SelectOption(value: "always_sore", label: "I'm always somewhat sore"),
                ])
            ),
            DeepProfileQuestion(
                id: "recovery_joint_pain",
                text: "Do you experience joint pain or stiffness?",
                inputType: .singleSelect([
                    SelectOption(value: "chronic", label: "Yes, chronic / daily"),
                    SelectOption(value: "exercise_related", label: "Mainly after exercise"),
                    SelectOption(value: "occasional", label: "Occasional"),
                    SelectOption(value: "none", label: "No"),
                ])
            ),
            DeepProfileQuestion(
                id: "recovery_injury_history",
                text: "Do you have any recurring injuries or weak spots?",
                inputType: .singleSelect([
                    SelectOption(value: "active_injury", label: "Yes, currently managing one"),
                    SelectOption(value: "past_injury", label: "Past injury that flares up"),
                    SelectOption(value: "general_tightness", label: "General tightness / imbalance"),
                    SelectOption(value: "none", label: "No significant issues"),
                ])
            ),
            DeepProfileQuestion(
                id: "recovery_protein_intake",
                text: "How would you rate your daily protein intake?",
                subtext: "Protein needs affect supplement stacking for recovery",
                inputType: .singleSelect([
                    SelectOption(value: "high", label: "High (I track it carefully)"),
                    SelectOption(value: "moderate", label: "Moderate (eat protein at most meals)"),
                    SelectOption(value: "low", label: "Low (could be better)"),
                    SelectOption(value: "unsure", label: "Not sure"),
                ])
            ),
        ]
    )
}
