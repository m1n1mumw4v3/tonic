import Foundation
import HealthKit

enum HealthKitAuthStatus {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

@Observable
class HealthKitService {
    private(set) var authorizationStatus: HealthKitAuthStatus = .notDetermined
    var isLoading: Bool = false
    var latestMetrics: HealthMetrics?

    private let healthStore: HKHealthStore?

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            healthStore = nil
            authorizationStatus = .unavailable
        }
    }

    // MARK: - Authorization

    @MainActor
    func requestAuthorization() async -> Bool {
        guard let healthStore else {
            authorizationStatus = .unavailable
            return false
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType(),
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            authorizationStatus = .authorized
            return true
        } catch {
            print("⚠️ [HealthKit] Authorization failed: \(error)")
            authorizationStatus = .denied
            return false
        }
    }

    // MARK: - Fetch All

    @MainActor
    func fetchAllMetrics() async -> HealthMetrics {
        guard let healthStore else { return HealthMetrics() }

        isLoading = true
        defer { isLoading = false }

        async let sleep = fetchSleepData(store: healthStore)
        async let rhr = fetchRestingHeartRate(store: healthStore)
        async let hrv = fetchHRV(store: healthStore)
        async let steps = fetchAverageDailySteps(store: healthStore)
        async let workouts = fetchWorkoutData(store: healthStore)
        async let sex = fetchBiologicalSex(store: healthStore)

        let (sleepData, rhrValue, hrvValue, stepsValue, workoutData, sexValue) =
            await (sleep, rhr, hrv, steps, workouts, sex)

        var metrics = HealthMetrics()
        metrics.lastSyncDate = Date()
        metrics.averageSleepDurationHours = sleepData.average
        metrics.lastNightSleepDurationHours = sleepData.lastNight
        metrics.restingHeartRate = rhrValue
        metrics.heartRateVariability = hrvValue
        metrics.averageDailySteps = stepsValue
        metrics.weeklyWorkoutCount = workoutData.count
        metrics.weeklyWorkoutMinutes = workoutData.minutes
        metrics.biologicalSex = sexValue

        latestMetrics = metrics
        return metrics
    }

    // MARK: - Individual Fetchers

    private func fetchSleepData(store: HKHealthStore) async -> (average: Double?, lastNight: Double?) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (nil, nil)
        }

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
                    }
                }
                store.execute(query)
            }

            // Filter to asleep categories (inBed includes time awake in bed)
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue
            ]
            let asleepSamples = samples.filter { asleepValues.contains($0.value) }

            // Group by night (use end date's calendar day)
            var nightlyDurations: [DateComponents: TimeInterval] = [:]
            for sample in asleepSamples {
                let dayKey = calendar.dateComponents([.year, .month, .day], from: sample.endDate)
                nightlyDurations[dayKey, default: 0] += sample.endDate.timeIntervalSince(sample.startDate)
            }

            let totalHours = nightlyDurations.values.map { $0 / 3600.0 }
            let average = totalHours.isEmpty ? nil : totalHours.reduce(0, +) / Double(totalHours.count)

            // Last night = most recent day's total
            let lastNight: Double? = nightlyDurations
                .max(by: { a, b in
                    calendar.date(from: a.key)! < calendar.date(from: b.key)!
                })
                .map { $0.value / 3600.0 }

            return (average, lastNight)
        } catch {
            print("⚠️ [HealthKit] Sleep fetch failed: \(error)")
            return (nil, nil)
        }
    }

    private func fetchRestingHeartRate(store: HKHealthStore) async -> Double? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: hrType,
                    quantitySamplePredicate: predicate,
                    options: .discreteMin
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: result)
                    }
                }
                store.execute(query)
            }

            return result?.minimumQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        } catch {
            print("⚠️ [HealthKit] Resting heart rate fetch failed: \(error)")
            return nil
        }
    }

    private func fetchHRV(store: HKHealthStore) async -> Double? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: hrvType,
                    quantitySamplePredicate: predicate,
                    options: .discreteAverage
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: result)
                    }
                }
                store.execute(query)
            }

            return result?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli))
        } catch {
            print("⚠️ [HealthKit] HRV fetch failed: \(error)")
            return nil
        }
    }

    private func fetchAverageDailySteps(store: HKHealthStore) async -> Int? {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: result)
                    }
                }
                store.execute(query)
            }

            guard let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) else { return nil }
            return Int(sum / 7.0)
        } catch {
            print("⚠️ [HealthKit] Steps fetch failed: \(error)")
            return nil
        }
    }

    private func fetchWorkoutData(store: HKHealthStore) async -> (count: Int?, minutes: Double?) {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
                let query = HKSampleQuery(
                    sampleType: HKObjectType.workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: (results as? [HKWorkout]) ?? [])
                    }
                }
                store.execute(query)
            }

            let totalMinutes = samples.reduce(0.0) { $0 + $1.duration / 60.0 }
            return (samples.count, totalMinutes)
        } catch {
            print("⚠️ [HealthKit] Workout fetch failed: \(error)")
            return (nil, nil)
        }
    }

    private func fetchBiologicalSex(store: HKHealthStore) async -> BiologicalSex? {
        do {
            let sex = try store.biologicalSex().biologicalSex
            switch sex {
            case .male: return .male
            case .female: return .female
            case .other: return .other
            default: return nil
            }
        } catch {
            print("⚠️ [HealthKit] Biological sex fetch failed: \(error)")
            return nil
        }
    }
}
