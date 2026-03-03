import Foundation

enum SkinHairNailsModule {
    static let config = DeepProfileModuleConfig(
        type: .skinHairNails,
        introDescription: "Your skin, hair, and nail health are influenced by nutrition, environment, and internal health. These questions help us recommend the right compounds for your specific concerns.",
        disclaimer: "This is not a dermatological assessment. Consult a dermatologist for persistent skin conditions.",
        questions: [
            DeepProfileQuestion(
                id: "shn_primary_concerns",
                text: "What are your primary skin, hair, or nail concerns?",
                inputType: .multiSelect([
                    SelectOption(value: "acne", label: "Acne or breakouts"),
                    SelectOption(value: "dryness", label: "Dry or flaky skin"),
                    SelectOption(value: "aging", label: "Fine lines or wrinkles"),
                    SelectOption(value: "hyperpigmentation", label: "Uneven tone or dark spots"),
                    SelectOption(value: "hair_thinning", label: "Hair thinning or loss"),
                    SelectOption(value: "brittle_nails", label: "Brittle or peeling nails"),
                    SelectOption(value: "dull_hair", label: "Dull or dry hair"),
                    SelectOption(value: "redness", label: "Redness or sensitivity"),
                    SelectOption(value: "slow_growth", label: "Slow hair or nail growth"),
                    SelectOption(value: "none", label: "None"),
                ])
            ),
            DeepProfileQuestion(
                id: "shn_diagnosed_conditions",
                text: "Have you been diagnosed with any skin conditions?",
                inputType: .multiSelect([
                    SelectOption(value: "eczema", label: "Eczema"),
                    SelectOption(value: "psoriasis", label: "Psoriasis"),
                    SelectOption(value: "rosacea", label: "Rosacea"),
                    SelectOption(value: "dermatitis", label: "Dermatitis"),
                    SelectOption(value: "alopecia", label: "Alopecia"),
                    SelectOption(value: "fungal", label: "Fungal infection"),
                    SelectOption(value: "none", label: "None"),
                ])
            ),
            DeepProfileQuestion(
                id: "shn_skin_type",
                text: "How would you describe your skin type?",
                inputType: .singleSelect([
                    SelectOption(value: "oily", label: "Oily"),
                    SelectOption(value: "dry", label: "Dry"),
                    SelectOption(value: "combination", label: "Combination"),
                    SelectOption(value: "sensitive", label: "Sensitive"),
                    SelectOption(value: "normal", label: "Normal"),
                ])
            ),
            DeepProfileQuestion(
                id: "shn_sun_exposure",
                text: "How much cumulative sun exposure has your skin had over your lifetime?",
                inputType: .singleSelect([
                    SelectOption(value: "high", label: "High — outdoor work or frequent tanning"),
                    SelectOption(value: "moderate", label: "Moderate — regular outdoor activity"),
                    SelectOption(value: "low", label: "Low — mostly indoors, consistent SPF use"),
                ])
            ),
            DeepProfileQuestion(
                id: "shn_topical_retinoids",
                text: "Are you currently using any topical retinoids?",
                subtext: "Important for safe vitamin A dosing.",
                inputType: .singleSelect([
                    SelectOption(value: "prescription", label: "Yes, prescription (tretinoin, adapalene)"),
                    SelectOption(value: "otc", label: "Yes, over-the-counter retinol"),
                    SelectOption(value: "no", label: "No"),
                    SelectOption(value: "not_sure", label: "Not sure"),
                ])
            ),
            DeepProfileQuestion(
                id: "shn_hair_loss_pattern",
                text: "If you're experiencing hair thinning or loss, what pattern best describes it?",
                inputType: .singleSelect([
                    SelectOption(value: "diffuse", label: "Diffuse thinning all over"),
                    SelectOption(value: "receding", label: "Receding hairline or temples"),
                    SelectOption(value: "crown", label: "Thinning at the crown"),
                    SelectOption(value: "patchy", label: "Patchy loss"),
                    SelectOption(value: "not_applicable", label: "Not experiencing hair loss"),
                ]),
                isOptional: true
            ),
            DeepProfileQuestion(
                id: "shn_water_intake",
                text: "How would you rate your current water intake?",
                inputType: .singleSelect([
                    SelectOption(value: "high", label: "High — 8+ glasses per day"),
                    SelectOption(value: "moderate", label: "Moderate — 4–7 glasses per day"),
                    SelectOption(value: "low", label: "Low — under 4 glasses per day"),
                ])
            ),
            DeepProfileQuestion(
                id: "shn_existing_supplements",
                text: "Do you currently take collagen or biotin supplements?",
                inputType: .multiSelect([
                    SelectOption(value: "collagen", label: "Collagen"),
                    SelectOption(value: "biotin", label: "Biotin"),
                    SelectOption(value: "neither", label: "Neither"),
                ])
            ),
            DeepProfileQuestion(
                id: "shn_skin_elasticity",
                text: "How would you rate your skin's elasticity and firmness?",
                inputType: .singleSelect([
                    SelectOption(value: "good", label: "Good — skin bounces back quickly"),
                    SelectOption(value: "moderate", label: "Moderate — some loss of firmness"),
                    SelectOption(value: "poor", label: "Poor — noticeable sagging or laxity"),
                ])
            ),
        ]
    )
}
