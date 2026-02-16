import Foundation

enum LabWorkBiomarkersModule {
    static let config = DeepProfileModuleConfig(
        type: .labWorkBiomarkers,
        introDescription: "If you've had recent lab work, sharing key results helps us fine-tune recommendations. All questions are optional — skip anything you don't know.",
        disclaimer: "We don't store lab values as medical records. This information is used only to personalize supplement suggestions.",
        questions: [
            DeepProfileQuestion(
                id: "lab_vitamin_d",
                text: "Do you know your Vitamin D level?",
                inputType: .singleSelect([
                    SelectOption(value: "low", label: "Low (under 30 ng/mL)"),
                    SelectOption(value: "adequate", label: "Adequate (30-50 ng/mL)"),
                    SelectOption(value: "optimal", label: "Optimal (50-80 ng/mL)"),
                    SelectOption(value: "high", label: "High (over 80 ng/mL)"),
                    SelectOption(value: "unknown", label: "I don't know"),
                ]),
                isOptional: true
            ),
            DeepProfileQuestion(
                id: "lab_iron_ferritin",
                text: "Have you ever been told your iron or ferritin is low?",
                inputType: .singleSelect([
                    SelectOption(value: "currently_low", label: "Yes, currently low"),
                    SelectOption(value: "previously_low", label: "Yes, in the past"),
                    SelectOption(value: "normal", label: "No, it's been normal"),
                    SelectOption(value: "unknown", label: "I don't know"),
                ]),
                isOptional: true
            ),
            DeepProfileQuestion(
                id: "lab_thyroid",
                text: "Have you been diagnosed with any thyroid issues?",
                inputType: .singleSelect([
                    SelectOption(value: "hypothyroid", label: "Hypothyroid (underactive)"),
                    SelectOption(value: "hyperthyroid", label: "Hyperthyroid (overactive)"),
                    SelectOption(value: "hashimotos", label: "Hashimoto's"),
                    SelectOption(value: "no", label: "No thyroid issues"),
                    SelectOption(value: "unknown", label: "I don't know"),
                ]),
                isOptional: true
            ),
            DeepProfileQuestion(
                id: "lab_cholesterol",
                text: "How are your cholesterol levels?",
                inputType: .singleSelect([
                    SelectOption(value: "high_total", label: "High total cholesterol"),
                    SelectOption(value: "high_ldl", label: "High LDL specifically"),
                    SelectOption(value: "low_hdl", label: "Low HDL"),
                    SelectOption(value: "normal", label: "All in normal range"),
                    SelectOption(value: "unknown", label: "I don't know"),
                ]),
                isOptional: true
            ),
            DeepProfileQuestion(
                id: "lab_b12",
                text: "Do you know your B12 status?",
                inputType: .singleSelect([
                    SelectOption(value: "deficient", label: "Deficient or borderline"),
                    SelectOption(value: "normal", label: "Normal"),
                    SelectOption(value: "supplementing", label: "I supplement B12 already"),
                    SelectOption(value: "unknown", label: "I don't know"),
                ]),
                isOptional: true
            ),
            DeepProfileQuestion(
                id: "lab_blood_sugar",
                text: "Have you been told your blood sugar is elevated?",
                inputType: .singleSelect([
                    SelectOption(value: "prediabetic", label: "Yes, pre-diabetic range"),
                    SelectOption(value: "diabetic", label: "Yes, diabetic"),
                    SelectOption(value: "normal", label: "No, it's normal"),
                    SelectOption(value: "unknown", label: "I don't know"),
                ]),
                isOptional: true
            ),
        ]
    )
}
