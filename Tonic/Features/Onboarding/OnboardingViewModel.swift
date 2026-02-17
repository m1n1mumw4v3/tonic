import SwiftUI

@Observable
class OnboardingViewModel {
    // Screen data
    var firstName: String = ""
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 30
    }
    var sex: Sex? = nil
    var isPregnant: Bool = false
    var isBreastfeeding: Bool = false
    var heightFeet: Int = 5
    var heightInches: Int = 8
    var heightCm: Int = 173
    var weightLbs: Int = 160
    var weightKg: Int = 73

    var healthGoals: Set<HealthGoal> = []

    var takingSupplements: Bool = false
    var currentSupplements: Set<String> = []
    var customSupplementText: String = ""

    var takingMedications: Bool = false
    var medications: Set<String> = []
    var customMedicationText: String = ""
    var noKnownAllergies: Bool = true
    var allergies: Set<String> = []
    var customAllergyText: String = ""

    var dietType: DietType? = nil
    var customDietText: String = ""
    var exerciseFrequency: ExerciseFrequency? = nil
    var coffeeCupsDaily: Int = 0
    var teaCupsDaily: Int = 0
    var energyDrinksDaily: Int = 0
    var alcoholWeekly: AlcoholIntake? = nil
    var stressLevel: StressLevel? = nil

    var baselineSleep: Double = 5
    var baselineEnergy: Double = 5
    var baselineClarity: Double = 5
    var baselineMood: Double = 5
    var baselineGut: Double = 5

    var healthKitEnabled: Bool = false
    var healthKitProvidedSex: Bool = false

    // Notification reminders
    var morningReminderEnabled: Bool = true
    var eveningReminderEnabled: Bool = true
    var morningReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    var eveningReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0))!

    // Generated plan (held between AI Interstitial and Plan Reveal)
    var generatedPlan: SupplementPlan?

    // Common allergies
    static let commonAllergies = ["Shellfish", "Soy", "Gluten", "Dairy", "Tree Nuts", "Fish"]

    // Validation
    var isNameValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var hasSelectedGoals: Bool {
        !healthGoals.isEmpty
    }

    var isAtGoalLimit: Bool {
        healthGoals.count >= HealthGoal.maxSelection
    }

    // Build profile
    func buildUserProfile() -> UserProfile {
        var profile = UserProfile()
        profile.firstName = firstName.trimmingCharacters(in: .whitespaces)
        profile.age = age
        profile.dateOfBirth = dateOfBirth
        profile.sex = sex ?? .preferNotToSay
        profile.isPregnant = isPregnant
        profile.isBreastfeeding = isBreastfeeding
        profile.heightInches = heightFeet * 12 + heightInches
        profile.weightLbs = weightLbs
        profile.healthGoals = Array(healthGoals)
        profile.takingSupplements = takingSupplements
        if takingSupplements {
            var supps = Array(currentSupplements)
            if !customSupplementText.isEmpty {
                supps.append(contentsOf: customSupplementText.split(separator: ",")
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
            allAllergies.append(contentsOf: customAllergyText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) })
        }
        profile.allergies = allAllergies

        profile.dietType = dietType ?? .omnivore
        profile.customDietText = customDietText.trimmingCharacters(in: .whitespaces)
        profile.exerciseFrequency = exerciseFrequency ?? .none
        profile.coffeeCupsDaily = coffeeCupsDaily
        profile.teaCupsDaily = teaCupsDaily
        profile.energyDrinksDaily = energyDrinksDaily
        profile.alcoholWeekly = alcoholWeekly ?? .none
        profile.stressLevel = stressLevel ?? .moderate
        profile.baselineSleep = Int(baselineSleep)
        profile.baselineEnergy = Int(baselineEnergy)
        profile.baselineClarity = Int(baselineClarity)
        profile.baselineMood = Int(baselineMood)
        profile.baselineGut = Int(baselineGut)
        profile.healthKitEnabled = healthKitEnabled
        profile.morningReminderEnabled = morningReminderEnabled
        profile.eveningReminderEnabled = eveningReminderEnabled
        profile.morningReminderTime = morningReminderTime
        profile.eveningReminderTime = eveningReminderTime
        return profile
    }
}
