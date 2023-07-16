//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct DropCircle: View {
    
    let dropPoint: CGPoint?
    
    let dropProgress: Double
    
    init(at dropPoint: CGPoint?, progress: Double) {
        self.dropPoint = dropPoint
        self.dropProgress = progress
    }
        
    var body: some View {
        if let dropPoint = dropPoint {
            Circle()
                .frame(width: CGFloat(dropProgress * 200),
                       height: CGFloat(dropProgress * 200))
                .foregroundColor(.black)
                .position(dropPoint)
                .opacity(0.2 * (1 - dropProgress))
                .allowsHitTesting(false)
        }
    }
}
