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
                id: "env_water_source",
                text: "What is your primary drinking water source?",
                inputType: .singleSelect([
                    SelectOption(value: "filtered", label: "Filtered (reverse osmosis, carbon, etc.)"),
                    SelectOption(value: "bottled", label: "Bottled water"),
                    SelectOption(value: "tap", label: "Unfiltered tap water"),
                    SelectOption(value: "well", label: "Well water"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_screen_time",
                text: "Roughly how many hours a day do you spend in front of screens?",
                inputType: .singleSelect([
                    SelectOption(value: "under_4", label: "Under 4 hours"),
                    SelectOption(value: "4_8", label: "4-8 hours"),
                    SelectOption(value: "8_12", label: "8-12 hours"),
                    SelectOption(value: "over_12", label: "12+ hours"),
                ])
            ),
            DeepProfileQuestion(
                id: "env_toxin_exposure",
                text: "Are you regularly exposed to any of these?",
                subtext: "Affects detox and antioxidant priorities",
                inputType: .singleSelect([
                    SelectOption(value: "chemicals", label: "Chemicals / cleaning agents at work"),
                    SelectOption(value: "mold", label: "Mold or damp environments"),
                    SelectOption(value: "smoke", label: "Smoke (tobacco, wildfire, etc.)"),
                    SelectOption(value: "none", label: "None of the above"),
                ])
            ),
        ]
    )
}
