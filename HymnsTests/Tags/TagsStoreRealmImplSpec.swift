import Combine
import Quick
import Mockingbird
import Nimble
import RealmSwift
@testable import Hymns

class TagStoreRealmImplSpec: QuickSpec {
    override func spec() {
        describe("using an in-memory realm") {
            var inMemoryRealm: Realm!
            var target: TagStoreRealmImpl!
            beforeEach {
                // Don't worry about force_try in tests.
                // swiftlint:disable:next force_try
                inMemoryRealm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TagStoreRealmImplSpec"))
                target = TagStoreRealmImpl(realm: inMemoryRealm)
            }
            afterEach {
                // Don't worry about force_try in tests.
                // swiftlint:disable:next force_try
                try! inMemoryRealm.write {
                    inMemoryRealm.deleteAll()
                }
                inMemoryRealm.invalidate()
            }

            context("store a few favorites") {
                beforeEach {
                    target.storeFavorite(FavoriteEntity(hymnIdentifier: classic1151, songTitle: "Hymn 1151"))

                    target
                        .storeFavorite(FavoriteEntity(hymnIdentifier: newSong145, songTitle: "Hymn: Jesus shall reign where\\u2019er the sun"))

                    target
                        .storeFavorite(FavoriteEntity(hymnIdentifier: cebuano123, songTitle: "Naghigda sa lubong\\u2014"))
                }
                describe("get the list of all favorites") {
                    it("should be 0 when we query tagEntity") {

                        let queryAllTags = target.querySelectedTags(tagSelected: nil)
                        expect(queryAllTags).to(haveCount(0))
                    }
                    it("should be 3 when we query FavoriteEntity") {

                        let queryAllFavorites = inMemoryRealm.objects(FavoriteEntity.self)
                        expect(queryAllFavorites).to(haveCount(3))
                    }
                }
            }
            context("store a few tags") {
                beforeEach {
                    target.storeRealmObject(TagEntity(hymnIdentifier: classic1151, songTitle: "Hymn 1151", tag: "Christ"))

                    target
                        .storeRealmObject(TagEntity(hymnIdentifier: newSong145, songTitle: "Hymn: Jesus shall reign where\\u2019er the sun", tag: "Bread and wine"))

                    target
                        .storeRealmObject(TagEntity(hymnIdentifier: cebuano123, songTitle: "Naghigda sa lubong\\u2014", tag: "Table"))
                }
                describe("getting all tags") {
                    it("should contain the stored songs sorted by last-stored") {
                        let resultsOfQuery = target.querySelectedTags(tagSelected: nil)
                        expect(resultsOfQuery).to(haveCount(3))
                    }
                }
                describe("getting one hymns tags after storing multiple tags for that hymn") {
                    beforeEach {
                        target.storeRealmObject(TagEntity(hymnIdentifier: classic1151, songTitle: "Hymn 1151", tag: "Is"))
                        target.storeRealmObject(TagEntity(hymnIdentifier: classic1151, songTitle: "Hymn 1151", tag: "Life"))
                        target.storeRealmObject(TagEntity(hymnIdentifier: classic1151, songTitle: "Hymn 1151", tag: "Peace"))
                    }
                    it("should contain a query number matching the number of tags for that hymn") {
                        let resultsOfQuery = target.queryTagsForHymn(hymnIdentifier: classic1151)
                        expect(resultsOfQuery).to(haveCount(4))
                    }
                }
            }
        }
    }
}
