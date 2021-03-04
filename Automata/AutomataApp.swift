//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

@main
struct AutomataApp: App {
    
    @AppStorage("appTheme") var appTheme: String = "system"
        
    var body: some Scene {
        DocumentGroup(newDocument: { AutomatDocument() }) { file in
            ContentView()
                .environmentObject(file.document.automat)
        }
        .commands {
            
            CommandGroup(replacing: .appInfo) {
                Button(action: {
                    AboutView.present()
                }) {
                    Text("About Automata")
                }.modifier(MenuButtonStyling())
            }
            
            CommandGroup(after: .windowArrangement) {
                Button(action: {
                    NSApp.appearance = NSAppearance(named: .darkAqua)
                    appTheme = "dark"
                }) {
                    Text("Dark mode").fontWeight(.medium)
                }.modifier(MenuButtonStyling())

                Button(action: {
                    NSApp.appearance = NSAppearance(named: .aqua)
                    appTheme = "light"
                }) {
                    Text("Light mode").fontWeight(.medium)
                }.modifier(MenuButtonStyling())

                Button(action: {
                    NSApp.appearance = nil
                    appTheme = "system"
                }) {
                    Text("System mode").fontWeight(.medium)
                }.modifier(MenuButtonStyling())
            }

            #if DEBUG
            CommandMenu("Debug") {
                Button(action: {
                    print("Stuff!")
                }) {
                    Text("Interesting Stuff").fontWeight(.medium)
                }.modifier(MenuButtonStyling())
                .keyboardShortcut("i")

                Button(action: {
                    print("Unused")
                }) {
                    Text("Unused Menu Option").fontWeight(.medium)
                }.modifier(MenuButtonStyling())
                .keyboardShortcut("u")
            }
            #endif
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
