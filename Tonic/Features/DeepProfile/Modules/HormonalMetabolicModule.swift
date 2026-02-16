import Foundation

enum HormonalMetabolicModule {
    static let config = DeepProfileModuleConfig(
        type: .hormonalMetabolic,
        introDescription: "Hormonal and metabolic factors significantly influence which supplements will be most effective for you.",
        disclaimer: "This survey does not replace bloodwork or medical evaluation. Consult a provider for hormonal concerns.",
        questions: [
            DeepProfileQuestion(
                id: "hormonal_energy_pattern",
                text: "When does your energy typically dip the most?",
                inputType: .singleSelect([
                    SelectOption(value: "morning", label: "Morning (hard to get going)"),
                    SelectOption(value: "early_afternoon", label: "Early afternoon (post-lunch crash)"),
                    SelectOption(value: "late_afternoon", label: "Late afternoon (3-5 PM wall)"),
                    SelectOption(value: "evening", label: "Evening (exhausted after work)"),
                    SelectOption(value: "consistent", label: "Fairly consistent throughout the day"),
                ])
            ),
            DeepProfileQuestion(
                id: "hormonal_cold_sensitivity",
                text: "Do you often feel cold when others are comfortable?",
                subtext: "Can indicate thyroid or metabolic factors",
                inputType: .singleSelect([
                    SelectOption(value: "yes_often", label: "Yes, often"),
                    SelectOption(value: "sometimes", label: "Sometimes"),
                    SelectOption(value: "rarely", label: "Rarely"),
                    SelectOption(value: "no", label: "No"),
                ])
            ),
            DeepProfileQuestion(
                id: "hormonal_weight_change",
                text: "Have you experienced unexplained weight changes in the past 6 months?",
                inputType: .singleSelect([
                    SelectOption(value: "gained", label: "Yes, gained weight"),
                    SelectOption(value: "lost", label: "Yes, lost weight"),
                    SelectOption(value: "fluctuating", label: "Fluctuating up and down"),
                    SelectOption(value: "stable", label: "No, relatively stable"),
                ])
            ),
            DeepProfileQuestion(
                id: "hormonal_blood_sugar",
                text: "Do you get shaky, irritable, or lightheaded if you skip a meal?",
                subtext: "Can indicate blood sugar regulation patterns",
                inputType: .singleSelect([
                    SelectOption(value: "yes_frequently", label: "Yes, frequently"),
                    SelectOption(value: "sometimes", label: "Sometimes"),
                    SelectOption(value: "rarely", label: "Rarely"),
                    SelectOption(value: "never", label: "Never"),
                ])
            ),
            // Female-only: menstrual cycle
            DeepProfileQuestion(
                id: "hormonal_menstrual_regularity",
                text: "How would you describe your menstrual cycle?",
                inputType: .singleSelect([
                    SelectOption(value: "regular", label: "Regular (25-35 days)"),
                    SelectOption(value: "irregular", label: "Irregular"),
                    SelectOption(value: "absent", label: "Absent"),
                    SelectOption(value: "perimenopause", label: "Perimenopause / changing"),
                    SelectOption(value: "postmenopause", label: "Post-menopause"),
                ]),
                condition: QuestionCondition { profile, _ in
                    profile.sex == .female
                }
            ),
            // Female-only: PMS symptoms
            DeepProfileQuestion(
                id: "hormonal_pms_symptoms",
                text: "Do you experience significant PMS symptoms?",
                subtext: "• Bloating\n• Mood swings\n• Cramps\n• Breast tenderness",
                inputType: .singleSelect([
                    SelectOption(value: "severe", label: "Severe — affects daily life"),
                    SelectOption(value: "moderate", label: "Moderate"),
                    SelectOption(value: "mild", label: "Mild"),
                    SelectOption(value: "none", label: "None or minimal"),
                ]),
                condition: QuestionCondition { profile, _ in
                    profile.sex == .female
                }
            ),
            // Male, age >= 30: testosterone indicators
            DeepProfileQuestion(
                id: "hormonal_low_t_signs",
                text: "Have you noticed any of these changes recently?",
                subtext: "• Reduced muscle mass\n• Lower libido\n• Increased fatigue\n• Brain fog",
                inputType: .singleSelect([
                    SelectOption(value: "several", label: "Yes, several of these"),
                    SelectOption(value: "one_or_two", label: "One or two"),
                    SelectOption(value: "none", label: "None of these"),
                ]),
                condition: QuestionCondition { profile, _ in
                    profile.sex == .male && profile.age >= 30
                }
            ),
        ]
    )
}
