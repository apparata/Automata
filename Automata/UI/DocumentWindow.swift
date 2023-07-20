//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct DocumentWindow: Scene {
    
    @StateObject var editState = StateEditState()
    
    var body: some Scene {
        DocumentGroup(newDocument: { AutomatDocument() }) { file in
            ContentView(url: file.fileURL)
                .frame(minWidth: 800, minHeight: 400)
                .environmentObject(file.document.automat)
                .environmentObject(editState)
                .focusedSceneObject(file.document.automat)
                .focusedSceneObject(editState)
        }
        .commands {
            AppCommands()
        }
    }
}

class StateEditState: ObservableObject {
    @Published var editingNodeWithID: StateNodeID?
}
