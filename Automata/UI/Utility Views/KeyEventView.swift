//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import AppKit

extension Notification.Name {
    static let keyEventViewResumeListeningToKeyDown = Self("keyEventViewResumeListeningToKeyDown")
}

struct KeyModifierState {
    let command: Bool
    let control: Bool
    let option: Bool
    let shift: Bool
}

struct KeyEventView: NSViewRepresentable {

    enum Event {
        case delete
    }
    
    static func resumeListeningToKeyDown() {
        NotificationCenter.default.post(name: .keyEventViewResumeListeningToKeyDown, object: nil)
    }

    let onKeyDown: (Event) -> Void
    
    let onFlagsChanged: (KeyModifierState) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyNSEventView()
        view.onEvent = onKeyDown
        view.onFlagsChanged = onFlagsChanged
        NotificationCenter.default.addObserver(view, selector: #selector(KeyNSEventView.didReceiveNotification(_:)), name: .keyEventViewResumeListeningToKeyDown, object: nil)
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class KeyNSEventView: NSView {
    
    var onEvent: (KeyEventView.Event) -> Void = { _ in }
    
    var onFlagsChanged: (KeyModifierState) -> Void = { _ in }

    override var acceptsFirstResponder: Bool { true }
        
    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == String(UnicodeScalar(NSDeleteCharacter)!) {
            onEvent(.delete)
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func flagsChanged(with event: NSEvent) {
        let state = KeyModifierState(
            command: event.modifierFlags.contains(.command),
            control: event.modifierFlags.contains(.control),
            option: event.modifierFlags.contains(.option),
            shift: event.modifierFlags.contains(.shift))
        onFlagsChanged(state)
        super.flagsChanged(with: event)
    }
    
    @objc func didReceiveNotification(_ notification: Notification) {
        guard let window = window else {
            return
        }
        if window.firstResponder != self {
            window.makeFirstResponder(self)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        DispatchQueue.main.async {
            guard let window = self.window else {
                return
            }
            guard let firstResponder = window.firstResponder else {
                return
            }
            let type = "\(type(of: firstResponder))"
            if type == "AppKitWindow" {
                window.makeFirstResponder(self)
            }
        }
        return super.resignFirstResponder()
    }
}
