import Combine
import FirebaseCrashlytics
import Foundation
import RealmSwift
import Resolver

protocol HistoryStore {
    func clearHistory() throws
    func recentSongs() -> AnyPublisher<[RecentSong], ErrorType>
    func storeRecentSong(hymnToStore hymnIdentifier: HymnIdentifier, songTitle: String)
}

class HistoryStoreRealmImpl: HistoryStore {

    /**
     * Once the number of entries hits this threshold, start replacing the entries.
     */
    let numberToStore = 50

    private let analytics: AnalyticsLogger
    private let realm: Realm

    init(analytics: AnalyticsLogger = Resolver.resolve(), realm: Realm) {
        self.analytics = analytics
        self.realm = realm
    }

    /**
     * Gets a list of `RecentSong`s. but if the list is greater than `numberToStore`, then it will delete the excess `RecentSong`s from the database.
     */
    func recentSongs() -> AnyPublisher<[RecentSong], ErrorType> {
        realm.objects(RecentSongEntity.self).sorted(byKeyPath: "created", ascending: false).collectionPublisher
            .map({ results -> [RecentSong] in
                results.map { entity -> RecentSong in
                    entity.recentSong
                }
            }).mapError({ error -> ErrorType in
                .data(description: error.localizedDescription)
            }).eraseToAnyPublisher()
    }

    func storeRecentSong(hymnToStore hymnIdentifier: HymnIdentifier, songTitle: String) {
        do {
            try realm.write {
                realm.add(
                    RecentSongEntity(recentSong:
                        RecentSong(hymnIdentifier: hymnIdentifier, songTitle: songTitle),
                                     created: Date()),
                    update: .modified)
            }
            let results: Results<RecentSongEntity> = realm.objects(RecentSongEntity.self).sorted(byKeyPath: "created", ascending: false)
            if results.count > numberToStore {
                let entitiesToDelete = Array(results).suffix(results.count - numberToStore)
                do {
                    try realm.write {
                        realm.delete(entitiesToDelete)
                    }
                } catch {
                    var extraParameters = [String: String]()
                    for (index, entity) in entitiesToDelete.enumerated() {
                        extraParameters["primary_key \(index)"] = entity.primaryKey
                    }
                    analytics.logError(message: "error occurred when deleting recent songs", error: error, extraParameters: extraParameters)
                }
            }
        } catch {
            analytics.logError(message: "error occurred when storing recent song", error: error, extraParameters: ["hymnIdentifier": String(describing: hymnIdentifier), "title": songTitle])
        }
    }

    func clearHistory() throws {
        try realm.write {
            self.realm.deleteAll()
        }
    }
}

extension Resolver {
    public static func registerHistoryStore() {
        register(HistoryStore.self) {
            // https://stackoverflow.com/questions/28465706/how-to-find-my-realm-file
            var url = Realm.Configuration.defaultConfiguration.fileURL
            url?.deleteLastPathComponent()
            url?.appendPathComponent("history.realm")
            let config = Realm.Configuration(
                fileURL: url!,
                // Set the new schema version. This must be greater than the previously used
                // version (if you've never set a schema version before, the version is 0).
                schemaVersion: 0,

                // Set the block which will be called automatically when opening a Realm with
                // a schema version lower than the one set above
                migrationBlock: { _, _ in
                    // We haven???t migrated anything yet, so oldSchemaVersion == 0
            })
            // If the Realm db is unable to be created, that's an unrecoverable error, so crashing the app is appropriate.
            // swiftlint:disable:next force_try
            let realm = try! Realm(configuration: config)
            return HistoryStoreRealmImpl(realm: realm) as HistoryStore
        }.scope(application)
    }
}
