//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import CollectionKit
import SwiftUI

class Automat: ObservableObject, Codable {
    
    /// Provides fast lookups, additions, but slow removals.
    private class DataModel: Codable {
        
        private(set) var stateNodes: [StateNode]
        private(set) var stateNodesByID: [StateNodeID: StateNode]
        
        private(set) var stateTransitions: [StateTransition]
        private(set) var stateTransitionsByID: [StateTransitionID: StateTransition]
        
        init() {
            stateNodes = []
            stateNodesByID = [:]
            stateTransitions = []
            stateTransitionsByID = [:]
        }
        
        init(_ data: DataModel) {
            stateNodes = data.stateNodes
            stateNodesByID = data.stateNodesByID
            stateTransitions = data.stateTransitions
            stateTransitionsByID = data.stateTransitionsByID
        }
        
        func state(by id: StateNodeID) -> StateNode? {
            stateNodesByID[id]
        }

        func transition(by id: StateTransitionID) -> StateTransition? {
            stateTransitionsByID[id]
        }
        
        func addStateNode(_ node: StateNode) {
            stateNodes.append(node)
            stateNodesByID[node.id] = node
        }
        
        func removeStateNode(id: StateNodeID) {
            stateNodes.removeFirst(where: { $0.id == id })
            stateNodesByID.removeValue(forKey: id)
        }
        
        func addStateTransition(_ transition: StateTransition) {
            stateTransitions.append(transition)
            stateTransitionsByID[transition.id] = transition
        }
        
        func removeStateTransition(id: StateTransitionID) {
            stateTransitions.removeFirst(where: { $0.id == id })
            stateTransitionsByID.removeValue(forKey: id)
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
            stateNodesByID = [:]
            for node in stateNodes {
                stateNodesByID[node.id] = node
            }
            stateTransitionsByID = [:]
            for transition in stateTransitions {
                stateTransitionsByID[transition.id] = transition
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(stateNodes, forKey: .stateNodes)
            try container.encode(stateTransitions, forKey: .stateTransitions)
        }
    }
    
    var stateNodes: [StateNode] {
        data.stateNodes
    }
    
    var stateTransitions: [StateTransition] {
        data.stateTransitions
    }

    var undoManager: UndoManager?

    private var data: DataModel
    
    init() {
        data = DataModel()
    }
    
    init(_ automat: Automat) {
        data = DataModel(automat.data)
        undoManager = automat.undoManager
    }
    
    func snapshot() -> Automat {
        return Automat(self)
    }
    
    func state(by id: StateNodeID) -> StateNode? {
        data.state(by: id)
    }

    func transition(by id: StateTransitionID) -> StateTransition? {
        data.transition(by: id)
    }
    
    @discardableResult
    func addState(at position: CGPoint, id: StateNodeID? = nil) -> StateNode {
                        
        let stateID = id ?? UUID()

        log(debug: "✨ Add state \(stateID) at (\(position.x), \(position.y))")

        objectWillChange.send()

        let node = StateNode(id: stateID, name: "New State", position: position, automat: self)
        data.addStateNode(node)

        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo ✨ add state \(stateID)")
            withAnimation(Animation.stateNodeFade) {
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
            _ = withAnimation(Animation.stateNodeFade) {
                automat.addState(at: position, id: id)
            }
        }
        
        data.removeStateNode(id: id)
    }
    
    func moveState(id: StateNodeID, from fromPoint: CGPoint, to toPoint: CGPoint) {
        
        log(debug: "🚀 Move state \(id) to (\(toPoint.x), \(toPoint.y))")
        
        guard let node = state(by: id) else {
            log(error: "⚠️ WARNING: Could not find node to move: \(id)")
            return
        }
        
        objectWillChange.send()

        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo 🚀 move state \(id) to (\(fromPoint.x), \(fromPoint.y))")
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
        
        node.updatePosition(toPoint)
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
        
        data.addStateTransition(transition)
        
        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo ✨ add transition \(transitionID)")
            withAnimation(Animation.stateTransitionFade) {
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
            _ = withAnimation(Animation.stateTransitionFade) {
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
        
        data.removeStateTransition(id: id)
    }

    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(DataModel.self, forKey: .data)
        for node in data.stateNodes {
            node.automat = self
        }
        for transition in data.stateTransitions {
            transition.automat = self
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
    }
}
