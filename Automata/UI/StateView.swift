//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

struct StateView: View {
    
    @Environment(\.undoManager) var undoManager
    
    @ObservedObject var node: StateNode
    
    @Binding var transitionCreation: TransitionCreation
    @Binding var targetForTransitionCreation: StateNode?
    let onCreateTransition: (_ from: StateNode) -> Void
    @State private var isSourceOfTransitionCreation: Bool = false
    
    @State private var isDragging: Bool = false
    @State private var dragOffset: CGPoint = .zero
    @State private var isHovering: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Text(node.name)
                .font(Font.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
        }
        .frame(minWidth: 80, minHeight: 50)
        .onHover(perform: handleHover)
        .background(background())
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        .position(node.position)
        .gesture(transitionAndStateCreationGesture())
        .gesture(transitionCreationGesture())
        .gesture(moveGesture())
    }

    // MARK: - Subviews
    
    private func background() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
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
            .onChanged { value in
                if !isDragging {
                    dragOffset = CGPoint(x: value.startLocation.x - node.position.x, y: value.startLocation.y - node.position.y)
                }
                isDragging = true
                node.updatePosition(CGPoint(x: value.location.x - dragOffset.x, y: value.location.y - dragOffset.y))
                
                for transitionID in node.outgoingTransitions {
                    if let transition = node.automat?.transition(by: transitionID) {
                        transition.objectWillChange.send()
                    }
                }

                for transitionID in node.incomingTransitions {
                    if let transition = node.automat?.transition(by: transitionID) {
                        transition.objectWillChange.send()
                    }
                }
            }
            .onEnded { value in
                isDragging = false
                let position = CGPoint(x: value.location.x - dragOffset.x, y: value.location.y - dragOffset.y)
                node.automat?.undoManager = undoManager
                dump(node.automat?.state(by: node.id) === node)
                node.automat?.moveState(id: node.id, from: value.startLocation, to: position)
            }
    }

}
