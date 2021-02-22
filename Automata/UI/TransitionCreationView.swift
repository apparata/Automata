//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

struct TransitionCreationView: View {
    
    var fromPoint: CGPoint
    
    var toPoint: CGPoint
            
    @State var isAnimating = false

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: fromPoint)
                path.addLine(to: toPoint)
            }
            .stroke(Color.pink, style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round))
            
            Path { path in
                path.move(to: fromPoint)
                path.addLine(to: toPoint)
            }
            .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round, dash: [12, 12], dashPhase: self.isAnimating ? 0 : 48))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                isAnimating = true
            }
        }
    }
}
