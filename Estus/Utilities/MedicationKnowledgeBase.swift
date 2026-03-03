import Foundation

// MARK: - Medication Definition

struct Medication {
    let name: String
    let category: String
    let genericName: String?
    let drugClass: String?
    let isCommon: Bool

    init(name: String, category: String, genericName: String? = nil, drugClass: String? = nil, isCommon: Bool = false) {
        self.name = name
        self.category = category
        self.genericName = genericName
        self.drugClass = drugClass
        self.isCommon = isCommon
    }
}

// MARK: - Category Info

struct MedicationCategoryInfo: Identifiable {
    let id: String
    let label: String
    let emoji: String

    init(_ label: String, emoji: String) {
        self.id = label
        self.label = label
        self.emoji = emoji
    }
}

// MARK: - Knowledge Base

enum MedicationKnowledgeBase {

    // MARK: - Category Pills

    static let categoryPills: [MedicationCategoryInfo] = [
        MedicationCategoryInfo("Blood Pressure", emoji: "\u{1F48A}"),
        MedicationCategoryInfo("Antidepressants", emoji: "\u{1F9E0}"),
        MedicationCategoryInfo("Cholesterol", emoji: "\u{1F4CA}"),
        MedicationCategoryInfo("Thyroid", emoji: "\u{1F98B}"),
        MedicationCategoryInfo("Blood Thinners", emoji: "\u{1FA78}"),
        MedicationCategoryInfo("Sleep", emoji: "\u{1F4A4}"),
        MedicationCategoryInfo("Diabetes", emoji: "\u{1F36C}"),
        MedicationCategoryInfo("ADHD", emoji: "\u{26A1}"),
        MedicationCategoryInfo("Stomach & Acid", emoji: "\u{1F344}"),
        MedicationCategoryInfo("Pain", emoji: "\u{1F4AA}"),
        MedicationCategoryInfo("Hormonal", emoji: "\u{1F338}"),
        MedicationCategoryInfo("Immune", emoji: "\u{1FAC1}"),
    ]

    static let categoryEmojiMap: [String: String] = {
        var map: [String: String] = [:]
        for pill in categoryPills {
            map[pill.label] = pill.emoji
        }
        return map
    }()

    // MARK: - All Medications

    static let allMedications: [Medication] = [
        // Blood Pressure
        Medication(name: "Lisinopril", category: "Blood Pressure", drugClass: "ACE inhibitor", isCommon: true),
        Medication(name: "Amlodipine", category: "Blood Pressure", drugClass: "Calcium channel blocker", isCommon: true),
        Medication(name: "Losartan", category: "Blood Pressure", drugClass: "ARB"),
        Medication(name: "Metoprolol", category: "Blood Pressure", drugClass: "Beta blocker"),
        Medication(name: "Atenolol", category: "Blood Pressure", drugClass: "Beta blocker"),
        Medication(name: "Hydrochlorothiazide", category: "Blood Pressure", drugClass: "Thiazide diuretic"),
        Medication(name: "Furosemide", category: "Blood Pressure", drugClass: "Loop diuretic"),
        Medication(name: "Valsartan", category: "Blood Pressure", drugClass: "ARB"),
        Medication(name: "Diltiazem", category: "Blood Pressure", drugClass: "Calcium channel blocker"),
        Medication(name: "Carvedilol", category: "Blood Pressure", drugClass: "Beta blocker"),

        // Cholesterol
        Medication(name: "Atorvastatin", category: "Cholesterol", genericName: "Lipitor", drugClass: "Statin", isCommon: true),
        Medication(name: "Rosuvastatin", category: "Cholesterol", genericName: "Crestor", drugClass: "Statin"),
        Medication(name: "Simvastatin", category: "Cholesterol", genericName: "Zocor", drugClass: "Statin"),
        Medication(name: "Pravastatin", category: "Cholesterol", drugClass: "Statin"),

        // Blood Thinners
        Medication(name: "Warfarin", category: "Blood Thinners", genericName: "Coumadin", drugClass: "Anticoagulant"),
        Medication(name: "Eliquis", category: "Blood Thinners", genericName: "Apixaban", drugClass: "DOAC anticoagulant"),
        Medication(name: "Xarelto", category: "Blood Thinners", genericName: "Rivaroxaban", drugClass: "DOAC anticoagulant"),
        Medication(name: "Clopidogrel", category: "Blood Thinners", genericName: "Plavix", drugClass: "Antiplatelet"),

        // Antidepressants
        Medication(name: "Sertraline", category: "Antidepressants", genericName: "Zoloft", drugClass: "SSRI", isCommon: true),
        Medication(name: "Escitalopram", category: "Antidepressants", genericName: "Lexapro", drugClass: "SSRI"),
        Medication(name: "Fluoxetine", category: "Antidepressants", genericName: "Prozac", drugClass: "SSRI"),
        Medication(name: "Citalopram", category: "Antidepressants", genericName: "Celexa", drugClass: "SSRI"),
        Medication(name: "Paroxetine", category: "Antidepressants", genericName: "Paxil", drugClass: "SSRI"),
        Medication(name: "Venlafaxine", category: "Antidepressants", genericName: "Effexor", drugClass: "SNRI"),
        Medication(name: "Duloxetine", category: "Antidepressants", genericName: "Cymbalta", drugClass: "SNRI"),
        Medication(name: "Bupropion", category: "Antidepressants", genericName: "Wellbutrin", drugClass: "NDRI"),
        Medication(name: "Trazodone", category: "Antidepressants", drugClass: "Serotonin modulator"),
        Medication(name: "Buspirone", category: "Antidepressants", drugClass: "Anxiolytic"),
        Medication(name: "Alprazolam", category: "Antidepressants", genericName: "Xanax", drugClass: "Benzodiazepine"),
        Medication(name: "Lorazepam", category: "Antidepressants", genericName: "Ativan", drugClass: "Benzodiazepine"),
        Medication(name: "Clonazepam", category: "Antidepressants", genericName: "Klonopin", drugClass: "Benzodiazepine"),
        Medication(name: "Aripiprazole", category: "Antidepressants", genericName: "Abilify", drugClass: "Atypical antipsychotic"),
        Medication(name: "Quetiapine", category: "Antidepressants", genericName: "Seroquel", drugClass: "Atypical antipsychotic"),
        Medication(name: "Lamotrigine", category: "Antidepressants", genericName: "Lamictal", drugClass: "Mood stabilizer"),
        Medication(name: "Lithium", category: "Antidepressants", drugClass: "Mood stabilizer"),

        // Diabetes
        Medication(name: "Metformin", category: "Diabetes", drugClass: "Biguanide", isCommon: true),
        Medication(name: "Glipizide", category: "Diabetes", drugClass: "Sulfonylurea"),
        Medication(name: "Glyburide", category: "Diabetes", drugClass: "Sulfonylurea"),
        Medication(name: "Jardiance", category: "Diabetes", genericName: "Empagliflozin", drugClass: "SGLT2 inhibitor"),
        Medication(name: "Farxiga", category: "Diabetes", genericName: "Dapagliflozin", drugClass: "SGLT2 inhibitor"),
        Medication(name: "Ozempic", category: "Diabetes", genericName: "Semaglutide", drugClass: "GLP-1 agonist"),
        Medication(name: "Trulicity", category: "Diabetes", genericName: "Dulaglutide", drugClass: "GLP-1 agonist"),
        Medication(name: "Mounjaro", category: "Diabetes", genericName: "Tirzepatide", drugClass: "GIP/GLP-1 agonist"),
        Medication(name: "Januvia", category: "Diabetes", genericName: "Sitagliptin", drugClass: "DPP-4 inhibitor"),
        Medication(name: "Insulin", category: "Diabetes", drugClass: "Hormone replacement"),
        Medication(name: "Pioglitazone", category: "Diabetes", drugClass: "Thiazolidinedione"),

        // Thyroid
        Medication(name: "Levothyroxine", category: "Thyroid", genericName: "Synthroid", drugClass: "Thyroid hormone replacement", isCommon: true),
        Medication(name: "Liothyronine", category: "Thyroid", genericName: "Cytomel", drugClass: "Thyroid hormone (T3)"),
        Medication(name: "Armour Thyroid", category: "Thyroid", drugClass: "Natural thyroid extract"),
        Medication(name: "Methimazole", category: "Thyroid", genericName: "Tapazole", drugClass: "Antithyroid agent"),

        // Sleep
        Medication(name: "Zolpidem", category: "Sleep", genericName: "Ambien", drugClass: "Sedative-hypnotic"),
        Medication(name: "Eszopiclone", category: "Sleep", genericName: "Lunesta", drugClass: "Sedative-hypnotic"),
        Medication(name: "Hydroxyzine", category: "Sleep", drugClass: "Antihistamine"),
        Medication(name: "Sumatriptan", category: "Sleep", genericName: "Imitrex", drugClass: "Triptan (migraine)"),
        Medication(name: "Topiramate", category: "Sleep", genericName: "Topamax", drugClass: "Anticonvulsant"),
        Medication(name: "Amitriptyline", category: "Sleep", drugClass: "Tricyclic antidepressant"),

        // ADHD
        Medication(name: "Adderall", category: "ADHD", genericName: "Amphetamine", drugClass: "Stimulant"),
        Medication(name: "Methylphenidate", category: "ADHD", genericName: "Ritalin", drugClass: "Stimulant"),
        Medication(name: "Modafinil", category: "ADHD", genericName: "Provigil", drugClass: "Wakefulness promoter"),
        Medication(name: "Levetiracetam", category: "ADHD", genericName: "Keppra", drugClass: "Anticonvulsant"),
        Medication(name: "Donepezil", category: "ADHD", genericName: "Aricept", drugClass: "Cholinesterase inhibitor"),

        // Stomach & Acid
        Medication(name: "Omeprazole", category: "Stomach & Acid", genericName: "Prilosec", drugClass: "Proton pump inhibitor", isCommon: true),
        Medication(name: "Pantoprazole", category: "Stomach & Acid", genericName: "Protonix", drugClass: "Proton pump inhibitor"),
        Medication(name: "Esomeprazole", category: "Stomach & Acid", genericName: "Nexium", drugClass: "Proton pump inhibitor"),
        Medication(name: "Famotidine", category: "Stomach & Acid", genericName: "Pepcid", drugClass: "H2 blocker"),
        Medication(name: "Ranitidine", category: "Stomach & Acid", genericName: "Zantac", drugClass: "H2 blocker"),
        Medication(name: "Ondansetron", category: "Stomach & Acid", genericName: "Zofran", drugClass: "Antiemetic"),
        Medication(name: "Dicyclomine", category: "Stomach & Acid", genericName: "Bentyl", drugClass: "Antispasmodic"),
        Medication(name: "Sucralfate", category: "Stomach & Acid", genericName: "Carafate", drugClass: "Mucosal protectant"),
        Medication(name: "Mesalamine", category: "Stomach & Acid", genericName: "Lialda", drugClass: "Anti-inflammatory (GI)"),

        // Pain
        Medication(name: "Ibuprofen", category: "Pain", genericName: "Advil", drugClass: "NSAID"),
        Medication(name: "Naproxen", category: "Pain", genericName: "Aleve", drugClass: "NSAID"),
        Medication(name: "Acetaminophen", category: "Pain", genericName: "Tylenol", drugClass: "Analgesic"),
        Medication(name: "Aspirin", category: "Pain", drugClass: "NSAID / Antiplatelet"),
        Medication(name: "Meloxicam", category: "Pain", genericName: "Mobic", drugClass: "NSAID"),
        Medication(name: "Celecoxib", category: "Pain", genericName: "Celebrex", drugClass: "COX-2 inhibitor"),
        Medication(name: "Gabapentin", category: "Pain", genericName: "Neurontin", drugClass: "Anticonvulsant / nerve pain"),
        Medication(name: "Pregabalin", category: "Pain", genericName: "Lyrica", drugClass: "Anticonvulsant / nerve pain"),
        Medication(name: "Tramadol", category: "Pain", drugClass: "Opioid analgesic"),
        Medication(name: "Cyclobenzaprine", category: "Pain", genericName: "Flexeril", drugClass: "Muscle relaxant"),
        Medication(name: "Prednisone", category: "Pain", drugClass: "Corticosteroid"),
        Medication(name: "Methylprednisolone", category: "Pain", drugClass: "Corticosteroid"),

        // Hormonal
        Medication(name: "Estradiol", category: "Hormonal", drugClass: "Estrogen replacement"),
        Medication(name: "Progesterone", category: "Hormonal", genericName: "Prometrium", drugClass: "Progestin"),
        Medication(name: "Testosterone", category: "Hormonal", drugClass: "Androgen replacement"),
        Medication(name: "Medroxyprogesterone", category: "Hormonal", genericName: "Provera", drugClass: "Progestin"),
        Medication(name: "Oral Contraceptive", category: "Hormonal", drugClass: "Combination hormone"),
        Medication(name: "Finasteride", category: "Hormonal", genericName: "Propecia", drugClass: "5-alpha reductase inhibitor"),
        Medication(name: "Tamoxifen", category: "Hormonal", drugClass: "Selective estrogen receptor modulator"),
        Medication(name: "Spironolactone", category: "Hormonal", drugClass: "Aldosterone antagonist"),

        // Immune
        Medication(name: "Albuterol", category: "Immune", genericName: "ProAir", drugClass: "Bronchodilator"),
        Medication(name: "Fluticasone", category: "Immune", genericName: "Flonase", drugClass: "Nasal corticosteroid"),
        Medication(name: "Montelukast", category: "Immune", genericName: "Singulair", drugClass: "Leukotriene inhibitor"),
        Medication(name: "Cetirizine", category: "Immune", genericName: "Zyrtec", drugClass: "Antihistamine"),
        Medication(name: "Loratadine", category: "Immune", genericName: "Claritin", drugClass: "Antihistamine"),
        Medication(name: "Fexofenadine", category: "Immune", genericName: "Allegra", drugClass: "Antihistamine"),
        Medication(name: "Tiotropium", category: "Immune", genericName: "Spiriva", drugClass: "Anticholinergic bronchodilator"),
        Medication(name: "Budesonide", category: "Immune", genericName: "Pulmicort", drugClass: "Inhaled corticosteroid"),
    ]

    // MARK: - Common Medications (top 7)

    static let commonMedications: [Medication] = {
        let commonOrder = ["Levothyroxine", "Lisinopril", "Metformin", "Atorvastatin", "Omeprazole", "Sertraline", "Amlodipine"]
        return commonOrder.compactMap { name in
            allMedications.first { $0.name == name }
        }
    }()

    // MARK: - Category Helpers

    static let allCategories: [String] = {
        var seen = Set<String>()
        var ordered: [String] = []
        for pill in categoryPills {
            if seen.insert(pill.label).inserted {
                ordered.append(pill.label)
            }
        }
        return ordered
    }()

    static let medicationsByCategory: [(category: String, medications: [Medication])] = {
        allCategories.map { cat in
            (category: cat,
             medications: allMedications.filter { $0.category == cat })
        }
    }()

    // MARK: - Search

    static func search(query: String) -> [Medication] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        return allMedications.filter { med in
            med.name.lowercased().contains(lowered)
                || (med.genericName?.lowercased().contains(lowered) ?? false)
                || (med.drugClass?.lowercased().contains(lowered) ?? false)
        }
    }

    static func searchGrouped(query: String) -> [(category: String, medications: [Medication])] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        return medicationsByCategory.compactMap { group in
            let filtered = group.medications.filter { med in
                med.name.lowercased().contains(lowered)
                    || (med.genericName?.lowercased().contains(lowered) ?? false)
                    || (med.drugClass?.lowercased().contains(lowered) ?? false)
            }
            guard !filtered.isEmpty else { return nil }
            return (category: group.category, medications: filtered)
        }
    }

    static func exactMatch(for query: String) -> Bool {
        let lowered = query.lowercased()
        return allMedications.contains { med in
            med.name.lowercased() == lowered
                || med.genericName?.lowercased() == lowered
        }
    }
}
