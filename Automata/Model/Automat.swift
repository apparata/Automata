//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import CollectionKit
import SwiftUI
import CGMath

// MARK: - Automat

class Automat: ObservableObject, Codable {

    enum SelectionMode {
        case exact
        case additive
        case subtractive
    }
    
    var stateNodes: [StateNode] {
        data.stateNodes
    }
    
    var stateTransitions: [StateTransition] {
        data.stateTransitions
    }
    
    var initialState: StateNode? {
        data.initialState.flatMap {
            state(by: $0)
        }
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

        let node = StateNode(id: stateID, name: "New State", position: position)
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
        
        if isInitialStateNode(id: id) {
            setInitialState(id: nil)
        }
    }

    // MARK: - Move States

    func moveStates(ids: [StateNodeID], distance: CGPoint) {
        for id in ids {
            if let node = state(by: id) {
                moveState(id: id, from: node.position, to: node.position + distance)
            }
        }
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
    
    // MARK: Set Initial Event
    
    func setInitialState(id: StateNodeID?) {
        
        log(debug: "🟢 Set initial state to \(id?.uuidString ?? "<none>")")
        
        objectWillChange.send()

        let initialState = data.initialState
        
        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo 🟢 set initial state to \(id?.uuidString ?? "<none>")")
            automat.setInitialState(id: initialState)
        }
        
        data.setInitialState(id: id)
    }
        
    // MARK: Add Transition
    
    @discardableResult
    func addTransition(from fromNodeID: StateNodeID, to toNodeID: StateNodeID, id: StateTransitionID? = nil) -> StateTransition {
        let transitionID = id ?? UUID()
        
        log(debug: "✨ Add transition \(transitionID)")
        
        guard let fromNode = state(by: fromNodeID) else {
            log(error: "⚠️ WARNING: Could not find 'from' node to add transition to: \(fromNodeID)")
            fatalError()
        }

        guard let toNode = state(by: toNodeID) else {
            log(error: "⚠️ WARNING: Could not find 'to' node to add transition to: \(toNodeID)")
            fatalError()
        }
        
        // Let's check if there already is a transition between these states.
        for id in fromNode.outgoingTransitions {
            if let transition = transition(by: id), transition.toNode == toNodeID {
                addEvent(to: transition, outgoing: true)
                return transition
            }
        }
        for id in fromNode.incomingTransitions {
            if let transition = transition(by: id), transition.fromNode == toNodeID {
                addEvent(to: transition, outgoing: false)
                return transition
            }
        }
        
        objectWillChange.send()

        let transition = StateTransition(id: transitionID, from: fromNodeID, to: toNodeID)

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
    
    // MARK: - Add Transition Event
    
    func addEvent(id: TransitionEventID = UUID(), to transition: StateTransition, outgoing: Bool) {
        
        objectWillChange.send()
        
        let event = StateTransition.Event(id: id, name: "New Event", outgoing: outgoing)
        
        transition.events.append(event)

        undoManager?.registerUndo(withTarget: self) { automat in
            log(debug: "↩️ Undo ✨ add event \(transition.id)")
            withAnimation(Animation.stateTransitionFade) {
                automat.removeEvent(event, from: transition.id)
            }
        }
    }
    
    func removeEvent(_ event: StateTransition.Event, from transitionID: StateTransitionID) {
        
        guard let transition = transition(by: transitionID) else {
            return
        }

        if transition.events.count > 1 {
            objectWillChange.send()
            transition.events.removeFirst(where: { $0.id == event.id })
            undoManager?.registerUndo(withTarget: self) { automat in
                log(debug: "↩️ Undo ✨ remove event \(transition.id)")
                withAnimation(Animation.stateTransitionFade) {
                    automat.addEvent(id: event.id, to: transition, outgoing: event.outgoing)
                }
            }
        } else {
            removeTransition(id: transition.id)
        }
    }
    
    // MARK: - Selection
    
    func forEachSelectedNode(_ action: (StateNode) -> Void) {
        for selectedNodeID in data.selectedNodesByID {
            if let node = state(by: selectedNodeID) {
                action(node)
            }
        }
    }
    
    func isStateNodeSelected(id: StateNodeID) -> Bool {
        return data.isStateNodeSelected(id: id)
    }

    func isInitialStateNode(id: StateNodeID) -> Bool {
        return data.initialState == id
    }

    func selectStateNodes(in area: CGRect, mode: SelectionMode = .exact) {
        let ids = Set(stateNodes.filter { area.intersects($0.frame) }.map(\.id))
        switch mode {
        case .exact:
            selectStateNodes(ids: ids)
        case .additive:
            addStateNodesToSelection(ids: ids)
        case .subtractive:
            deselectStateNode(ids: ids)
        }
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
        
        private(set) var initialState: StateNodeID?
        
        init() {
            stateNodes = []
            stateNodesByID = [:]
            stateTransitions = []
            stateTransitionsByID = [:]
            selectedNodesByID = []
            initialState = nil
        }
        
        init(_ data: DataModel) {
            stateNodes = data.stateNodes
            stateNodesByID = data.stateNodesByID
            stateTransitions = data.stateTransitions
            stateTransitionsByID = data.stateTransitionsByID
            selectedNodesByID = data.selectedNodesByID
            initialState = data.initialState
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
        
        func setInitialState(id: StateNodeID?) {
            initialState = id
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
            case initialState
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
            
            initialState = try container.decodeIfPresent(StateNodeID.self, forKey: .initialState)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(stateNodes, forKey: .stateNodes)
            try container.encode(stateTransitions, forKey: .stateTransitions)
            try container.encode(selectedNodesByID, forKey: .selectedNodesByID)
            try container.encodeIfPresent(initialState, forKey: .initialState)
        }
    }

}
