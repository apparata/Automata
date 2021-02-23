//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

struct ContentView: View {
        
    @ObservedObject var automat: Automat
        
    @Environment(\.undoManager) private var undoManager
    
    var body: some View {
        Canvas(automat: automat)
            .onChange(of: undoManager, perform: automat.updateUndoManager)
    }
}
