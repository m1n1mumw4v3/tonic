import XCTest
@testable import Estus

final class WellbeingScoreTests: XCTestCase {

    // MARK: - Basic Calculation

    func testCalculateReturnsAverageOfFiveDimensions() {
        let score = WellbeingScore.calculate(sleep: 6, energy: 8, clarity: 4, mood: 10, gut: 2)
        XCTAssertEqual(score, 6.0, accuracy: 0.001)
    }

    func testCalculateAllZeros() {
        let score = WellbeingScore.calculate(sleep: 0, energy: 0, clarity: 0, mood: 0, gut: 0)
        XCTAssertEqual(score, 0.0, accuracy: 0.001)
    }

    func testCalculateAllTens() {
        let score = WellbeingScore.calculate(sleep: 10, energy: 10, clarity: 10, mood: 10, gut: 10)
        XCTAssertEqual(score, 10.0, accuracy: 0.001)
    }

    func testCalculateAllFives() {
        let score = WellbeingScore.calculate(sleep: 5, energy: 5, clarity: 5, mood: 5, gut: 5)
        XCTAssertEqual(score, 5.0, accuracy: 0.001)
    }

    // MARK: - Dictionary-based Calculation

    func testCalculateFromDictionaryWithAllKeys() {
        let scores: [WellnessDimension: Int] = [
            .sleep: 8, .energy: 6, .clarity: 7, .mood: 9, .gut: 5
        ]
        let score = WellbeingScore.calculate(scores: scores)
        XCTAssertEqual(score, 7.0, accuracy: 0.001)
    }

    func testCalculateFromDictionaryMissingKeyDefaultsToFive() {
        // Only provide sleep; the rest should default to 5
        let scores: [WellnessDimension: Int] = [.sleep: 10]
        let score = WellbeingScore.calculate(scores: scores)
        // (10 + 5 + 5 + 5 + 5) / 5 = 6.0
        XCTAssertEqual(score, 6.0, accuracy: 0.001)
    }

    func testCalculateFromEmptyDictionaryReturns5() {
        let scores: [WellnessDimension: Int] = [:]
        let score = WellbeingScore.calculate(scores: scores)
        // All default to 5 → 5.0
        XCTAssertEqual(score, 5.0, accuracy: 0.001)
    }

    // MARK: - DailyCheckIn Integration

    func testDailyCheckInWellbeingScoreMatchesDirectCalculation() {
        var checkIn = DailyCheckIn()
        checkIn.sleepScore = 7
        checkIn.energyScore = 3
        checkIn.clarityScore = 8
        checkIn.moodScore = 6
        checkIn.gutScore = 4

        let expected = WellbeingScore.calculate(sleep: 7, energy: 3, clarity: 8, mood: 6, gut: 4)
        XCTAssertEqual(checkIn.wellbeingScore, expected, accuracy: 0.001)
    }

    // MARK: - WellnessDimension

    func testAllDimensionsCovered() {
        XCTAssertEqual(WellnessDimension.allCases.count, 5)
    }

    func testDimensionLabelsAreNonEmpty() {
        for dimension in WellnessDimension.allCases {
            XCTAssertFalse(dimension.label.isEmpty, "\(dimension) should have a label")
            XCTAssertFalse(dimension.icon.isEmpty, "\(dimension) should have an icon")
            XCTAssertFalse(dimension.shortLabel.isEmpty, "\(dimension) should have a short label")
            XCTAssertFalse(dimension.lowLabel.isEmpty, "\(dimension) should have a low label")
            XCTAssertFalse(dimension.highLabel.isEmpty, "\(dimension) should have a high label")
        }
    }

    func testDimensionCodableRoundTrip() throws {
        let dimension = WellnessDimension.clarity
        let data = try JSONEncoder().encode(dimension)
        let decoded = try JSONDecoder().decode(WellnessDimension.self, from: data)
        XCTAssertEqual(decoded, dimension)
    }
}
