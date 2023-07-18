//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

struct TransitionCreation: Equatable {
    
    let isActive: Bool
    let fromPoint: CGPoint
    let fromNodeID: StateNodeID?
    let toPoint: CGPoint
    let toNodeID: StateNodeID?
    let createStateIfNeeded: Bool
    let isLoopAllowed: Bool
    let isLoop: Bool
        
    init() {
        isActive = false
        fromPoint = .zero
        fromNodeID = nil
        toPoint = .zero
        toNodeID = nil
        createStateIfNeeded = false
        isLoopAllowed = false
        isLoop = false
    }
    
    init(
        fromPoint: CGPoint,
        fromNodeID: StateNodeID?,
        toPoint: CGPoint,
        toNodeID: StateNodeID?,
        createStateIfNeeded: Bool = false,
        isActive: Bool = true,
        isLoopAllowed: Bool = false,
        isLoop: Bool = false
    ) {
        self.isActive = isActive
        self.fromPoint = fromPoint
        self.fromNodeID = fromNodeID
        self.toPoint = toPoint
        self.toNodeID = toNodeID
        self.createStateIfNeeded = createStateIfNeeded
        self.isLoopAllowed = isLoopAllowed
        self.isLoop = isLoop
    }
}
