//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox
import CGMath

struct Canvas: View {
    
    private struct MoveState {
        var isDragging: Bool = false
        var dragOffset: CGPoint = .zero
    }
    
    private struct SelectionAreaState {
        var isSelecting: Bool = false
        var frame: CGRect = .zero
    }
    
    private struct DropState {
        var point: CGPoint? = nil
        var progress: Double = 0
    }
        
    @StateObject private var mousePosition = MousePosition()
    
    @GestureState private var transitionCreation = TransitionCreation()
    
    @GestureState private var moveState = MoveState()
                    
    @GestureState private var selectionAreaState = SelectionAreaState()
    
    @State private var dropState = DropState()
    
    @EnvironmentObject private var automat: Automat
    
    var body: some View {
        
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                
                CanvasBackground()
                    .contextMenu {
                        Button {
                            addState()
                        } label: {
                            Image(systemName: "plus")
                            Text("Add State")
                        }
                    }
                    .onTapGesture {
                        clearSelection()
                    }
                    .gesture(selectAreaGesture(.additive).modifiers([.shift]))
                    .gesture(selectAreaGesture(.subtractive).modifiers([.option]))
                    .gesture(selectAreaGesture(.exact))
                    .simultaneousGesture(TapGesture(count: 2).onEnded { value in
                        addState()
                    })
                    .background(KeyEventView { key in
                        if key == .delete {
                            automat.removeSelectedStates()
                        }
                    })

                MouseTracker(onMove: mouseMoved) {
                    EmptyView()
                }
                
                DropCircle(at: dropState.point, progress: dropState.progress)
                
                transitionViews()
                
                if transitionCreation.isActive {
                    TransitionCreationView(fromPoint: transitionCreation.fromPoint,
                                           toPoint: transitionCreation.toPoint,
                                           isLoop: transitionCreation.isLoop)
                }

                stateViews()
                
                if selectionAreaState.isSelecting {
                    SelectionArea(frame: selectionAreaState.frame)
                }
                
            }.frame(width: 3000, height: 2400)
        }
        .onCutCommand { () -> [NSItemProvider] in
            logger.debug("Cut!")
            return [NSItemProvider(object: automat.cutPasteboardData())]
        }
        .onCopyCommand { () -> [NSItemProvider] in
            logger.debug("Copy!")
            return [NSItemProvider(object: automat.copyPasteboardData())]
        }
        .onPasteCommand(of: ["se.apparata.tools.Automata.states"]) { items in
            logger.debug("Paste!")
            for item in items {
                item.loadItem(forTypeIdentifier: "se.apparata.tools.Automata.states", options: nil) { item, error in
                    guard let pasteData = item as? Data else {
                        return
                    }
                    
                    do {
                        let data = try JSONDecoder().decode(Automat.DataModel.self, from: pasteData)
                        DispatchQueue.main.async {
                            automat.addPasteboardData(data, at: mousePosition.point)
                        }
                    } catch {
                        dump(error)
                    }
                }
            }
        }
    }
        
    private func transitionViews() -> some View {
        ForEach(automat.stateTransitions) { transition in
            TransitionView(transition: transition)
                .transition(.opacity)
        }
    }
        
    private func stateViews() -> some View {
        ForEach(automat.stateNodes) { node in
            StateView(node: node,
                      transitionCreation: transitionCreation)
                .gesture(transitionCreationGesture(createStateIfNeeded: true, node: node))
                .gesture(transitionCreationGesture(createStateIfNeeded: false, node: node))
                .gesture(moveGesture(for: node))
                .gesture(TapGesture().modifiers(.command).onEnded { toggleNodeSelection(node) })
                .gesture(TapGesture().modifiers(.shift).onEnded { addNodeToSelection(node) })
                .gesture(TapGesture().onEnded { selectOnlyThisNode(node) })
                .simultaneousGesture(TapGesture(count: 2).onEnded { _ in
                    NodeTextField.notifyTextFieldIsNowEditing(nodeID: node.id)
                    withAnimation(Animation.selectionFade) {
                        automat.selectStateNodes(ids: [node.id])
                    }
                })
                .transition(.opacity)
                .contextMenu {
                    Button {
                        // TODO: Rename state
                    } label: {
                        Image(systemName: "character.cursor.ibeam")
                        Text("Rename")
                    }
                    Button {
                        removeState(node)
                    } label: {
                        Image(systemName: "trash")
                        Text("Remove")
                    }
                    Button {
                        setInitialState(node)
                    } label: {
                        Image(systemName: "1.square.fill")
                        Text("Set Initial State")
                    }
                }
        }
    }
    
    // MARK: - Gesture Input
        
    private func transitionCreationGesture(createStateIfNeeded: Bool, node: StateNode) -> some Gesture {
        DragGesture()
            .updating($transitionCreation, body: { (value, gestureState, transaction) in
                let targetNode = automat.stateAtPoint(value.location)
                let isLoop = node.id == targetNode?.id
                let transitionCreation = TransitionCreation(fromPoint: node.position,
                                                            fromNodeID: node.id,
                                                            toPoint: value.location,
                                                            toNodeID: targetNode?.id,
                                                            createStateIfNeeded: createStateIfNeeded,
                                                            isLoop: isLoop)
                gestureState = transitionCreation
            })
            .onEnded { value in
                let targetNode = automat.stateAtPoint(value.location)
                let isLoop = node.id == targetNode?.id
                let transitionCreation = TransitionCreation(fromPoint: node.position,
                                                            fromNodeID: node.id,
                                                            toPoint: value.location,
                                                            toNodeID: targetNode?.id,
                                                            createStateIfNeeded: createStateIfNeeded,
                                                            isLoop: isLoop)
                automat.createTransition(using: transitionCreation)
            }
            .modifiers(createStateIfNeeded ? [.command, .shift] : [.command])
    }
        
    private func moveGesture(for node: StateNode) -> some Gesture {
        DragGesture()
            .updating($moveState, body: { (value, gestureState, transaction) in
                let dragOffset: CGPoint
                if !gestureState.isDragging {
                    dragOffset = value.startLocation - node.position
                } else {
                    dragOffset = gestureState.dragOffset
                }
                gestureState = MoveState(isDragging: true, dragOffset: dragOffset)
            })
            .onChanged { value in
                                
                func notifyTransitionsOfChange(node: StateNode) {
                    for transitionID in node.outgoingTransitions {
                        if let transition = automat.transition(by: transitionID) {
                            transition.objectWillChange.send()
                        }
                    }

                    for transitionID in node.incomingTransitions {
                        if let transition = automat.transition(by: transitionID) {
                            transition.objectWillChange.send()
                        }
                    }
                }
                                                                                
                let toPoint = value.location - moveState.dragOffset
                let relativeDistance = toPoint - node.position
                
                if automat.isStateNodeSelected(id: node.id) {
                    automat.forEachSelectedNode { selectedNode in
                        selectedNode.updatePosition(selectedNode.position + relativeDistance)
                        notifyTransitionsOfChange(node: selectedNode)
                    }
                } else {
                    node.updatePosition(toPoint)
                    notifyTransitionsOfChange(node: node)
                    automat.selectStateNodes(ids: [node.id])
                }
                
            }
            .onEnded { value in
                let distance = value.location - moveState.dragOffset - value.startLocation
                
                if automat.isStateNodeSelected(id: node.id) {
                    automat.forEachSelectedNode { selectedNode in
                        let fromPoint = selectedNode.position - distance
                        let toPoint = selectedNode.position
                        automat.moveState(id: selectedNode.id, from: fromPoint, to: toPoint)
                    }
                } else {
                    let fromPoint = node.position - distance
                    let toPoint = node.position
                    automat.moveState(id: node.id, from: fromPoint, to: toPoint)
                }
                
            }
    }
    
    // MARK: - Selection
    
    private func clearSelection() {
        withAnimation(Animation.stateTransitionFade) {
            automat.clearSelection()
        }
        KeyEventView.resumeListeningToKeyDown()
    }
    
    private func selectOnlyThisNode(_ node: StateNode) {
        guard !automat.isStateNodeSelected(id: node.id) else {
            return
        }
        withAnimation(Animation.stateNodeFade) {
            automat.selectStateNodes(ids: [node.id])
        }
        KeyEventView.resumeListeningToKeyDown()
    }

    private func addNodeToSelection(_ node: StateNode) {
        guard !automat.isStateNodeSelected(id: node.id) else {
            return
        }
        withAnimation(Animation.stateNodeFade) {
            automat.addStateNodesToSelection(ids: [node.id])
        }
        KeyEventView.resumeListeningToKeyDown()
    }

    private func toggleNodeSelection(_ node: StateNode) {
        if automat.isStateNodeSelected(id: node.id) {
            withAnimation(Animation.stateNodeFade) {
                automat.deselectStateNode(ids: [node.id])
            }
        } else {
            withAnimation(Animation.stateNodeFade) {
                automat.addStateNodesToSelection(ids: [node.id])
            }
        }
        KeyEventView.resumeListeningToKeyDown()
    }
    
    private func mouseMoved(to point: CGPoint) {
        mousePosition.point = point
    }
        
    // MARK: Area Selection
    
    private func selectAreaGesture(_ mode: Automat.SelectionMode = .exact) -> some Gesture {
        DragGesture()
            .updating($selectionAreaState) { (value, gestureState, transaction) in
                gestureState = SelectionAreaState(
                    isSelecting: true,
                    frame: absoluteFrame(from: value.startLocation, to: value.location))
            }
            .onEnded { value in
                let frame = absoluteFrame(from: value.startLocation, to: value.location)
                automat.selectStateNodes(in: frame, mode: mode)
            }
    }
    
    private func absoluteFrame(from: CGPoint, to: CGPoint) -> CGRect {
        let x = min(from.x, to.x)
        let y = min(from.y, to.y)
        let width = abs(from.x - to.x)
        let height = abs(from.y - to.y)
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // MARK: - Data Model
    
    private func setInitialState(_ node: StateNode) {
        withAnimation(Animation.stateNodeFade) {
            automat.setInitialState(id: node.id)
        }
    }
    
    private func addState() {
        let point = mousePosition.point
        
        withAnimation(Animation.stateNodeFade) {
            _ = automat.addState(at: point)
        }
        
        dropState = DropState(point: point, progress: 0)
        withAnimation(Animation.easeOut(duration: 0.4)) {
            dropState = DropState(point: point, progress: 1)
        }
    }
    
    private func removeState(_ node: StateNode) {
        if automat.isStateNodeSelected(id: node.id) {
            automat.removeSelectedStates()
        } else {
            withAnimation(Animation.stateNodeFade) {
                automat.removeState(id: node.id)
            }
        }
    }
}

fileprivate class MousePosition: ObservableObject {
    var point: CGPoint = .zero
}
