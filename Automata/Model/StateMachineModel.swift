//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import SwiftUI
import CollectionKit

class StateMachineModel: ObservableObject {
    
    @Published private(set) var stateNodes: OrderedSet<StateNode>
    
    @Published var stateTransitions: OrderedSet<StateTransition>

    init() {
        stateNodes = []
        stateTransitions = []
    }
    
    @discardableResult
    func addState(at position: CGPoint) -> StateNode {
        let node = StateNode(name: "New State", position: position)
        stateNodes.append(node)
        return node
    }

    func removeState(_ node: StateNode) {
        
        for transition in node.outgoingTransitions {
            stateTransitions.remove(transition)
        }
        
        for transition in node.incomingTransitions {
            stateTransitions.remove(transition)
        }
        
        stateNodes.remove(node)
    }
    
    @discardableResult
    func addTransition(from fromNode: StateNode, to toNode: StateNode) -> StateTransition {
        let transition = StateTransition(from: fromNode, to: toNode)
        stateTransitions.append(transition)
        return transition
    }
}
