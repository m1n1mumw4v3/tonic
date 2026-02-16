import Foundation

enum DeepProfileModuleRegistry {
    static func config(for type: DeepProfileModuleType) -> DeepProfileModuleConfig {
        switch type {
        case .sleepCircadian:
            return SleepCircadianModule.config
        case .hormonalMetabolic:
            return HormonalMetabolicModule.config
        case .gutHealth:
            return GutHealthModule.config
        case .stressNervousSystem:
            return StressNervousSystemModule.config
        case .cognitiveFunction:
            return CognitiveFunctionModule.config
        case .musculoskeletalRecovery:
            return MusculoskeletalRecoveryModule.config
        case .environmentExposures:
            return EnvironmentExposuresModule.config
        case .labWorkBiomarkers:
            return LabWorkBiomarkersModule.config
        }
    }
}
