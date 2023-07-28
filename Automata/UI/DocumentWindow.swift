//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct DocumentWindow: Scene {
    
    @StateObject var editState = StateEditState()
    
    @AppStorage(\AppSettings.colorMode) private var colorMode
    
    var body: some Scene {
        DocumentGroup(newDocument: { AutomatDocument() }) { file in
            ContentView(url: file.fileURL)
                .frame(minWidth: 800, minHeight: 400)
                .environmentObject(file.document.automat)
                .environmentObject(editState)
                .focusedSceneObject(file.document.automat)
                .focusedSceneObject(editState)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
                        switch colorMode {
                        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
                        case .light: NSApp.appearance = NSAppearance(named: .aqua)
                        case .system: NSApp.appearance = nil
                        }
                    }
                }
        }
        .commands {
            AppCommands()
        }
    }
}

class StateEditState: ObservableObject {
    @Published var editingNodeWithID: StateNodeID?
}
