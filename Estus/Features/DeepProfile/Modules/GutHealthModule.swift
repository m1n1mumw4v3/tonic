import Foundation

enum GutHealthModule {
    static let config = DeepProfileModuleConfig(
        type: .gutHealth,
        introDescription: "Your gut health influences nutrient absorption, immune function, and even mood. These questions help us tailor probiotic strains and digestive support.",
        disclaimer: "Not a diagnostic tool. See a gastroenterologist for persistent digestive issues.",
        questions: [
            DeepProfileQuestion(
                id: "gut_bowel_regularity",
                text: "What's your typical stool pattern?",
                inputType: .singleSelect([
                    SelectOption(value: "normal_regular", label: "Normal and regular"),
                    SelectOption(value: "constipation", label: "Tends toward constipation"),
                    SelectOption(value: "loose", label: "Tends toward loose/diarrhea"),
                    SelectOption(value: "alternates", label: "Alternates between both"),
                    SelectOption(value: "varies", label: "Varies a lot"),
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
                id: "gut_post_meal_symptoms",
                text: "Which symptoms do you commonly experience after meals?",
                inputType: .multiSelect([
                    SelectOption(value: "gas", label: "Gas"),
                    SelectOption(value: "bloating", label: "Bloating"),
                    SelectOption(value: "nausea", label: "Nausea"),
                    SelectOption(value: "fatigue", label: "Post-meal fatigue"),
                    SelectOption(value: "none", label: "None"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_diagnosed_conditions",
                text: "Have you been diagnosed with any of these conditions?",
                inputType: .multiSelect([
                    SelectOption(value: "ibs", label: "IBS"),
                    SelectOption(value: "ibd", label: "IBD"),
                    SelectOption(value: "gerd", label: "GERD / Acid Reflux"),
                    SelectOption(value: "celiac", label: "Celiac"),
                    SelectOption(value: "sibo", label: "SIBO"),
                    SelectOption(value: "none", label: "None"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_acid_reflux",
                text: "How often do you experience acid reflux or heartburn?",
                inputType: .singleSelect([
                    SelectOption(value: "daily", label: "Daily"),
                    SelectOption(value: "several_weekly", label: "Several times a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely", label: "Rarely or never"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_ppi_usage",
                text: "Do you use proton pump inhibitors (PPIs) like omeprazole?",
                inputType: .singleSelect([
                    SelectOption(value: "yes_currently", label: "Yes, currently"),
                    SelectOption(value: "yes_past", label: "Yes, in the past"),
                    SelectOption(value: "no", label: "No"),
                    SelectOption(value: "not_sure", label: "Not sure"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_fiber_intake",
                text: "How would you describe your fiber intake?",
                inputType: .singleSelect([
                    SelectOption(value: "high", label: "High"),
                    SelectOption(value: "moderate", label: "Moderate"),
                    SelectOption(value: "low", label: "Low"),
                    SelectOption(value: "not_sure", label: "Not sure"),
                ])
            ),
            DeepProfileQuestion(
                id: "gut_nausea_appetite",
                text: "Do you experience nausea or loss of appetite outside of meals?",
                inputType: .singleSelect([
                    SelectOption(value: "frequently", label: "Frequently"),
                    SelectOption(value: "sometimes", label: "Sometimes"),
                    SelectOption(value: "rarely", label: "Rarely"),
                    SelectOption(value: "never", label: "Never"),
                ])
            ),
        ]
    )
}
