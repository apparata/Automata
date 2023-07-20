//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct AttributionsWindow: Scene {

    static let windowID = "attributions"
    
    var body: some Scene {
        Window("Attributions", id: Self.windowID) {
            AttributionsView()
                .frame(minWidth: 500, minHeight: 300)
        }
        .defaultPosition(.center)
        .defaultSize(width: 500, height: 260)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
    }
}
