//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct DebugCommands: Commands {
            
    var body: some Commands {
        CommandMenu("Debug") {
            Button {
                print("Stuff!")
            } label: {
                Text("Interesting Stuff")
            }
            .keyboardShortcut("i")

            Button {
                print("Unused")
            } label: {
                Text("Unused Menu Option")
            }
            .keyboardShortcut("u")
        }
    }
}
