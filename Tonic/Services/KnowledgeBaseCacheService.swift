import Foundation

struct KnowledgeBaseCacheService {
    private static let directoryName = "knowledge_base"
    private static let snapshotFileName = "snapshot.json"
    private static let metadataFileName = "metadata.json"
    private static let schemaVersion = 1
    private static let stalenessThreshold: TimeInterval = 24 * 60 * 60 // 24 hours

    struct CacheMetadata: Codable {
        let lastFetchedAt: Date
        let schemaVersion: Int
    }

    // MARK: - Directory

    private static var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(directoryName)
    }

    private static var snapshotURL: URL {
        cacheDirectory.appendingPathComponent(snapshotFileName)
    }

    private static var metadataURL: URL {
        cacheDirectory.appendingPathComponent(metadataFileName)
    }

    // MARK: - Write

    func save(_ snapshot: KnowledgeBaseSnapshot) throws {
        let dir = Self.cacheDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let snapshotData = try encoder.encode(snapshot)
        try snapshotData.write(to: Self.snapshotURL)

        let metadata = CacheMetadata(lastFetchedAt: Date(), schemaVersion: Self.schemaVersion)
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: Self.metadataURL)
    }

    // MARK: - Read

    func load() -> KnowledgeBaseSnapshot? {
        guard FileManager.default.fileExists(atPath: Self.snapshotURL.path) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let metadataData = try? Data(contentsOf: Self.metadataURL),
              let metadata = try? decoder.decode(CacheMetadata.self, from: metadataData),
              metadata.schemaVersion == Self.schemaVersion else {
            return nil
        }

        guard let snapshotData = try? Data(contentsOf: Self.snapshotURL),
              let snapshot = try? decoder.decode(KnowledgeBaseSnapshot.self, from: snapshotData) else {
            return nil
        }

        return snapshot
    }

    // MARK: - Staleness

    func isFresh() -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = try? Data(contentsOf: Self.metadataURL),
              let metadata = try? decoder.decode(CacheMetadata.self, from: data),
              metadata.schemaVersion == Self.schemaVersion else {
            return false
        }

        return Date().timeIntervalSince(metadata.lastFetchedAt) < Self.stalenessThreshold
    }

    // MARK: - Load (any age, ignoring staleness)

    func loadIgnoringStaleness() -> KnowledgeBaseSnapshot? {
        guard FileManager.default.fileExists(atPath: Self.snapshotURL.path) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let data = try? Data(contentsOf: Self.snapshotURL),
              let snapshot = try? decoder.decode(KnowledgeBaseSnapshot.self, from: data) else {
            return nil
        }

        return snapshot
    }
}
