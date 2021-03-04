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
    
    @GestureState private var sourceOfTransitionCreation: StateNodeID?
    @GestureState private var transitionCreation = TransitionCreation()
    
    @State var targetForTransitionCreation: StateNode?
    
    @GestureState private var moveState = MoveState()
    
    @EnvironmentObject private var automat: Automat
            
    @StateObject private var mousePosition = MousePosition()
    
    @GestureState var isSelectingArea: Bool = false
    
    @State var selectionAreaFrame: CGRect = .zero
        
    var body: some View {
        
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                
                CanvasBackground()
                    .contextMenu {
                        Button(action: addState, label: {
                            Image(systemName: "plus")
                            Text("Add State")
                        })
                    }
                    .onTapGesture {
                        clearSelection()
                    }
                    .gesture(selectAreaGesture(.additive).modifiers([.shift]))
                    .gesture(selectAreaGesture(.subtractive).modifiers([.option]))
                    .gesture(selectAreaGesture(.exact))
                    .background(KeyEventView { key in
                        if key == .delete {
                            removeSelectedStates()
                        }
                    })
                
                MouseTracker(onMove: mouseMoved) {
                    EmptyView()
                }
                
                transitionViews()
                
                if transitionCreation.isActive {
                    TransitionCreationView(fromPoint: transitionCreation.fromPoint,
                                           toPoint: transitionCreation.toPoint)
                }

                stateViews()
                
                if isSelectingArea {
                    Rectangle()
                        .strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1)
                        .background(Color.yellow.opacity(0.1))
                        .position(selectionAreaFrame.center)
                        .frame(width: selectionAreaFrame.width, height: selectionAreaFrame.height)
                        .allowsHitTesting(false)
                }
                
            }.frame(width: 3000, height: 2400)
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
                      transitionCreation: transitionCreation,
                      isSourceOfTransitionCreation: sourceOfTransitionCreation == node.id,
                      targetForTransitionCreation: $targetForTransitionCreation)
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
                    Button(action: {
                        removeState(node)
                    }, label: {
                        Image(systemName: "trash")
                        Text("Remove")
                    })
                }
        }
    }
    
    // MARK: - Gesture Input
        
    private func transitionCreationGesture(createStateIfNeeded: Bool, node: StateNode) -> some Gesture {
        DragGesture()
            .updating($sourceOfTransitionCreation, body: { (value, gestureState, transaction) in
                gestureState = node.id
            })
            .updating($transitionCreation, body: { (value, gestureState, transaction) in
                let transitionCreation = TransitionCreation(fromPoint: node.position,
                                                            toPoint: value.location,
                                                            createStateIfNeeded: createStateIfNeeded)
                gestureState = transitionCreation
            })
            .onEnded { _ in
                createTransition(from: node)
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
            .updating($isSelectingArea) { (value, gestureState, transaction) in
                gestureState = true
            }
            .onChanged { value in
                let x = min(value.startLocation.x, value.location.x)
                let y = min(value.startLocation.y, value.location.y)
                let width = abs(value.startLocation.x - value.location.x)
                let height = abs(value.startLocation.y - value.location.y)
                selectionAreaFrame = CGRect(x: x, y: y, width: width, height: height)
            }
            .onEnded { value in
                let x = min(value.startLocation.x, value.location.x)
                let y = min(value.startLocation.y, value.location.y)
                let width = abs(value.startLocation.x - value.location.x)
                let height = abs(value.startLocation.y - value.location.y)
                selectionAreaFrame = CGRect(x: x, y: y, width: width, height: height)
                automat.selectStateNodes(in: selectionAreaFrame, mode: mode)
            }
    }
    
    // MARK: - Data Model
    
    private func addState() {
        withAnimation(Animation.stateNodeFade) {
            _ = automat.addState(at: mousePosition.point)
        }
    }
    
    private func removeState(_ node: StateNode) {
        if automat.isStateNodeSelected(id: node.id) {
            removeSelectedStates()
        } else {
            withAnimation(Animation.stateNodeFade) {
                automat.removeState(id: node.id)
            }
        }
    }

    private func removeSelectedStates() {
        withAnimation(Animation.stateNodeFade) {
            automat.forEachSelectedNode { stateNode in
                automat.removeState(id: stateNode.id)
            }
        }
    }
    
    private func createTransition(from node: StateNode) {
        if let toNode = targetForTransitionCreation {
            withAnimation(Animation.stateTransitionFade) {
                _ = automat.addTransition(from: node.id, to: toNode.id)
            }
        } else if transitionCreation.createStateIfNeeded {
            withAnimation(Animation.stateTransitionFade) {
                let toNode = automat.addState(at: transitionCreation.toPoint)
                automat.addTransition(from: node.id, to: toNode.id)
            }
        }
    }

}

fileprivate class MousePosition: ObservableObject {
    var point: CGPoint = .zero
}
