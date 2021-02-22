//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import CollectionKit
import SwiftUI

class Automat: ObservableObject, Codable {
    
    private(set) var stateNodes: [StateNode]
    
    var stateTransitions: [StateTransition]
    
    var undoManager: UndoManager?
    
    init() {
        stateNodes = []
        stateTransitions = []
    }
    
    init(_ automat: Automat) {
        stateNodes = automat.stateNodes
        stateTransitions = automat.stateTransitions
    }
    
    func snapshot() -> Automat {
        return Automat(self)
    }
    
    func state(by id: StateNodeID) -> StateNode? {
        stateNodes.first(where: { $0.id == id })
    }

    func transition(by id: StateTransitionID) -> StateTransition? {
        stateTransitions.first(where: { $0.id == id })
    }
    
    @discardableResult
    func addState(at position: CGPoint, id: StateNodeID? = nil) -> StateNode {
                        
        let stateID = id ?? UUID()

        log(debug: "✨ Add state \(stateID) at (\(position.x), \(position.y))")

        objectWillChange.send()

        let node = StateNode(id: stateID, name: "New State", position: position, automat: self)
        stateNodes.append(node)
                
        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo ✨ add state \(stateID)")
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                automat.removeState(id: stateID)
            }
        }
        
        return node
    }
    
    func removeState(id: StateNodeID) {
        
        log(debug: "🗑 Remove state \(id)")

        guard let node = state(by: id) else {
            log(error: "⚠️ WARNING: Could not find node to remove: \(id)")
            return
        }
        
        objectWillChange.send()

        for transitionID in node.outgoingTransitions {
            removeTransition(id: transitionID)
        }
        
        for transitionID in node.incomingTransitions {
            removeTransition(id: transitionID)
        }

        let position = node.position
        
        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo 🗑 remove state \(id) at (\(position.x), \(position.y))")
            _ = withAnimation(Animation.easeInOut(duration: 0.2)) {
                automat.addState(at: position, id: id)
            }
        }
        
        stateNodes.removeFirst(where: { $0.id == id })
    }
    
    func moveState(id: StateNodeID, from fromPoint: CGPoint, to toPoint: CGPoint) {
        
        log(debug: "🚀 Move state \(id) to (\(toPoint.x), \(toPoint.y))")
        
        guard let node = stateNodes.first(where: { $0.id == id }) else {
            log(error: "⚠️ WARNING: Could not find node to move: \(id)")
            return
        }
        
        objectWillChange.send()

        undoManager?.registerUndo(withTarget: self) { automat in
            guard let undoNode = automat.state(by: id) else {
                log(error: "⚠️ WARNING: Could find node to undo move: \(id)")
                return
            }
            log(debug: "↩️ Undo 🚀 move state \(id) to (\(fromPoint.x), \(fromPoint.y))")
            undoNode.position = fromPoint
            automat.moveState(id: id, from: toPoint, to: fromPoint)
        }
        
        
        for transitionID in node.outgoingTransitions {
            if let transition = transition(by: transitionID) {
                transition.objectWillChange.send()
            }
        }

        for transitionID in node.incomingTransitions {
            if let transition = transition(by: transitionID) {
                transition.objectWillChange.send()
            }
        }
        
        node.position = toPoint
    }
    
    @discardableResult
    func addTransition(from fromNodeID: StateNodeID, to toNodeID: StateNodeID, id: StateTransitionID? = nil) -> StateTransition {
        let transitionID = id ?? UUID()
                        
        log(debug: "✨ Add transition \(transitionID)")

        objectWillChange.send()

        let transition = StateTransition(id: transitionID, from: fromNodeID, to: toNodeID, automat: self)
        
        guard let fromNode = state(by: fromNodeID) else {
            log(error: "⚠️ WARNING: Could not find 'from' node to add transition to: \(fromNodeID)")
            fatalError()
        }

        guard let toNode = state(by: toNodeID) else {
            log(error: "⚠️ WARNING: Could not find 'to' node to add transition to: \(toNodeID)")
            fatalError()
        }
        
        fromNode.addOutgoingTransition(transition.id)
        toNode.addIncomingTransition(transition.id)
        
        stateTransitions.append(transition)
        
        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo ✨ add transition \(transitionID)")
            withAnimation(Animation.easeInOut(duration: 0.2)) {
                automat.removeTransition(id: transitionID)
            }
        }
        
        return transition
    }
    
    func removeTransition(id: StateTransitionID) {
        
        log(debug: "🗑 Remove transition \(id)")

        guard let transition = transition(by: id) else {
            log(error: "⚠️ WARNING: Could not find transition to remove: \(id)")
            return
        }
        
        objectWillChange.send()
        
        let fromID = transition.fromNode
        let toID = transition.toNode
        
        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo 🗑 remove transition \(id)")
            _ = withAnimation(Animation.easeInOut(duration: 0.2)) {
                automat.addTransition(from: fromID, to: toID, id: id)
            }
        }
        
        guard let fromNode = state(by: fromID) else {
            log(error: "⚠️ WARNING: Could not find 'from' node to remove transition from: \(fromID)")
            fatalError()
        }

        guard let toNode = state(by: toID) else {
            log(error: "⚠️ WARNING: Could not find 'to' node to remove transition from: \(toID)")
            fatalError()
        }
        
        
        fromNode.removeOutgoingTransition(transition.id)
        toNode.removeIncomingTransition(transition.id)
        
        stateTransitions.removeFirst(where: { $0.id == id })
    }

    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case stateNodes
        case stateTransitions
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stateNodes = try container.decode([StateNode].self, forKey: .stateNodes)
        stateTransitions = try container.decode([StateTransition].self, forKey: .stateTransitions)
        for node in stateNodes {
            node.automat = self
        }
        for node in stateTransitions {
            node.automat = self
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stateNodes, forKey: .stateNodes)
        try container.encode(stateTransitions, forKey: .stateTransitions)
    }
}
