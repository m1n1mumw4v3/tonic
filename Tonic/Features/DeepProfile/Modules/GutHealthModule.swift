import Foundation

enum GutHealthModule {
    static let config = DeepProfileModuleConfig(
        type: .gutHealth,
        introDescription: "Your gut health influences nutrient absorption, immune function, and even mood. These questions help us tailor probiotic strains and digestive support.",
        disclaimer: "Not a diagnostic tool. See a gastroenterologist for persistent digestive issues.",
        questions: [
            DeepProfileQuestion(
                id: "gut_bowel_regularity",
                text: "How regular are your bowel movements?",
                inputType: .singleSelect([
                    SelectOption(value: "very_regular", label: "Very regular (daily, predictable)"),
                    SelectOption(value: "mostly_regular", label: "Mostly regular"),
                    SelectOption(value: "inconsistent", label: "Inconsistent"),
                    SelectOption(value: "frequently_constipated", label: "Frequently constipated"),
                    SelectOption(value: "frequently_loose", label: "Frequently loose/diarrhea"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_bloating",
                text: "How often do you experience bloating?",
                inputType: .singleSelect([
                    SelectOption(value: "daily", label: "Daily"),
                    SelectOption(value: "several_weekly", label: "Several times a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely", label: "Rarely"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_food_sensitivities",
                text: "Do you have known food sensitivities or intolerances?",
                inputType: .multiSelect([
                    SelectOption(value: "dairy", label: "Dairy / Lactose"),
                    SelectOption(value: "gluten", label: "Gluten"),
                    SelectOption(value: "fodmaps", label: "FODMAPs"),
                    SelectOption(value: "histamine", label: "Histamine-rich foods"),
                    SelectOption(value: "soy", label: "Soy"),
                    SelectOption(value: "none", label: "None that I know of"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_antibiotic_history",
                text: "Have you taken antibiotics in the past 6 months?",
                inputType: .singleSelect([
                    SelectOption(value: "multiple_courses", label: "Yes, multiple courses"),
                    SelectOption(value: "one_course", label: "Yes, one course"),
                    SelectOption(value: "no", label: "No"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_probiotic_foods",
                text: "How often do you eat fermented foods?",
                subtext: "Yogurt, kimchi, sauerkraut, kombucha, kefir",
                inputType: .singleSelect([
                    SelectOption(value: "daily", label: "Daily"),
                    SelectOption(value: "few_weekly", label: "A few times a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely_never", label: "Rarely or never"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_post_meal_symptoms",
                text: "Which symptoms do you commonly experience after meals?",
                inputType: .multiSelect([
                    SelectOption(value: "gas", label: "Gas"),
                    SelectOption(value: "bloating", label: "Bloating"),
                    SelectOption(value: "heartburn", label: "Heartburn / acid reflux"),
                    SelectOption(value: "nausea", label: "Nausea"),
                    SelectOption(value: "fatigue", label: "Post-meal fatigue"),
                    SelectOption(value: "none", label: "None"),
                ])
            ),
        ]
    )
}
