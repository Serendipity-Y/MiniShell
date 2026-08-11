//
//  DataStore.swift
//  macSCP
//
//  SwiftData ModelContainer setup and management
//

import Foundation
import SwiftData

@MainActor
final class DataStore {
    static let shared = DataStore()

    let modelContainer: ModelContainer

    private static let storeDirectoryName = "MiniShell"
    private static let storeFileName = "connections.store"
    private static let legacyStoreFileName = "default.store"

    private init() {
        do {
            let schema = Schema([
                ConnectionEntity.self,
                FolderEntity.self
            ])

            let storeURL = try Self.persistentStoreURL()
            try Self.migrateLegacyStoreIfNeeded(to: storeURL, schema: schema)

            let modelConfiguration = ModelConfiguration(
                "MiniShell",
                schema: schema,
                url: storeURL,
                allowsSave: true
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            logInfo("DataStore initialized successfully", category: .database)
        } catch {
            logError("Failed to initialize DataStore: \(error)", category: .database)
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    private static func persistentStoreURL() throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let directoryURL = applicationSupportURL.appendingPathComponent(
            storeDirectoryName,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        return directoryURL.appendingPathComponent(storeFileName)
    }

    /// Moves existing MiniShell data away from SwiftData's shared default filename.
    /// The legacy store is left untouched so a failed or interrupted migration is recoverable.
    private static func migrateLegacyStoreIfNeeded(to destinationURL: URL, schema: Schema) throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: destinationURL.path) else { return }

        let legacyURL = destinationURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(legacyStoreFileName)
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }
        guard try legacyStoreContainsMiniShellData(at: legacyURL, schema: schema) else { return }

        try copyPersistentStore(from: legacyURL, to: destinationURL)
        logInfo("Migrated legacy connection store", category: .database)
    }

    private static func legacyStoreContainsMiniShellData(at url: URL, schema: Schema) throws -> Bool {
        let configuration = ModelConfiguration(
            "MiniShellLegacyReadOnly",
            schema: schema,
            url: url,
            allowsSave: false
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        return try !context.fetch(FetchDescriptor<ConnectionEntity>()).isEmpty ||
            !context.fetch(FetchDescriptor<FolderEntity>()).isEmpty
    }

    private static func copyPersistentStore(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: sourceURL.path + suffix)
            let destination = URL(fileURLWithPath: destinationURL.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            try fileManager.copyItem(at: source, to: destination)
        }
    }

    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    /// Creates a new background context for async operations
    func newBackgroundContext() -> ModelContext {
        ModelContext(modelContainer)
    }

    /// Attempts to recover from database corruption by recreating the store
    static func createWithRecovery() -> ModelContainer {
        do {
            return DataStore.shared.modelContainer
        } catch {
            logError("Database recovery failed: \(error)", category: .database)
            fatalError("Cannot recover database: \(error)")
        }
    }
}

// MARK: - Preview Support
extension DataStore {
    @MainActor
    static var preview: DataStore {
        let store = DataStore()
        // Add preview data if needed
        return store
    }
}
