import Foundation
import SwiftUI

enum BrowseTab {
    case tags(AnyView)
    case classic(AnyView)
    case newTunes(AnyView)
    case newSongs(AnyView)
    case children(AnyView)
    case scripture(AnyView)
    case all(AnyView)
}

extension BrowseTab {

    var label: String {
        switch self {
        case .tags:
        return NSLocalizedString("Tags", comment: "Browse tags")
        case .classic:
            return NSLocalizedString("Classic Hymns", comment: "Display name of 'Classic hymns', usually appears just by itself (i.e. as a title)")
        case .newTunes:
            return NSLocalizedString("New Tunes", comment: "Display name of 'New Tunes'. Usually appears just by itself (i.e. as a title)")
        case .newSongs:
            return NSLocalizedString("New Songs", comment: "Display name of 'New Songs'. Usually appears just by itself (i.e. as a title)")
        case .children:
            return NSLocalizedString("Children's Songs", comment: "Display name of 'Children's Songs'. Usually appears just by itself (i.e. as a title)")
        case .scripture:
            return NSLocalizedString("Scripture Songs", comment: "Display name of 'Scripture Songs'. Usually appears just by itself (i.e. as a title)")
        case .all:
            return NSLocalizedString("All Songs", comment: "Browse all songs")
        }
    }
}

extension BrowseTab: TabItem {

    var id: String { self.label }

    var content: AnyView {
        switch self {
        case .tags(let content):
            return content
        case .classic(let content):
            return content
        case .newTunes(let content):
            return content
        case .newSongs(let content):
            return content
        case .children(let content):
            return content
        case .scripture(let content):
            return content
        case .all(let content):
            return content
        }
    }

    var selectedLabel: some View {
        Text(label).font(.body).foregroundColor(.accentColor).padding(.horizontal)
    }

    var unselectedLabel: some View {
        Text(label).font(.body).foregroundColor(.primary).padding(.horizontal)
    }

    var a11yLabel: Text {
        Text(label)
    }

    static func == (lhs: BrowseTab, rhs: BrowseTab) -> Bool {
        lhs.label == rhs.label
    }
}

#if DEBUG
struct BrowseTab_Previews: PreviewProvider {
    static var previews: some View {
        var classicTab: BrowseTab = .classic(EmptyView().eraseToAnyView())
        let newTunesTab: BrowseTab = .newTunes(EmptyView().eraseToAnyView())
        let newSongsTab: BrowseTab = .newSongs(EmptyView().eraseToAnyView())
        let childrensTab: BrowseTab = .children(EmptyView().eraseToAnyView())
        let scripturesTab: BrowseTab = .scripture(EmptyView().eraseToAnyView())
        let allTab: BrowseTab = .all(EmptyView().eraseToAnyView())

        let currentTabClassic = Binding<BrowseTab>(
            get: {classicTab},
            set: {classicTab = $0})
        return Group {
            GeometryReader { geometry in
                TabBar(currentTab: currentTabClassic,
                       geometry: geometry,
                       tabItems: [classicTab, newTunesTab, newSongsTab, childrensTab, scripturesTab, allTab]).toPreviews()
            }
        }
    }
}
#endif
