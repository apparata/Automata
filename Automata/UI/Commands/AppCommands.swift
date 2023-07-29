//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox

struct AppCommands: Commands {
            
    var body: some Commands {
        AboutCommand()
        ColorSchemeCommands()
        EditCommands()
        HelpCommands()
        
        #if DEBUG
        DebugCommands()
        #endif
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
