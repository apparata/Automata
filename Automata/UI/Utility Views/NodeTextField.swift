//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

#if os(macOS)

import Cocoa
import SwiftUI

extension Notification.Name {
    static let nodeTextFieldIsNowEditing = Self("nodeTextFieldIsNowEditing")
}

struct NodeTextField: NSViewRepresentable {
    
    @Binding var text: String
        
    var nodeID: StateNodeID
    
    static func notifyTextFieldIsNowEditing(nodeID: StateNodeID) {
        NotificationCenter.default.post(name: .nodeTextFieldIsNowEditing, object: nodeID)
    }
    
    init(text: Binding<String>, nodeID: StateNodeID) {
        _text = text
        self.nodeID = nodeID
    }

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.focusRingType = .none
        textView.textColor = NSColor.clear
        textView.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        textView.textContainer?.lineBreakMode = .byClipping
        textView.textContainer?.maximumNumberOfLines = 1
        textView.textContainer?.lineFragmentPadding = 0
        textView.isEditable = false
        textView.isHidden = true
        
        context.coordinator.textView = textView
        context.coordinator.nodeID = nodeID
        
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.didReceiveStopEditing(_:)), name: .keyEventViewResumeListeningToKeyDown, object: nil)

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.didReceiveStartEditing(_:)), name: .nodeTextFieldIsNowEditing, object: nil)

        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.string = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(nodeID: nodeID) { text in
            self.text = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var mutator: (_ text: String) -> Void
        
        weak var textView: NSTextView?
        
        var nodeID: StateNodeID
        
        init(nodeID: StateNodeID, mutator: @escaping (String) -> Void) {
            self.mutator = mutator
            self.nodeID = nodeID
        }

        public func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                mutator(textView.string)
            }
        }
        
        public func textView(_ textView: NSTextView,
                             shouldChangeTextIn affectedCharRange: NSRange,
                             replacementString: String?) -> Bool {
            return !(replacementString?.contains("\n") ?? false)
        }
        
        public func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                textView.window?.makeFirstResponder(nil)
                mutator(textView.string)
                textView.isEditable = false
                textView.isHidden = true
                return true
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                textView.window?.makeFirstResponder(nil)
                mutator(textView.string)
                textView.isEditable = false
                textView.isHidden = true
                return true
            }
            
            return false
        }
        
        @objc
        func didReceiveStopEditing(_ notification: Notification) {
            textView?.isEditable = false
            textView?.isHidden = true
        }

        @objc
        func didReceiveStartEditing(_ notification: Notification) {
            guard let id = notification.object as? StateNodeID, id == nodeID else {
                textView?.isEditable = false
                textView?.isHidden = true
                return
            }
            guard let textView = textView else {
                return
            }
            if textView.string == "New State" {
                mutator("")
            }
            textView.isEditable = true
            textView.isHidden = false
            textView.window?.makeFirstResponder(textView)
        }

    }
}

#endif

