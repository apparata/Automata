//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct AboutCommand: Commands {

    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        // Replace the About window menu option.
        CommandGroup(replacing: .appInfo) {
            Button {
                openWindow(id: AboutWindow.windowID)
            } label: {
                Text("About \(Bundle.main.name)")
            }
        }
    }
}
