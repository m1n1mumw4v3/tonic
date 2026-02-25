import Foundation

enum KnowledgeBaseMapper {

    struct MappedKnowledgeBase {
        let supplements: [Supplement]
        let goalSupplementMap: [String: [GoalSupplementEntry]]
        let knownDrugInteractions: [String: [String]]
        let onsetTimelines: [String: (min: Int, max: Int, description: String)]
        let dailyTips: [String]
    }

    static func map(_ snapshot: KnowledgeBaseSnapshot) -> MappedKnowledgeBase {
        // Build a lookup from supplement ID → name for cross-table joins
        let idToName: [UUID: String] = Dictionary(
            snapshot.supplements.map { ($0.id, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )

        let supplements = mapSupplements(snapshot, idToName: idToName)
        let goalMap = mapGoalSupplementMap(snapshot.goalMaps, idToName: idToName)
        let drugInteractions = mapDrugInteractions(snapshot.drugInteractions, idToName: idToName)
        let timelines = mapOnsetTimelines(snapshot.supplements)
        let tips = mapDailyTips(snapshot.supplements)

        return MappedKnowledgeBase(
            supplements: supplements,
            goalSupplementMap: goalMap,
            knownDrugInteractions: drugInteractions,
            onsetTimelines: timelines,
            dailyTips: tips
        )
    }

    // MARK: - Supplements

    private static func mapSupplements(_ snapshot: KnowledgeBaseSnapshot, idToName: [UUID: String]) -> [Supplement] {
        snapshot.supplements.map { s in
            let timing: SupplementTiming = {
                guard let raw = s.timeOfDay else { return .morning }
                switch raw {
                case "morning": return .morning
                case "afternoon": return .afternoon
                case "evening": return .evening
                case "bedtime": return .bedtime
                case "with_food": return .withFood
                case "empty_stomach": return .emptyStomach
                default: return .morning
                }
            }()

            let evidence: EvidenceLevel = {
                guard let raw = s.synthesisConfidence else { return .moderate }
                switch raw {
                case "high": return .strong
                case "moderate": return .moderate
                case "low": return .emerging
                default: return EvidenceLevel(rawValue: raw) ?? .moderate
                }
            }()

            // Collect drug interaction keywords for this supplement
            let interactionKeywords = snapshot.drugInteractions
                .filter { $0.supplementId == s.id }
                .map(\.drugOrClass)

            // Collect contraindication conditions
            let contraindicationsList = snapshot.contraindications
                .filter { $0.supplementId == s.id }
                .map(\.condition)

            // Build dosage range string from dose fields
            let dosageRange: String = {
                if let low = s.doseRangeLow, let high = s.doseRangeHigh {
                    return "\(low) – \(high)"
                }
                return s.defaultDose ?? ""
            }()

            // Parse recommended dosage number from defaultDose (e.g. "300 mg" → 300)
            let dosageMg: Double = {
                guard let dose = s.defaultDose else { return 0 }
                let digits = dose.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return Double(digits) ?? 0
            }()

            // Build benefits from primary action
            let benefits: [String] = {
                if let action = s.primaryAction {
                    return [action]
                }
                return []
            }()

            // Form and bioavailability from recommended form
            let formInfo: String = s.defaultForm ?? ""

            // Timeline text from onset description
            let timeline: String = s.onsetDescription ?? ""

            // Timing rationale as notes
            let notes: String = s.timingRationale ?? ""

            // What to look for from the default form + notes
            let whatToLookFor: String = s.timingRelativeNotes ?? ""

            return Supplement(
                id: s.id,
                name: s.name,
                category: s.category,
                commonDosageRange: dosageRange,
                recommendedDosageMg: dosageMg,
                recommendedTiming: timing,
                benefits: benefits,
                contraindications: contraindicationsList,
                drugInteractions: interactionKeywords,
                notes: notes,
                dosageRationale: s.primaryAction ?? "",
                expectedTimeline: timeline,
                whatToLookFor: whatToLookFor,
                formAndBioavailability: formInfo,
                evidenceLevel: evidence
            )
        }
    }

    // MARK: - Goal Supplement Map

    private static func mapGoalSupplementMap(_ goalMaps: [SupabaseGoalMap], idToName: [UUID: String]) -> [String: [GoalSupplementEntry]] {
        var result: [String: [GoalSupplementEntry]] = [:]
        for entry in goalMaps {
            guard let name = idToName[entry.supplementId] else { continue }
            let weightInt = Int(entry.weight) ?? 1
            let goalEntry = GoalSupplementEntry(name: name, weight: weightInt)
            result[entry.goal, default: []].append(goalEntry)
        }
        // Sort each goal's entries by weight descending
        for key in result.keys {
            result[key]?.sort { $0.weight > $1.weight }
        }
        return result
    }

    // MARK: - Drug Interactions

    private static func mapDrugInteractions(_ interactions: [SupabaseDrugInteraction], idToName: [UUID: String]) -> [String: [String]] {
        var result: [String: [String]] = [:]
        for interaction in interactions {
            guard let supplementName = idToName[interaction.supplementId] else { continue }
            result[interaction.drugOrClass, default: []].append(supplementName)
        }
        // Deduplicate
        for key in result.keys {
            result[key] = Array(Set(result[key] ?? []))
        }
        return result
    }

    // MARK: - Onset Timelines

    private static func mapOnsetTimelines(_ supplements: [SupabaseSupplement]) -> [String: (min: Int, max: Int, description: String)] {
        // Start with hardcoded timelines as base
        var timelines = SupplementKnowledgeBase.onsetTimelines

        // Overlay with DB data where onset fields are populated
        for s in supplements {
            if let minDays = s.onsetMinDays, let maxDays = s.onsetMaxDays {
                let desc = s.onsetDescription ?? "\(minDays)–\(maxDays) days"
                timelines[s.name] = (min: minDays, max: maxDays, description: desc)
            } else if timelines[s.name] == nil {
                // Default for new supplements with no onset data
                timelines[s.name] = (min: 7, max: 28, description: s.onsetDescription ?? "Results may vary")
            }
        }

        return timelines
    }

    // MARK: - Daily Tips

    private static func mapDailyTips(_ supplements: [SupabaseSupplement]) -> [String] {
        // Keep hardcoded tips as baseline, add timing rationale from new supplements
        var tips = SupplementKnowledgeBase.dailyTips
        let hardcodedNames = Set(SupplementKnowledgeBase.allSupplements.map(\.name))

        for s in supplements where !hardcodedNames.contains(s.name) {
            if let rationale = s.timingRationale, !rationale.isEmpty {
                tips.append("\(s.name): \(rationale)")
            }
        }

        return tips
    }
}
