import SwiftUI

@Observable
class BaselineProfileViewModel {
    // Personal
    var firstName: String
    var age: Int
    var sex: Sex
    var heightFeet: Int
    var heightInches: Int
    var heightCm: Int
    var includeHeight: Bool
    var weightLbs: Int
    var weightKg: Int
    var includeWeight: Bool

    // Goals
    var healthGoals: Set<HealthGoal>

    // Supplements & Medications
    var takingSupplements: Bool
    var currentSupplements: Set<String>
    var customSupplementText: String
    var takingMedications: Bool
    var medications: Set<String>
    var customMedicationText: String
    var allergies: Set<String>
    var customAllergyText: String

    // Lifestyle
    var dietType: DietType
    var exerciseFrequency: ExerciseFrequency
    var coffeeCupsDaily: Int
    var teaCupsDaily: Int
    var energyDrinksDaily: Int
    var alcoholWeekly: AlcoholIntake
    var stressLevel: StressLevel

    // Baseline Wellness
    var baselineSleep: Double
    var baselineEnergy: Double
    var baselineClarity: Double
    var baselineMood: Double
    var baselineGut: Double

    var isAtGoalLimit: Bool {
        healthGoals.count >= HealthGoal.maxSelection
    }

    // Original snapshot for change detection
    private let original: UserProfile

    init(profile: UserProfile) {
        self.original = profile

        firstName = profile.firstName
        age = profile.age
        sex = profile.sex

        if let totalInches = profile.heightInches {
            heightFeet = totalInches / 12
            heightInches = totalInches % 12
            heightCm = Int(round(Double(totalInches) * 2.54))
            includeHeight = true
        } else {
            heightFeet = 5
            heightInches = 8
            heightCm = 173
            includeHeight = false
        }

        if let lbs = profile.weightLbs {
            weightLbs = lbs
            weightKg = Int(round(Double(lbs) * 0.453592))
            includeWeight = true
        } else {
            weightLbs = 160
            weightKg = 73
            includeWeight = false
        }

        healthGoals = Set(profile.healthGoals)

        takingSupplements = profile.takingSupplements
        currentSupplements = Set(profile.currentSupplements)
        customSupplementText = ""

        takingMedications = profile.takingMedications
        medications = Set(profile.medications)
        customMedicationText = ""

        allergies = Set(profile.allergies)
        customAllergyText = ""

        dietType = profile.dietType
        exerciseFrequency = profile.exerciseFrequency
        coffeeCupsDaily = profile.coffeeCupsDaily
        teaCupsDaily = profile.teaCupsDaily
        energyDrinksDaily = profile.energyDrinksDaily
        alcoholWeekly = profile.alcoholWeekly
        stressLevel = profile.stressLevel

        baselineSleep = Double(profile.baselineSleep)
        baselineEnergy = Double(profile.baselineEnergy)
        baselineClarity = Double(profile.baselineClarity)
        baselineMood = Double(profile.baselineMood)
        baselineGut = Double(profile.baselineGut)
    }

    // MARK: - Apply Changes

    func applyChanges() -> UserProfile {
        var profile = original
        profile.updatedAt = Date()

        profile.firstName = firstName.trimmingCharacters(in: .whitespaces)
        profile.age = age
        profile.sex = sex
        profile.heightInches = includeHeight ? (heightFeet * 12 + heightInches) : nil
        profile.weightLbs = includeWeight ? weightLbs : nil

        profile.healthGoals = Array(healthGoals)

        profile.takingSupplements = takingSupplements
        if takingSupplements {
            var supps = Array(currentSupplements)
            if !customSupplementText.isEmpty {
                supps.append(contentsOf: customSupplementText
                    .split(separator: ",")
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty })
            }
            profile.currentSupplements = supps
        } else {
            profile.currentSupplements = []
        }

        profile.takingMedications = takingMedications
        if takingMedications {
            var meds = Array(medications)
            if !customMedicationText.isEmpty {
                meds.append(contentsOf: customMedicationText
                    .split(separator: ",")
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty })
            }
            profile.medications = meds
        } else {
            profile.medications = []
        }

        var allAllergies = Array(allergies)
        if !customAllergyText.isEmpty {
            allAllergies.append(contentsOf: customAllergyText
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty })
        }
        profile.allergies = allAllergies

        profile.dietType = dietType
        profile.exerciseFrequency = exerciseFrequency
        profile.coffeeCupsDaily = coffeeCupsDaily
        profile.teaCupsDaily = teaCupsDaily
        profile.energyDrinksDaily = energyDrinksDaily
        profile.alcoholWeekly = alcoholWeekly
        profile.stressLevel = stressLevel

        profile.baselineSleep = Int(baselineSleep)
        profile.baselineEnergy = Int(baselineEnergy)
        profile.baselineClarity = Int(baselineClarity)
        profile.baselineMood = Int(baselineMood)
        profile.baselineGut = Int(baselineGut)

        return profile
    }

    // MARK: - Change Detection

    var hasChanges: Bool {
        let updated = applyChanges()
        return updated.firstName != original.firstName
            || updated.age != original.age
            || updated.sex != original.sex
            || updated.heightInches != original.heightInches
            || updated.weightLbs != original.weightLbs
            || Set(updated.healthGoals) != Set(original.healthGoals)
            || updated.takingSupplements != original.takingSupplements
            || Set(updated.currentSupplements) != Set(original.currentSupplements)
            || updated.takingMedications != original.takingMedications
            || Set(updated.medications) != Set(original.medications)
            || Set(updated.allergies) != Set(original.allergies)
            || updated.dietType != original.dietType
            || updated.exerciseFrequency != original.exerciseFrequency
            || updated.coffeeCupsDaily != original.coffeeCupsDaily
            || updated.teaCupsDaily != original.teaCupsDaily
            || updated.energyDrinksDaily != original.energyDrinksDaily
            || updated.alcoholWeekly != original.alcoholWeekly
            || updated.stressLevel != original.stressLevel
            || updated.baselineSleep != original.baselineSleep
            || updated.baselineEnergy != original.baselineEnergy
            || updated.baselineClarity != original.baselineClarity
            || updated.baselineMood != original.baselineMood
            || updated.baselineGut != original.baselineGut
    }

    var needsPlanRegeneration: Bool {
        let updated = applyChanges()
        return Set(updated.healthGoals) != Set(original.healthGoals)
            || Set(updated.medications) != Set(original.medications)
            || Set(updated.allergies) != Set(original.allergies)
            || updated.dietType != original.dietType
            || updated.age != original.age
            || updated.sex != original.sex
            || updated.weightLbs != original.weightLbs
    }
}
