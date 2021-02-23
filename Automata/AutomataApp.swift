//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

@main
struct AutomataApp: App {
        
    var body: some Scene {
        DocumentGroup(newDocument: { AutomatDocument() }) { file in
            ContentView()
                .environmentObject(file.document.automat)
        }
    }
}
