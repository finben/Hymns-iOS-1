import SwiftUI

//The custom title view modifier is meant to be set up to replace navigationbartitle texts. By doing this we gain alot more ability to customize the title text at the top of the screen. In addition, we also avoid being forced into using navigation bar titles  which comes with other issues as well.
struct CustomTitleLayout: ViewModifier {
    let font = Font.title.weight(.bold)
    func body(content: Content) -> some View {
        content
            .padding()
            .font(font)
    }
}

extension View {
    func customTitleLayout() -> some View {
        return self.modifier(CustomTitleLayout())
    }
}
