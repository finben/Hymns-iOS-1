import SwiftUI
import UIKit
import Resolver

struct AboutUsDialogView: View {

    @Environment(\.presentationMode) var presentationMode
    private let analytics: AnalyticsLogger = Resolver.resolve()
    private let application: Application = Resolver.resolve()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                    Text("About us").fontWeight(.bold).padding(.leading)
                    Spacer()
                }.padding().padding(.top).foregroundColor(.primary)
                Text("Hello There 👋").font(.title).fontWeight(.bold).padding()
                Text("We're the team behind this hymnal app. We love Jesus, and we created this app as a free resource to help other believers access the thousands of hymns available on the internet. We also built in support for the hymns indexed by the Living Stream Ministry hymnal.").font(.callout).padding()
                Text("Let the word of Christ dwell in you richly in all wisdom, teaching and admonishing one another with psalms and hymns and spiritual songs, singing with grace in your hearts to God.")
                    .font(.body).fontWeight(.light).padding().padding(.horizontal)
                HStack {
                    Spacer()
                    Text("- Col. 3:16").font(.body).fontWeight(.bold).padding(.trailing)
                }
                // Cant get this dumb thing in line. It won't concatenate the text since it has a tapGesture.
                // Right now the whole sentence will link you.
                // https://stackoverflow.com/questions/59359730/is-it-possible-to-add-an-in-line-button-within-a-text
                Group {
                    Text("For a free study Bible tap ") + Text(NSLocalizedString("here.", comment: "The 'here' in 'tap here' that links to BFA to get a free Bible")).fontWeight(.bold).underline()
                }.font(.callout).padding().onTapGesture {
                    self.analytics.logBFALinkClicked()
                    self.application.open(URL(string: "https://biblesforamerica.org/")!)
                }
                Spacer()
            }
        }
    }
}

#if DEBUG
struct AboutUsDialogView_Previews: PreviewProvider {
    static var previews: some View {
        AboutUsDialogView()
    }
}
#endif
