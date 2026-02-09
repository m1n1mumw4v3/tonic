import Foundation

// MARK: - Medication Definition

struct Medication {
    let name: String
    let category: String
    let genericName: String?
}

// MARK: - Knowledge Base

enum MedicationKnowledgeBase {

    // MARK: - All Medications

    static let allMedications: [Medication] = [
        // Cardiovascular
        Medication(name: "Lisinopril", category: "Cardiovascular", genericName: nil),
        Medication(name: "Amlodipine", category: "Cardiovascular", genericName: nil),
        Medication(name: "Losartan", category: "Cardiovascular", genericName: nil),
        Medication(name: "Metoprolol", category: "Cardiovascular", genericName: nil),
        Medication(name: "Atenolol", category: "Cardiovascular", genericName: nil),
        Medication(name: "Hydrochlorothiazide", category: "Cardiovascular", genericName: nil),
        Medication(name: "Furosemide", category: "Cardiovascular", genericName: nil),
        Medication(name: "Valsartan", category: "Cardiovascular", genericName: nil),
        Medication(name: "Diltiazem", category: "Cardiovascular", genericName: nil),
        Medication(name: "Carvedilol", category: "Cardiovascular", genericName: nil),
        Medication(name: "Warfarin", category: "Cardiovascular", genericName: "Coumadin"),
        Medication(name: "Eliquis", category: "Cardiovascular", genericName: "Apixaban"),
        Medication(name: "Xarelto", category: "Cardiovascular", genericName: "Rivaroxaban"),
        Medication(name: "Clopidogrel", category: "Cardiovascular", genericName: "Plavix"),
        Medication(name: "Atorvastatin", category: "Cardiovascular", genericName: "Lipitor"),
        Medication(name: "Rosuvastatin", category: "Cardiovascular", genericName: "Crestor"),
        Medication(name: "Simvastatin", category: "Cardiovascular", genericName: "Zocor"),
        Medication(name: "Pravastatin", category: "Cardiovascular", genericName: nil),

        // Diabetes
        Medication(name: "Metformin", category: "Diabetes", genericName: nil),
        Medication(name: "Glipizide", category: "Diabetes", genericName: nil),
        Medication(name: "Glyburide", category: "Diabetes", genericName: nil),
        Medication(name: "Jardiance", category: "Diabetes", genericName: "Empagliflozin"),
        Medication(name: "Farxiga", category: "Diabetes", genericName: "Dapagliflozin"),
        Medication(name: "Ozempic", category: "Diabetes", genericName: "Semaglutide"),
        Medication(name: "Trulicity", category: "Diabetes", genericName: "Dulaglutide"),
        Medication(name: "Mounjaro", category: "Diabetes", genericName: "Tirzepatide"),
        Medication(name: "Januvia", category: "Diabetes", genericName: "Sitagliptin"),
        Medication(name: "Insulin", category: "Diabetes", genericName: nil),
        Medication(name: "Pioglitazone", category: "Diabetes", genericName: nil),

        // Mental Health
        Medication(name: "Sertraline", category: "Mental Health", genericName: "Zoloft"),
        Medication(name: "Escitalopram", category: "Mental Health", genericName: "Lexapro"),
        Medication(name: "Fluoxetine", category: "Mental Health", genericName: "Prozac"),
        Medication(name: "Citalopram", category: "Mental Health", genericName: "Celexa"),
        Medication(name: "Paroxetine", category: "Mental Health", genericName: "Paxil"),
        Medication(name: "Venlafaxine", category: "Mental Health", genericName: "Effexor"),
        Medication(name: "Duloxetine", category: "Mental Health", genericName: "Cymbalta"),
        Medication(name: "Bupropion", category: "Mental Health", genericName: "Wellbutrin"),
        Medication(name: "Trazodone", category: "Mental Health", genericName: nil),
        Medication(name: "Buspirone", category: "Mental Health", genericName: nil),
        Medication(name: "Alprazolam", category: "Mental Health", genericName: "Xanax"),
        Medication(name: "Lorazepam", category: "Mental Health", genericName: "Ativan"),
        Medication(name: "Clonazepam", category: "Mental Health", genericName: "Klonopin"),
        Medication(name: "Aripiprazole", category: "Mental Health", genericName: "Abilify"),
        Medication(name: "Quetiapine", category: "Mental Health", genericName: "Seroquel"),
        Medication(name: "Lamotrigine", category: "Mental Health", genericName: "Lamictal"),
        Medication(name: "Lithium", category: "Mental Health", genericName: nil),

        // Pain & Inflammation
        Medication(name: "Ibuprofen", category: "Pain & Inflammation", genericName: "Advil"),
        Medication(name: "Naproxen", category: "Pain & Inflammation", genericName: "Aleve"),
        Medication(name: "Acetaminophen", category: "Pain & Inflammation", genericName: "Tylenol"),
        Medication(name: "Aspirin", category: "Pain & Inflammation", genericName: nil),
        Medication(name: "Meloxicam", category: "Pain & Inflammation", genericName: "Mobic"),
        Medication(name: "Celecoxib", category: "Pain & Inflammation", genericName: "Celebrex"),
        Medication(name: "Gabapentin", category: "Pain & Inflammation", genericName: "Neurontin"),
        Medication(name: "Pregabalin", category: "Pain & Inflammation", genericName: "Lyrica"),
        Medication(name: "Tramadol", category: "Pain & Inflammation", genericName: nil),
        Medication(name: "Cyclobenzaprine", category: "Pain & Inflammation", genericName: "Flexeril"),
        Medication(name: "Prednisone", category: "Pain & Inflammation", genericName: nil),
        Medication(name: "Methylprednisolone", category: "Pain & Inflammation", genericName: nil),

        // Thyroid
        Medication(name: "Levothyroxine", category: "Thyroid", genericName: "Synthroid"),
        Medication(name: "Liothyronine", category: "Thyroid", genericName: "Cytomel"),
        Medication(name: "Armour Thyroid", category: "Thyroid", genericName: nil),
        Medication(name: "Methimazole", category: "Thyroid", genericName: "Tapazole"),

        // Respiratory
        Medication(name: "Albuterol", category: "Respiratory", genericName: "ProAir"),
        Medication(name: "Fluticasone", category: "Respiratory", genericName: "Flonase"),
        Medication(name: "Montelukast", category: "Respiratory", genericName: "Singulair"),
        Medication(name: "Cetirizine", category: "Respiratory", genericName: "Zyrtec"),
        Medication(name: "Loratadine", category: "Respiratory", genericName: "Claritin"),
        Medication(name: "Fexofenadine", category: "Respiratory", genericName: "Allegra"),
        Medication(name: "Tiotropium", category: "Respiratory", genericName: "Spiriva"),
        Medication(name: "Budesonide", category: "Respiratory", genericName: "Pulmicort"),

        // GI (Gastrointestinal)
        Medication(name: "Omeprazole", category: "GI", genericName: "Prilosec"),
        Medication(name: "Pantoprazole", category: "GI", genericName: "Protonix"),
        Medication(name: "Esomeprazole", category: "GI", genericName: "Nexium"),
        Medication(name: "Famotidine", category: "GI", genericName: "Pepcid"),
        Medication(name: "Ranitidine", category: "GI", genericName: "Zantac"),
        Medication(name: "Ondansetron", category: "GI", genericName: "Zofran"),
        Medication(name: "Dicyclomine", category: "GI", genericName: "Bentyl"),
        Medication(name: "Sucralfate", category: "GI", genericName: "Carafate"),
        Medication(name: "Mesalamine", category: "GI", genericName: "Lialda"),

        // Hormones
        Medication(name: "Estradiol", category: "Hormones", genericName: nil),
        Medication(name: "Progesterone", category: "Hormones", genericName: "Prometrium"),
        Medication(name: "Testosterone", category: "Hormones", genericName: nil),
        Medication(name: "Medroxyprogesterone", category: "Hormones", genericName: "Provera"),
        Medication(name: "Oral Contraceptive", category: "Hormones", genericName: nil),
        Medication(name: "Finasteride", category: "Hormones", genericName: "Propecia"),
        Medication(name: "Tamoxifen", category: "Hormones", genericName: nil),
        Medication(name: "Spironolactone", category: "Hormones", genericName: nil),

        // Neurological & Sleep
        Medication(name: "Sumatriptan", category: "Neurological & Sleep", genericName: "Imitrex"),
        Medication(name: "Topiramate", category: "Neurological & Sleep", genericName: "Topamax"),
        Medication(name: "Amitriptyline", category: "Neurological & Sleep", genericName: nil),
        Medication(name: "Zolpidem", category: "Neurological & Sleep", genericName: "Ambien"),
        Medication(name: "Eszopiclone", category: "Neurological & Sleep", genericName: "Lunesta"),
        Medication(name: "Hydroxyzine", category: "Neurological & Sleep", genericName: nil),
        Medication(name: "Modafinil", category: "Neurological & Sleep", genericName: "Provigil"),
        Medication(name: "Adderall", category: "Neurological & Sleep", genericName: "Amphetamine"),
        Medication(name: "Methylphenidate", category: "Neurological & Sleep", genericName: "Ritalin"),
        Medication(name: "Levetiracetam", category: "Neurological & Sleep", genericName: "Keppra"),
        Medication(name: "Donepezil", category: "Neurological & Sleep", genericName: "Aricept"),
    ]

    // MARK: - Category Helpers

    static let allCategories: [String] = {
        var seen = Set<String>()
        var ordered: [String] = []
        for medication in allMedications {
            if seen.insert(medication.category).inserted {
                ordered.append(medication.category)
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

    static func search(query: String) -> [(category: String, medications: [Medication])] {
        guard !query.isEmpty else { return [] }
        let lowered = query.lowercased()
        return medicationsByCategory.compactMap { group in
            let filtered = group.medications.filter { med in
                med.name.lowercased().contains(lowered)
                    || (med.genericName?.lowercased().contains(lowered) ?? false)
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
