//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

struct TransitionCreation: Equatable {
    
    let isActive: Bool
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let createStateIfNeeded: Bool
        
    init() {
        isActive = false
        fromPoint = .zero
        toPoint = .zero
        createStateIfNeeded = false
    }
    
    init(fromPoint: CGPoint, toPoint: CGPoint, createStateIfNeeded: Bool = false, isActive: Bool = true) {
        self.isActive = isActive
        self.fromPoint = fromPoint
        self.toPoint = toPoint
        self.createStateIfNeeded = createStateIfNeeded
    }
}
