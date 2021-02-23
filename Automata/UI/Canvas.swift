//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox

struct Canvas: View {
    
    @Environment(\.undoManager) var undoManager
    
    @ObservedObject var automat: Automat
            
    @State var transitionCreation = TransitionCreation()
    
    @State var targetForTransitionCreation: StateNode?
    
    @StateObject private var mousePosition = MousePosition()
    
    var body: some View {
        
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            ZStack {
                                
                CanvasBackground()
                    .contextMenu {
                        Button(action: addState, label: {
                            Label("Add State", systemImage: "plus")
                        })
                    }
                
                MouseTracker(onMove: mouseMoved) {
                    EmptyView()
                }
                
                transitionViews()
                
                if transitionCreation.isActive {
                    TransitionCreationView(fromPoint: transitionCreation.fromPoint,
                                           toPoint: transitionCreation.toPoint)
                }

                stateViews()
                
            }.frame(width: 2000, height: 2000)
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
                      transitionCreation: $transitionCreation,
                      targetForTransitionCreation: $targetForTransitionCreation,
                      onCreateTransition: createTransition)
                .transition(.opacity)
                .contextMenu {
                    Button(action: {
                        removeState(node)
                    }, label: {
                        Label("Remove", systemImage: "trash")
                    })
                }
        }
    }
    
    private func mouseMoved(to point: CGPoint) {
        mousePosition.point = point
    }
    
    private func addState() {
        withAnimation(Animation.stateNodeFade) {
            automat.undoManager = undoManager
            _ = automat.addState(at: mousePosition.point)
        }
    }
    
    private func removeState(_ node: StateNode) {
        withAnimation(Animation.stateNodeFade) {
            automat.undoManager = undoManager
            automat.removeState(id: node.id)
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
