//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

@main
struct AutomataApp: App {
    
    @AppStorage("appTheme") var appTheme: String = "system"
        
    var body: some Scene {
        DocumentGroup(newDocument: { AutomatDocument() }) { file in
            ContentView(url: file.fileURL)
                .frame(minWidth: 800, minHeight: 400)
                .environmentObject(file.document.automat)
        }
        .commands {
            AppCommands(appTheme: $appTheme)
        }
        
        Settings {
            SettingsView()
        }
    }
}

struct MenuButtonStyling: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.primary)
            .padding(.bottom, 2)
            .padding(.top, 1)
    }
}
