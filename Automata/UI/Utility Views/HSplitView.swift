//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Cocoa
import SwiftUI

public struct HSplitView<Primary: View, Secondary: View>: View {

    public enum VisibleState {
        case primary
        case secondary
        case both
    }
    
    public typealias SubviewsBuilder = () -> TupleView<(Primary, Secondary)>

    private let subviews: TupleView<(Primary, Secondary)>

    @GestureState private var gestureOffset: CGFloat = 0
    @State private var currentDividerOffset: CGFloat = 0
    
    private var visibleState: VisibleState
    
    private var dividerOffset: CGFloat {
        currentDividerOffset + gestureOffset
    }
    
    public init(visible: VisibleState = .both, @ViewBuilder subviews: @escaping SubviewsBuilder) {
        self.subviews = subviews()
        self.visibleState = visible
    }
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                
                if visibleState == .primary || visibleState == .both {
                    subviews.value.0
                        .frame(maxHeight: .infinity)
                        .frame(width: (visibleState == .both) ? min(max(geometry.size.width / 2 - 1 + dividerOffset, 0), geometry.size.width) : geometry.size.width)
                }
                
                if visibleState == .both {
                    separator()
                }
                
                if visibleState == .secondary || visibleState == .both {
                    subviews.value.1
                        .frame(maxHeight: .infinity)
                        .frame(width: (visibleState == .both) ? min(max(geometry.size.width / 2 - 1 - dividerOffset, 0), geometry.size.width) : geometry.size.width)
                }
            }
        }
    }
    
    func separator() -> some View {
        return VStack {
            Color(NSColor(red: 0, green: 0, blue: 0, alpha: 0.4))
        }.frame(width: 2)
        .gesture(DragGesture(coordinateSpace: .global)
                    .updating($gestureOffset, body: { value, state, _ in
                        state = value.translation.width
                    })
                    .onEnded { value in
                        currentDividerOffset += value.translation.width
                    })
        .onHover { isOver in
            if isOver {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
