//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import Splash
import Combine

struct DebouncedSwiftCode: View {
    
    @EnvironmentObject private var automat: Automat
    
    let string: String
    
    let theme: Splash.Theme
        
    @StateObject private var model = SwiftCodeModel()
        
    var body: some View {
        model.highlightSwift(string, theme: theme)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(theme.backgroundColor))
            .fixedSize(horizontal: true, vertical: true)
    }
}

class SwiftCodeModel: ObservableObject {
    
    var highlightedText: Text = Text("")
    
    private var isFirstHighlight: Bool = true
    
    private let subject = PassthroughSubject<(String, Splash.Theme), Never>()
    
    private var subscription: AnyCancellable? = nil
        
    private let queue = DispatchQueue(label: "io.apparata.highlighter", qos: .userInitiated)

    init() {
        subscription = subject
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [weak self] (string, theme) in
                self?.highlightInBackground(string, theme: theme)
            }
    }
    
    func highlightSwift(_ string: String, theme: Splash.Theme) -> Text {
        if isFirstHighlight {
            isFirstHighlight = false
            queue.asyncAfter(deadline: .now() + .milliseconds(800)) { [weak self] in
                self?.highlightInBackground(string, theme: theme, animated: true)
            }
            return highlightedText
        }
        subject.send((string, theme))
        return highlightedText
    }
    
    func highlightInBackground(_ string: String, theme: Splash.Theme, animated: Bool = false) {
        queue.async { [weak self] in
            let highlighter = SyntaxHighlighter(format: SplashSwiftUIOutputFormat(theme: theme))
            let text = highlighter.highlight(string)
            DispatchQueue.main.async {
                if animated {
                    withAnimation(.codeRefreshFade) {
                        self?.objectWillChange.send()
                        self?.highlightedText = text
                    }
                } else {
                    self?.objectWillChange.send()
                    self?.highlightedText = text
                }
            }
        }
    }
}
