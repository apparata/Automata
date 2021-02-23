//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import CGMath

private struct StateViewSizeKey: PreferenceKey {
    
    static var defaultValue: CGSize = CGSize(width: StateView.minWidth, height: StateView.minHeight)

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct StateView: View {
    
    private struct MoveState {
        var isDragging: Bool = false
        var dragOffset: CGPoint = .zero
    }
    
    fileprivate static let minWidth: CGFloat = 80
    fileprivate static let minHeight: CGFloat = 50
    
    @EnvironmentObject private var automat: Automat
    
    @ObservedObject var node: StateNode
    
    @Binding var transitionCreation: TransitionCreation
    @Binding var targetForTransitionCreation: StateNode?
    let onCreateTransition: (_ from: StateNode) -> Void
    @State private var isSourceOfTransitionCreation: Bool = false
    
    @GestureState private var moveState = MoveState()
    @State private var isHovering: Bool = false
    
    private var isSelected: Bool {
        automat.isStateNodeSelected(id: node.id)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Text(node.name)
                .font(Font.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
        }
        .frame(minWidth: StateView.minWidth, minHeight: StateView.minHeight)
        .onHover(perform: handleHover)
        .background(GeometryReader { geometry in
            background()
                .preference(key: StateViewSizeKey.self, value: geometry.size)
        })
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        .position(node.position)
        .gesture(transitionAndStateCreationGesture())
        .gesture(transitionCreationGesture())
        .gesture(moveGesture())
        .gesture(TapGesture().modifiers(.command).onEnded(toggleNodeSelection))
        .gesture(TapGesture().modifiers(.shift).onEnded(addNodeToSelection))
        .onTapGesture(perform: selectOnlyThisNode)
        .onPreferenceChange(StateViewSizeKey.self) { size in
            node.updateSize(size)
        }
    }

    // MARK: - Subviews
    
    private func background() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(isSelected ? Color.yellow : Color.black.opacity(0.2), lineWidth: 3)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .foregroundColor(evaluateNodeColor()))
    }
    
    private func evaluateNodeColor() -> Color {
        if transitionCreation.isActive, isHovering {
            return Color.pink
        } else if transitionCreation.isActive, isSourceOfTransitionCreation {
            return Color.pink
        } else {
            return Color(.systemBlue)
        }
    }
    
    // MARK: - Gesture Input
    
    private func handleHover(isHovering: Bool) {
        self.isHovering = isHovering
        if isHovering, transitionCreation.isActive {
            targetForTransitionCreation = node
        } else if !isHovering, targetForTransitionCreation == node {
            targetForTransitionCreation = nil
        }
    }
    
    private func transitionCreationGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isSourceOfTransitionCreation {
                    isSourceOfTransitionCreation = true
                }
                transitionCreation = TransitionCreation(fromPoint: node.position, toPoint: value.location)
            }
            .onEnded { _ in
                onCreateTransition(node)
                transitionCreation = TransitionCreation()
                isSourceOfTransitionCreation = false
            }
            .modifiers(.command)
    }
    
    private func transitionAndStateCreationGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isSourceOfTransitionCreation {
                    isSourceOfTransitionCreation = true
                }
                transitionCreation = TransitionCreation(fromPoint: node.position, toPoint: value.location, createStateIfNeeded: true)
            }
            .onEnded { _ in
                onCreateTransition(node)
                transitionCreation = TransitionCreation()
                isSourceOfTransitionCreation = false
            }
            .modifiers([.command, .shift])
    }
    
        
    private func moveGesture() -> some Gesture {
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
                
                if isSelected {
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
                
                if isSelected {
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
    
    private func selectOnlyThisNode() {
        guard !isSelected else {
            return
        }
        withAnimation(Animation.stateNodeFade) {
            automat.selectStateNodes(ids: [node.id])
        }
    }

    private func addNodeToSelection() {
        guard !isSelected else {
            return
        }
        withAnimation(Animation.stateNodeFade) {
            automat.addStateNodesToSelection(ids: [node.id])
        }
    }

    private func toggleNodeSelection() {
        if isSelected {
            withAnimation(Animation.stateNodeFade) {
                automat.deselectStateNode(ids: [node.id])
            }
        } else {
            withAnimation(Animation.stateNodeFade) {
                automat.addStateNodesToSelection(ids: [node.id])
            }
        }
    }

}
