//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import CGMath

struct TransitionCreationView: View {
    
    var fromPoint: CGPoint
    
    var toPoint: CGPoint
            
    @State var isAnimating = false
    
    var isLoop: Bool

    var body: some View {
        if isLoop {
            loopTransition
        } else {
            regularTransition
        }
    }

    private var loopTransition: some View {
        ZStack {
            Path { path in
                path.move(to: fromPoint)
                path.addCurve(to: fromPoint,
                              control1: fromPoint + CGPoint(x: -90, y: -90),
                              control2: fromPoint + CGPoint(x: 90, y: -90))
            }
            .stroke(Color.transientTransition, style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round))
            
            Path { path in
                path.move(to: fromPoint)
                path.addCurve(to: fromPoint,
                              control1: fromPoint + CGPoint(x: -90, y: -90),
                              control2: fromPoint + CGPoint(x: 90, y: -90))
            }
            .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round, dash: [12, 12], dashPhase: self.isAnimating ? 0 : 48))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                isAnimating = true
            }
        }
    }
    
    private var regularTransition: some View {
        ZStack {
            Path { path in
                path.move(to: fromPoint)
                path.addLine(to: toPoint)
            }
            .stroke(Color.transientTransition, style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round))
            
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
