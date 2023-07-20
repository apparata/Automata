//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import Splash

struct SwiftCode: View {
    
    @EnvironmentObject private var automat: Automat
    
    var string: String
    
    private let theme: Splash.Theme
    
    var body: some View {
        highlightSwift(string, theme: theme)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(theme.backgroundColor))
            .fixedSize(horizontal: true, vertical: true)
    }
    
    init(_ string: String, theme: Splash.Theme = .automatDark) {
        self.string = string
        self.theme = theme
    }
    
    private func highlightSwift(_ string: String, theme: Splash.Theme) -> Text {
        let highlighter = SyntaxHighlighter(format: SplashSwiftUIOutputFormat(theme: theme))
        let text = highlighter.highlight(string)
        return text
    }
}
