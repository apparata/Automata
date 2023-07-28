//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox
import AttributionsUI

@main
struct AutomataApp: App {
            
    @AppStorage(\AppSettings.colorMode) private var colorMode
                
    var body: some Scene {
        DocumentWindow()
            // This has to be here to work, or menu won't trigger a change
            .onChange(of: colorMode) { theme in
                switch theme {
                case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
                case .light: NSApp.appearance = NSAppearance(named: .aqua)
                case .system: NSApp.appearance = nil
                }
            }
   
        SettingsWindow()
        
        AboutWindow(developedBy: "Apparata AB",
                    attributionsWindowID: AttributionsWindow.windowID)
        
        AttributionsWindow([
                ("Splash", .mit(year: "2018", holder: "John Sundell"))
            ],
            header: "The following software may be included in this product.")
    }
}
