//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI
struct AppCommands: Commands {
    
    @Binding var appTheme: String
    
    var body: some Commands {
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
}
