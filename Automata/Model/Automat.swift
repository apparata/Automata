//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import CollectionKit
import SwiftUI
import CGMath
import UniformTypeIdentifiers

// MARK: - Automat

class Automat: ObservableObject, Codable {

    enum SelectionMode {
        case exact
        case additive
        case subtractive
    }

    static let pasteboardType = UTType(exportedAs: "se.apparata.tools.Automata.states")
    
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
    
    var onSelectionChange: ((_ selectedNodesByID: Set<StateNodeID>) -> Void)?

    private var undoManager: UndoManager?

    private var data: DataModel
    
    init() {
        data = DataModel()
        data.onSelectionChange = { [weak self] selection in
            self?.onSelectionChange?(selection)
        }
    }
    
    // MARK: - Snapshotting
    
    init(_ automat: Automat) {
        data = DataModel(automat.data)
        data.onSelectionChange = { [weak self] selection in
            self?.onSelectionChange?(selection)
        }
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

        logger.debug("✨ Add state \(stateID) at (\(position.x), \(position.y))")

        objectWillChange.send()

        let node = StateNode(id: stateID, name: "New State", position: position)
        data.addStateNode(node)

        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo ✨ add state \(stateID)")
            withAnimation(Animation.stateNodeFade) {
                automat.removeState(id: stateID)
            }
        }
        
        return node
    }

    func addState(_ state: StateNode) {
                        
        logger.debug("✨ Add state \(state.id) at (\(state.position.x), \(state.position.y))")

        objectWillChange.send()

        data.addStateNode(state)

        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo ✨ add state \(state.id)")
            withAnimation(Animation.stateNodeFade) {
                automat.removeState(id: state.id)
            }
        }
    }
    
    // MARK: - Remove State
    
    func removeState(id: StateNodeID) {
        
        logger.debug("🗑 Remove state \(id)")

        guard let node = state(by: id) else {
            logger.error("⚠️ WARNING: Could not find node to remove: \(id)")
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
            logger.debug("↩️ Undo 🗑 remove state \(id) at (\(position.x), \(position.y))")
            _ = withAnimation(Animation.stateNodeFade) {
                automat.addState(at: position, id: id)
            }
        }
        
        data.removeStateNode(id: id)
        
        if isInitialStateNode(id: id) {
            setInitialState(id: nil)
        }
    }
    
    func removeSelectedStates() {
        withAnimation(Animation.stateNodeFade) {
            forEachSelectedNode { stateNode in
                removeState(id: stateNode.id)
            }
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
        
        let toX = String(Int(toPoint.x))
        let toY = String(Int(toPoint.y))
        logger.debug("🚀 Move state \(id, privacy: .public) to (\(toX, privacy: .public), \(toY, privacy: .public))")
        
        guard let node = state(by: id) else {
            logger.error("⚠️ WARNING: Could not find node to move: \(id)")
            return
        }
        
        objectWillChange.send()

        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo 🚀 move state \(id, privacy: .public) to (\(fromPoint.x), \(fromPoint.y))")
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
    
    // MARK: Set Initial State
    
    func setInitialState(id: StateNodeID?) {
        
        logger.debug("🟢 Set initial state to \(id?.uuidString ?? "<none>", privacy: .public)")
        
        objectWillChange.send()

        let initialState = data.initialState
        
        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo 🟢 set initial state to \(id?.uuidString ?? "<none>", privacy: .public)")
            automat.setInitialState(id: initialState)
        }
        
        data.setInitialState(id: id)
    }
        
    // MARK: Add Transition
    
    @discardableResult
    func addTransition(from fromNodeID: StateNodeID, to toNodeID: StateNodeID, id: StateTransitionID? = nil) -> StateTransition {
        let transitionID = id ?? UUID()
        
        logger.debug("✨ Add transition \(transitionID)")
        
        guard let fromNode = state(by: fromNodeID) else {
            logger.error("⚠️ WARNING: Could not find 'from' node to add transition to: \(fromNodeID, privacy: .public)")
            fatalError()
        }

        guard let toNode = state(by: toNodeID) else {
            logger.error("⚠️ WARNING: Could not find 'to' node to add transition to: \(toNodeID, privacy: .public)")
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
            logger.debug("↩️ Undo ✨ add transition \(transitionID, privacy: .public)")
            withAnimation(Animation.stateTransitionFade) {
                automat.removeTransition(id: transitionID)
            }
        }
        
        return transition
    }

    func addTransition(_ transition: StateTransition) {
        
        logger.debug("✨ Add transition \(transition.id)")
        
        guard let fromNode = state(by: transition.fromNode) else {
            logger.error("⚠️ WARNING: Could not find 'from' node to add transition to: \(transition.fromNode, privacy: .public)")
            fatalError()
        }

        guard let toNode = state(by: transition.toNode) else {
            logger.error("⚠️ WARNING: Could not find 'to' node to add transition to: \(transition.toNode, privacy: .public)")
            fatalError()
        }
                
        objectWillChange.send()

        fromNode.addOutgoingTransition(transition.id)
        toNode.addIncomingTransition(transition.id)
        
        data.addStateTransition(transition)
        
        undoManager?.registerUndo(withTarget: self) { automat in
            logger.error("↩️ Undo ✨ add transition \(transition.id, privacy: .public)")
            withAnimation(Animation.stateTransitionFade) {
                automat.removeTransition(id: transition.id)
            }
        }
    }
    
    func createTransition(using parameters: TransitionCreation) {
        guard let fromNodeID = parameters.fromNodeID else {
            return
        }
        if parameters.isLoop, !parameters.isLoopAllowed {
            return
        }
        if let toNodeID = parameters.toNodeID {
            withAnimation(Animation.stateTransitionFade) {
                _ = addTransition(from: fromNodeID, to: toNodeID)
            }
        } else if parameters.createStateIfNeeded {
            withAnimation(Animation.stateTransitionFade) {
                let toNode = addState(at: parameters.toPoint)
                addTransition(from: fromNodeID, to: toNode.id)
            }
        }
    }

    // MARK: - Remove Transition
    
    func removeTransition(id: StateTransitionID) {
        
        logger.debug("🗑 Remove transition \(id)")

        guard let transition = transition(by: id) else {
            logger.error("⚠️ WARNING: Could not find transition to remove: \(id, privacy: .public)")
            return
        }
        
        objectWillChange.send()
        
        let fromID = transition.fromNode
        let toID = transition.toNode
        
        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo 🗑 remove transition \(id, privacy: .public)")
            _ = withAnimation(Animation.stateTransitionFade) {
                automat.addTransition(from: fromID, to: toID, id: id)
            }
        }
        
        guard let fromNode = state(by: fromID) else {
            logger.error("⚠️ WARNING: Could not find 'from' node to remove transition from: \(fromID, privacy: .public)")
            fatalError()
        }

        guard let toNode = state(by: toID) else {
            logger.error("⚠️ WARNING: Could not find 'to' node to remove transition from: \(toID, privacy: .public)")
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
            logger.debug("↩️ Undo ✨ add event \(transition.id, privacy: .public)")
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
                logger.debug("↩️ Undo ✨ remove event \(transition.id, privacy: .public)")
                withAnimation(Animation.stateTransitionFade) {
                    automat.addEvent(id: event.id, to: transition, outgoing: event.outgoing)
                }
            }
        } else {
            removeTransition(id: transition.id)
        }
    }
    
    // MARK: - State at Point
    
    func stateAtPoint(_ point: CGPoint) -> StateNode? {
        for stateNode in stateNodes {
            if stateNode.frame.contains(point) {
                return stateNode
            }
        }
        return nil
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
        logger.debug("👈 Select state nodes \(idsString, privacy: .public)")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo 👈 select state nodes \(idsString, privacy: .public)")
            withAnimation(Animation.stateTransitionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.selectStateNodes(ids: ids)
    }
    
    func addStateNodesToSelection(ids: Set<StateNodeID>) {
        
        let idsString = ids.map(\.uuidString).joined(separator: ", ")
        logger.debug("👈 Add state nodes to selection \(idsString, privacy: .public)")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo 👈 add state nodes to selection \(idsString, privacy: .public)")
            withAnimation(Animation.stateTransitionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.addStateNodesToSelection(ids: ids)
    }
    
    func deselectStateNode(ids: Set<StateNodeID>) {
        
        let idsString = ids.map(\.uuidString).joined(separator: ", ")
        logger.debug("✋ Remove state nodes from selection \(idsString, privacy: .public)")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo ✋ remove state nodes from selection \(idsString, privacy: .public)")
            withAnimation(Animation.stateTransitionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.deselectStateNodes(ids: ids)
    }

    func clearSelection() {
        
        logger.debug("👋 Clear selection")
        
        objectWillChange.send()

        let currentSelection = data.selectedNodesByID

        undoManager?.registerUndo(withTarget: self) { automat in
            logger.debug("↩️ Undo 👋 clear selection")
            withAnimation(Animation.selectionFade) {
                automat.selectStateNodes(ids: currentSelection)
            }
        }
        
        data.clearSelection()
    }
    
    func cutPasteboardData() -> PasteboardData {
        let pasteData = copyPasteboardData()
        for stateID in data.selectedNodesByID {
            removeState(id: stateID)
        }
        return pasteData
    }
    
    func copyPasteboardData() -> PasteboardData {
        let pasteData = DataModel()
        
        var idMap: [StateNodeID: StateNodeID] = [:]
        for stateNodeID in data.selectedNodesByID {
            guard let stateNode = state(by: stateNodeID) else {
                continue
            }
            let newID = StateNodeID()
            idMap[stateNode.id] = newID
            let copiedState = StateNode(id: newID, state: stateNode)
            pasteData.addStateNode(copiedState)
        }
        
        for transition in stateTransitions {
            if data.isStateNodeSelected(id: transition.fromNode),
               data.isStateNodeSelected(id: transition.toNode),
               let fromNodeID = idMap[transition.fromNode],
               let toNodeID = idMap[transition.toNode] {
                let events = transition.events.map {
                    StateTransition.Event(id: TransitionEventID(), event: $0)
                }
                let copiedTransition = StateTransition(id: StateTransitionID(),
                                                       from: fromNodeID,
                                                       to: toNodeID,
                                                       dueTo: events)
                pasteData.addStateTransition(copiedTransition)
            }
        }
        
        return PasteboardData(data: pasteData)
    }

    func addPasteboardData(_ data: DataModel, at position: CGPoint) {
        let averagePosition = CGPoint.average(data.stateNodes.map(\.position))
        for state in data.stateNodes {
            let newPosition = state.position - averagePosition + position
            state.updatePosition(newPosition)
            addState(state)
        }
        for transition in data.stateTransitions {
            addTransition(transition)
        }
    }

    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode(DataModel.self, forKey: .data)
        data.onSelectionChange = { [weak self] selection in
            self?.onSelectionChange?(selection)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
    }
}

extension Automat {

    // MARK: - Internal Data Model
    
    /// Provides fast lookups, additions, but slow removals.
    class DataModel: Codable {
        
        var onSelectionChange: ((_ selectedNodesByID: Set<StateNodeID>) -> Void)?
        
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
            onSelectionChange?(selectedNodesByID)
        }
        
        func addStateNodesToSelection(ids: Set<StateNodeID>) {
            selectedNodesByID.formUnion(ids)
            onSelectionChange?(selectedNodesByID)
        }
        
        func deselectStateNodes(ids: Set<StateNodeID>) {
            selectedNodesByID.subtract(ids)
            onSelectionChange?(selectedNodesByID)
        }
        
        func clearSelection() {
            selectedNodesByID = []
            onSelectionChange?(selectedNodesByID)
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
