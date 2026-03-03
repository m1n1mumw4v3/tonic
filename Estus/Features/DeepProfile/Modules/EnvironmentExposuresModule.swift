import Foundation

enum EnvironmentExposuresModule {
    static let config = DeepProfileModuleConfig(
        type: .environmentExposures,
        introDescription: "Environmental factors affect nutrient needs, detox pathways, and antioxidant requirements. These questions help us account for your daily exposures.",
        questions: [
            DeepProfileQuestion(
                id: "env_sun_exposure",
                text: "How much direct sunlight do you get most days?",
                subtext: "Affects Vitamin D and antioxidant needs",
                inputType: .singleSelect([
                    SelectOption(value: "minimal", label: "Minimal (mostly indoors)"),
                    SelectOption(value: "some", label: "Some (15-30 min)"),
                    SelectOption(value: "moderate", label: "Moderate (30-60 min)"),
                    SelectOption(value: "lots", label: "Lots (60+ min outdoors)"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_air_quality",
                text: "How would you rate your local air quality?",
                inputType: .singleSelect([
                    SelectOption(value: "excellent", label: "Excellent (rural / clean)"),
                    SelectOption(value: "good", label: "Good (suburban)"),
                    SelectOption(value: "moderate", label: "Moderate (urban)"),
                    SelectOption(value: "poor", label: "Poor (high pollution area)"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_toxin_exposure",
                text: "Are you regularly exposed to any of these?",
                subtext: "Select all that apply",
                inputType: .multiSelect([
                    SelectOption(value: "chemicals", label: "Chemicals / cleaning agents at work"),
                    SelectOption(value: "mold", label: "Mold or damp environments"),
                    SelectOption(value: "smoke", label: "Smoke (tobacco, wildfire, etc.)"),
                    SelectOption(value: "none", label: "None of the above"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_smoking_nicotine",
                text: "Do you use tobacco or nicotine products?",
                inputType: .singleSelect([
                    SelectOption(value: "daily_cigarettes", label: "Daily cigarettes"),
                    SelectOption(value: "occasional_cigarettes", label: "Occasional cigarettes"),
                    SelectOption(value: "vape_daily", label: "Vape / e-cigarette daily"),
                    SelectOption(value: "vape_occasional", label: "Vape / e-cigarette occasionally"),
                    SelectOption(value: "nicotine_pouches", label: "Nicotine pouches / gum"),
                    SelectOption(value: "former", label: "Former user"),
                    SelectOption(value: "never", label: "Never"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_alcohol_beyond_onboarding",
                text: "Is your alcohol intake higher than you reported during onboarding?",
                inputType: .singleSelect([
                    SelectOption(value: "no", label: "No"),
                    SelectOption(value: "yes_higher", label: "Yes, probably higher"),
                    SelectOption(value: "varies_seasonally", label: "Varies seasonally"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_high_altitude",
                text: "Do you live or train at high altitude (above 5,000 ft)?",
                inputType: .singleSelect([
                    SelectOption(value: "yes", label: "Yes"),
                    SelectOption(value: "no", label: "No"),
                    SelectOption(value: "not_sure", label: "Not sure"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_organic_produce",
                text: "How often do you eat organic produce?",
                inputType: .singleSelect([
                    SelectOption(value: "mostly_organic", label: "Mostly organic"),
                    SelectOption(value: "mixed", label: "Mixed"),
                    SelectOption(value: "rarely", label: "Rarely"),
                    SelectOption(value: "never", label: "Never"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_heavy_traffic",
                text: "How often are you exposed to heavy traffic or exhaust fumes?",
                inputType: .singleSelect([
                    SelectOption(value: "daily", label: "Daily"),
                    SelectOption(value: "several_weekly", label: "Several times a week"),
                    SelectOption(value: "occasionally", label: "Occasionally"),
                    SelectOption(value: "rarely", label: "Rarely"),
                ])
            ),
        ]
    )
}
