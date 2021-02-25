//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import CGMath

struct TransitionView: View {
    
    @EnvironmentObject private var automat: Automat
    
    @ObservedObject var transition: StateTransition
            
    @State var isAnimating = false

    var body: some View {
        ZStack {
            Path { path in
                path.move(to: position(of: transition.fromNode))
                path.addLine(to: position(of: transition.toNode))
            }
            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round))
            
            Path { path in
                path.move(to: position(of: transition.fromNode))
                path.addLine(to: position(of: transition.toNode))
            }
            .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round, dash: [12, 12], dashPhase: self.isAnimating ? 0 : 48))
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
            .onAppear {
                isAnimating = true
            }
            
            TransitionEventLabel(fromPoint: automat.state(by: transition.fromNode)?.position ?? .zero,
                                 toPoint: automat.state(by: transition.toNode)?.position ?? .zero)
        }
    }
    
    private func position(of stateNodeID: StateNodeID) -> CGPoint {
        // MARK: This is not efficient.
        automat.state(by: stateNodeID)?.position ?? .zero
    }
}

struct TransitionEventLabel: View {
    
    private let fromPoint: CGPoint
    private let toPoint: CGPoint
    
    init(fromPoint: CGPoint, toPoint: CGPoint) {
        self.fromPoint = fromPoint
        self.toPoint = toPoint
    }
            
    var body: some View {
        HStack(spacing: 4) {
            if !isFromStateLeftOfToState {
                Image(systemName: "arrowtriangle.backward.fill")
            }
            Text("Transition")
            if isFromStateLeftOfToState {
                Image(systemName: "arrowtriangle.forward.fill")
            }
        }
        .font(Font.system(size: 14, weight: .medium, design: .default))
        .foregroundColor(.white)
        .offset(x: 0, y: -16)
        .rotationEffect(labelAngle)
        .position(CGPoint.average(fromPoint, toPoint))
    }
    
    private var labelAngle: Angle {
        var angle = lineAngle
        
        if (CGFloat.pi / 2)..<CGFloat.pi ~= angle {
            angle += CGFloat.pi
        }
                
        return Angle(radians: Double(angle))
    }
        
    private var lineAngle: CGFloat {
        let from = fromPoint
        let to = toPoint

        let a: CGPoint
        if from.y <= to.y {
            a = CGPoint(x: to.x - from.x, y: to.y - from.y)
        } else {
            a = CGPoint(x: from.x - to.x, y: from.y - to.y)
        }
                
        let cosine = a.x / sqrt(a.x * a.x + a.y * a.y)
        
        let angle = acos(cosine)
        
        return angle
    }
    
    private var isFromStateLeftOfToState: Bool {
        return fromPoint.x <= toPoint.x
    }
}
