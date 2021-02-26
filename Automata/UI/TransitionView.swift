//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import CGMath
import SwiftUIToolbox

private struct EventNamesHeightKey: PreferenceKey {
    
    static var defaultValue: CGFloat = 20

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TransitionView: View {
    
    enum Direction {
        case outgoing
        case incoming
        case both
    }
    
    @EnvironmentObject private var automat: Automat
    
    @ObservedObject var transition: StateTransition
            
    @State var isAnimating = false
    
    var direction: Direction {
        let hasOutgoing = transition.events.filter { $0.outgoing }.count > 0
        let hasIncoming = transition.events.filter { !$0.outgoing }.count > 0
        switch (hasOutgoing, hasIncoming) {
        case (true, false): return .outgoing
        case (false, true): return .incoming
        case (false, false), (true, true): return .both
        }
    }
    
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: position(of: transition.fromNode))
                path.addLine(to: position(of: transition.toNode))
            }
            .stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round))
            
            switch direction {
            case .outgoing:
                Path { path in
                    path.move(to: position(of: transition.fromNode))
                    path.addLine(to: position(of: transition.toNode))
                }
                .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round, dash: [12, 12], dashPhase: self.isAnimating ? 0 : 48))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                .onAppear {
                    isAnimating.toggle()
                }
            case .incoming: EmptyView()
                Path { path in
                    path.move(to: position(of: transition.fromNode))
                    path.addLine(to: position(of: transition.toNode))
                }
                .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round, dash: [12, 12], dashPhase: self.isAnimating ? 0 : -48))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                .onAppear {
                    isAnimating.toggle()
                }
            case .both: EmptyView()
                Path { path in
                    path.move(to: position(of: transition.fromNode))
                    path.addLine(to: position(of: transition.toNode))
                }
                .stroke(Color.black.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round, dash: [12, 12], dashPhase: self.isAnimating ? 0 : 48))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true))
                .onAppear {
                    isAnimating.toggle()
                }
            }
                        
            TransitionEventLabel(
                transition: transition,
                outgoing: true,
                fromPoint: automat.state(by: transition.fromNode)?.position ?? .zero,
                toPoint: automat.state(by: transition.toNode)?.position ?? .zero)

            TransitionEventLabel(
                transition: transition,
                outgoing: false,
                fromPoint: automat.state(by: transition.fromNode)?.position ?? .zero,
                toPoint: automat.state(by: transition.toNode)?.position ?? .zero)

        }
    }
    
    private func position(of stateNodeID: StateNodeID) -> CGPoint {
        automat.state(by: stateNodeID)?.position ?? .zero
    }
}

struct EditEventNameView: View {
    
    @ObservedObject var event: StateTransition.Event
    
    var transition: StateTransition
    
    var body: some View {
        TextField("Event", text: $event.name)
            .multilineTextAlignment(.center)
            .font(Font.system(size: 14, weight: .medium, design: .default))
            .textFieldStyle(PlainTextFieldStyle())
            .onReceive(event.objectWillChange) { _ in
                transition.objectWillChange.send()
            }
    }
}

struct TransitionEventLabel: View {
    
    @EnvironmentObject private var automat: Automat
    
    @ObservedObject private var transition: StateTransition
    private let outgoing: Bool
    private let fromPoint: CGPoint
    private let toPoint: CGPoint
    
    @State private var width: CGFloat = 0
    
    @State private var isEditingEvents: Bool = false
    
    @State private var eventsNamesOffset: CGFloat = 0
        
    init(transition: StateTransition, outgoing: Bool, fromPoint: CGPoint, toPoint: CGPoint) {
        self.transition = transition
        self.outgoing = outgoing
        self.fromPoint = fromPoint
        self.toPoint = toPoint
    }
            
    var body: some View {
        HStack(spacing: 4) {
            if outgoing, transition.events.filter({ $0.outgoing }).count > 0 {
                if !isFromStateLeftOfToState {
                    Image(systemName: "arrowtriangle.backward.fill")
                }
                VStack(spacing: 2) {
                    ForEach(transition.events.filter { $0.outgoing }) { event in
                        Text(event.name)
                            .font(Font.system(size: 14, weight: .medium, design: .default))
                    }
                }
                if isFromStateLeftOfToState {
                    Image(systemName: "arrowtriangle.forward.fill")
                }
            }
            
            if !outgoing, transition.events.filter({ !$0.outgoing }).count > 0 {
                if isFromStateLeftOfToState {
                    Image(systemName: "arrowtriangle.backward.fill")
                }
                VStack(spacing: 2) {
                    ForEach(transition.events.filter { !$0.outgoing }) { event in
                        Text(event.name)
                            .font(Font.system(size: 14, weight: .medium, design: .default))
                    }
                }
                if !isFromStateLeftOfToState != outgoing {
                    Image(systemName: "arrowtriangle.forward.fill")
                }

            }
        }
        .font(Font.system(size: 14, weight: .medium, design: .default))
        .foregroundColor(.white)
        .background(GeometryReader { proxy in
            Color.clear
                .preference(key: EventNamesHeightKey.self, value: proxy.size.height / 2)
            }.onPreferenceChange(EventNamesHeightKey.self, perform: { height in
                eventsNamesOffset = height
            }))
        .offset(x: 0, y: outgoing ? -12 - eventsNamesOffset : 12 + eventsNamesOffset)
        .rotationEffect(labelAngle)
        .popover(isPresented: $isEditingEvents) {
            eventsEditor()
        }
        .position(CGPoint.average(fromPoint, toPoint))
        .gesture(TapGesture(count: 1).onEnded {
            isEditingEvents = true
        })
    }
    
    private func eventsEditor() -> some View {
        VStack {
            Text("Transition Events")
                .font(.title2)
                .fontWeight(.semibold)

            if transition.events.filter { $0.outgoing }.count > 0 {
                HSeparator(color: .separator)
                ForEach(transition.events.filter { $0.outgoing }) { event in
                    HStack {
                        Button(action: { removeEvent(event) }) {
                            Image(systemName: "minus.circle.fill")
                                .renderingMode(.original)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                        
                        EditEventNameView(event: event, transition: transition)

                        Spacer()
                        Button(action: { flipEvent(event) }) {
                            Image(systemName: "arrowtriangle.forward.circle.fill")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(4)
                    .animation(.easeInOut(duration: 0.3))
                    .transition(.opacity)

                }
            }

            if transition.events.filter { !$0.outgoing }.count > 0 {
                HSeparator(color: .separator)

                ForEach(transition.events.filter { !$0.outgoing }) { event in
                    HStack {
                        Button(action: { flipEvent(event) }) {
                            Image(systemName: "arrowtriangle.backward.circle.fill")
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                        
                        EditEventNameView(event: event, transition: transition)

                        Spacer()
                        Button(action: { removeEvent(event) }) {
                            Image(systemName: "minus.circle.fill")
                                .renderingMode(.original)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(4)
                    .animation(.easeInOut(duration: 0.3))
                    .transition(.opacity)

                }
            }

            HSeparator(color: .separator)
            Button("Add Event", action: addEvent)
                .padding(.top, 8)
            Spacer()
        }
        .frame(minWidth: 220)
        .padding([.top, .horizontal])
        .padding(.bottom, 8)

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
    
    private func addEvent() {
        transition.events.append(.init(name: "New Event", outgoing: true))
    }
    
    private func removeEvent(_ event: StateTransition.Event) {
        if transition.events.count > 1 {
            transition.events.removeFirst(where: { $0.id == event.id })
        } else {
            automat.removeTransition(id: transition.id)
            isEditingEvents = false
        }
    }
    
    private func flipEvent(_ event: StateTransition.Event) {
        withAnimation {
            event.outgoing.toggle()
        }
    }
}
