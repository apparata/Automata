//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import CollectionKit
import SwiftUI

// MARK: - Automat

class Automat: ObservableObject, Codable {
        
    var stateNodes: [StateNode] {
        data.stateNodes
    }
    
    var stateTransitions: [StateTransition] {
        data.stateTransitions
    }

    private var undoManager: UndoManager?

    private var data: DataModel
    
    init() {
        data = DataModel()
    }
    
    // MARK: - Snapshotting
    
    init(_ automat: Automat) {
        data = DataModel(automat.data)
        undoManager = automat.undoManager
    }
    
    func snapshot() -> Automat {
        return Automat(self)
    }
    
    // MARK: - Undo Management
    
    func updateUndoManager(_ undoManager: UndoManager?) {
        self.undoManager = undoManager
    }
    
    // MARK: - Lookup
    
    func state(by id: StateNodeID) -> StateNode? {
        data.state(by: id)
    }

    func transition(by id: StateTransitionID) -> StateTransition? {
        data.transition(by: id)
    }
    
    // MARK: - Add State
    
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
    
    // MARK: - Remove State
    
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
    
    // MARK: - Move State
    
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
    
    // MARK: Add Transition
    
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
    
    // MARK: - Remove Transition
    
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
    
    // MARK: - Selection
    
    func isStateNodeSelected(id: StateNodeID) -> Bool {
        return data.isStateNodeSelected(id: id)
    }
        
    func selectStateNodes(ids: Set<StateNodeID>) {
        
        let idsString = ids.map(\.uuidString).joined(separator: ", ")
        log(debug: "👈 Select state nodes \(idsString)")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo 👈 select state nodes \(idsString)")
            withAnimation(Animation.stateTransitionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.selectStateNodes(ids: ids)
    }
    
    func addStateNodesToSelection(ids: Set<StateNodeID>) {
        
        let idsString = ids.map(\.uuidString).joined(separator: ", ")
        log(debug: "👈 Add state nodes to selection \(idsString)")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo 👈 add state nodes to selection \(idsString)")
            withAnimation(Animation.stateTransitionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.addStateNodesToSelection(ids: ids)
    }
    
    func deselectStateNode(ids: Set<StateNodeID>) {
        
        let idsString = ids.map(\.uuidString).joined(separator: ", ")
        log(debug: "✋ Remove state nodes from selection \(idsString)")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo ✋ remove state nodes from selection \(idsString)")
            withAnimation(Animation.stateTransitionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.deselectStateNodes(ids: ids)
    }

    func clearSelection() {
        
        log(debug: "👋 Clear selection")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo 👋 clear selection")
            withAnimation(Animation.selectionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.clearSelection()
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

private extension Automat {

    // MARK: - Internal Data Model
    
    /// Provides fast lookups, additions, but slow removals.
    private class DataModel: Codable {
        
        private(set) var stateNodes: [StateNode]
        private(set) var stateNodesByID: [StateNodeID: StateNode]
        
        private(set) var stateTransitions: [StateTransition]
        private(set) var stateTransitionsByID: [StateTransitionID: StateTransition]
        
        private(set) var selectedNodesByID: Set<StateNodeID>
        
        init() {
            stateNodes = []
            stateNodesByID = [:]
            stateTransitions = []
            stateTransitionsByID = [:]
            selectedNodesByID = []
        }
        
        init(_ data: DataModel) {
            stateNodes = data.stateNodes
            stateNodesByID = data.stateNodesByID
            stateTransitions = data.stateTransitions
            stateTransitionsByID = data.stateTransitionsByID
            selectedNodesByID = data.selectedNodesByID
        }
        
        // MARK: - Lookup
        
        func state(by id: StateNodeID) -> StateNode? {
            stateNodesByID[id]
        }

        func transition(by id: StateTransitionID) -> StateTransition? {
            stateTransitionsByID[id]
        }
        
        // MARK: - Add / Remove State
        
        func addStateNode(_ node: StateNode) {
            stateNodes.append(node)
            stateNodesByID[node.id] = node
        }
        
        func removeStateNode(id: StateNodeID) {
            stateNodes.removeFirst(where: { $0.id == id })
            stateNodesByID.removeValue(forKey: id)
        }
        
        // MARK: - Add / Remove Transition
        
        func addStateTransition(_ transition: StateTransition) {
            stateTransitions.append(transition)
            stateTransitionsByID[transition.id] = transition
        }
        
        func removeStateTransition(id: StateTransitionID) {
            stateTransitions.removeFirst(where: { $0.id == id })
            stateTransitionsByID.removeValue(forKey: id)
        }
        
        // MARK: - Selection
        
        func isStateNodeSelected(id: StateNodeID) -> Bool {
            return selectedNodesByID.contains(id)
        }
        
        func selectStateNodes(ids: Set<StateNodeID>) {
            selectedNodesByID = Set(ids)
        }
        
        func addStateNodesToSelection(ids: Set<StateNodeID>) {
            selectedNodesByID.formUnion(ids)
        }
        
        func deselectStateNodes(ids: Set<StateNodeID>) {
            selectedNodesByID.subtract(ids)
        }
        
        func clearSelection() {
            selectedNodesByID = []
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case stateNodes
            case stateTransitions
            case selectedNodesByID
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            stateNodes = try container.decode([StateNode].self, forKey: .stateNodes)
            stateNodesByID = [:]
            for node in stateNodes {
                stateNodesByID[node.id] = node
            }

            stateTransitions = try container.decode([StateTransition].self, forKey: .stateTransitions)
            stateTransitionsByID = [:]
            for transition in stateTransitions {
                stateTransitionsByID[transition.id] = transition
            }
            
            selectedNodesByID = try container.decode(Set<StateNodeID>.self, forKey: .selectedNodesByID)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(stateNodes, forKey: .stateNodes)
            try container.encode(stateTransitions, forKey: .stateTransitions)
            try container.encode(selectedNodesByID, forKey: .selectedNodesByID)
        }
    }

}
