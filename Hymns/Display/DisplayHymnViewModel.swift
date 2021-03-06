import Combine
import RealmSwift
import Resolver
import SwiftUI

class DisplayHymnViewModel: ObservableObject {

    typealias Title = String
    typealias Lyrics = [Verse]

    @Published var isLoaded = false
    @Published var title: String = ""
    @Published var currentTab: HymnLyricsTab
    @Published var tabItems: [HymnLyricsTab] = [HymnLyricsTab]()
    @Published var isFavorited: Bool?
    @Published var bottomBar: DisplayHymnBottomBarViewModel?

    let identifier: HymnIdentifier

    private let analytics: AnalyticsLogger
    private let backgroundQueue: DispatchQueue
    private let favoriteStore: FavoriteStore
    private let historyStore: HistoryStore
    private let mainQueue: DispatchQueue
    private let pdfLoader: PDFLoader
    private let repository: HymnsRepository
    private let systemUtil: SystemUtil
    private let storeInHistoryStore: Bool

    /**
     * Title of song for when the song is displayed as a song result in a list of results. Used to store into the Favorites/Recents store.
     */
    private var resultsTitle: String = ""
    private var disposables = Set<AnyCancellable>()

    init(analytics: AnalyticsLogger = Resolver.resolve(),
         backgroundQueue: DispatchQueue = Resolver.resolve(name: "background"),
         favoriteStore: FavoriteStore = Resolver.resolve(),
         hymnToDisplay identifier: HymnIdentifier,
         hymnsRepository repository: HymnsRepository = Resolver.resolve(),
         historyStore: HistoryStore = Resolver.resolve(),
         mainQueue: DispatchQueue = Resolver.resolve(name: "main"),
         pdfPreloader: PDFLoader = Resolver.resolve(),
         systemUtil: SystemUtil = Resolver.resolve(),
         storeInHistoryStore: Bool = false) {
        self.analytics = analytics
        self.backgroundQueue = backgroundQueue
        self.currentTab = .lyrics(HymnLyricsView(viewModel: HymnLyricsViewModel(hymnToDisplay: identifier)).maxSize().eraseToAnyView())
        self.favoriteStore = favoriteStore
        self.historyStore = historyStore
        self.identifier = identifier
        self.mainQueue = mainQueue
        self.pdfLoader = pdfPreloader
        self.repository = repository
        self.systemUtil = systemUtil
        self.storeInHistoryStore = storeInHistoryStore
    }

    func fetchHymn() {
        analytics.logDisplaySong(hymnIdentifier: identifier)
        repository
            .getHymn(identifier)
            .subscribe(on: backgroundQueue)
            .receive(on: mainQueue)
            .sink(
                receiveValue: { [weak self] hymn in
                    guard let self = self else { return }
                    self.isLoaded = true
                    guard let hymn = hymn else { return }

                    switch self.identifier.hymnType {
                    case .newTune, .newSong, .children, .howardHigashi:
                        self.title = hymn.title
                    default:
                        self.title = "\(self.identifier.hymnType.displayLabel) \(self.identifier.hymnNumber)"
                    }

                    self.resultsTitle = hymn.resultTitle

                    self.tabItems = [.lyrics(HymnLyricsView(viewModel: HymnLyricsViewModel(hymnToDisplay: self.identifier)).maxSize().eraseToAnyView())]

                    if self.systemUtil.isNetworkAvailable() {
                        let chordsPath = hymn.pdfSheet?.data.first(where: { datum -> Bool in
                            datum.value == DatumValue.text.rawValue
                        })?.path
                        let chordsUrl = chordsPath.flatMap({ path -> URL? in
                            HymnalNet.url(path: path)
                        })
                        if let chordsUrl = chordsUrl {
                            self.pdfLoader.load(url: chordsUrl)
                            self.tabItems.append(.chords(DisplayHymnPdfView(url: chordsUrl).eraseToAnyView()))
                        }

                        let guitarPath = hymn.pdfSheet?.data.first(where: { datum -> Bool in
                            datum.value == DatumValue.guitar.rawValue
                        })?.path
                        let guitarUrl = guitarPath.flatMap({ path -> URL? in
                            HymnalNet.url(path: path)
                        })
                        if let guitarUrl = guitarUrl {
                            self.pdfLoader.load(url: guitarUrl)
                            self.tabItems.append(.guitar(DisplayHymnPdfView(url: guitarUrl).eraseToAnyView()))
                        }

                        let pianoPath = hymn.pdfSheet?.data.first(where: { datum -> Bool in
                            datum.value == DatumValue.piano.rawValue
                        })?.path
                        let pianoUrl = pianoPath.flatMap({ path -> URL? in
                            HymnalNet.url(path: path)
                        })
                        if let pianoUrl = pianoUrl {
                            self.pdfLoader.load(url: pianoUrl)
                            self.tabItems.append(.piano(DisplayHymnPdfView(url: pianoUrl).eraseToAnyView()))
                        }
                    }

                    self.bottomBar = DisplayHymnBottomBarViewModel(hymnToDisplay: self.identifier)
                    self.fetchFavoriteStatus()
                    if self.storeInHistoryStore {
                        self.historyStore.storeRecentSong(hymnToStore: self.identifier, songTitle: self.resultsTitle)
                    }
            }).store(in: &disposables)
    }

    func fetchFavoriteStatus() {
        favoriteStore.isFavorite(hymnIdentifier: identifier)
            .compactMap({ isFavorited -> Bool? in
                isFavorited
            })
            .replaceError(with: nil)
            .receive(on: mainQueue)
            .sink(receiveValue: { isFavorited in
                self.isFavorited = isFavorited
            }).store(in: &disposables)
    }
    func toggleFavorited() {
        isFavorited.map { isFavorited in
            if isFavorited {
                favoriteStore.deleteFavorite(primaryKey: FavoriteEntity.createPrimaryKey(hymnIdentifier: self.identifier))
            } else {
                favoriteStore.storeFavorite(FavoriteEntity(hymnIdentifier: self.identifier, songTitle: self.resultsTitle))
            }
        }
    }
}

extension DisplayHymnViewModel: Equatable {
    static func == (lhs: DisplayHymnViewModel, rhs: DisplayHymnViewModel) -> Bool {
        lhs.identifier == rhs.identifier && lhs.storeInHistoryStore && rhs.storeInHistoryStore
    }
}
