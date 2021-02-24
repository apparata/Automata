//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import Carbon.HIToolbox.Events

struct KeyEventView: NSViewRepresentable {

    enum Event {
        case delete
    }

    let onKeyDown: (Event) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyNSEventView()
        view.onEvent = onKeyDown
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class KeyNSEventView: NSView {
    
    var onEvent: (KeyEventView.Event) -> Void = { _ in }

    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == String(UnicodeScalar(NSDeleteCharacter)!) {
            onEvent(.delete)
        } else {
            super.keyDown(with: event)
        }
    }
}
