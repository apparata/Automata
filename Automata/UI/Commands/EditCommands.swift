//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct EditCommands: Commands {
    
    @FocusedObject var automat: Automat?
    @FocusedObject var editState: StateEditState?
        
    var body: some Commands {
        
        CommandGroup(after: .textEditing) {
            Button {
                editSelectedNode()
            } label: {
                Text("Rename State")
            }
            .disabled(!isRenameEnabled)
            .keyboardShortcut("r")
        }
    }
    
    private var isRenameEnabled: Bool {
        guard let automat, let editState else {
            return false
        }
        guard automat.selectedNodesByID.count == 1 else {
            return false
        }
        guard editState.editingNodeWithID == nil else {
            return false
        }
        return true
    }
    
    private func editSelectedNode() {
        guard let automat, let editState else {
            return
        }
        editState.editingNodeWithID = automat.selectedNodesByID.first
    }
}
