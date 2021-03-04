//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import CGMath

private struct StateViewSizeKey: PreferenceKey {
    
    static var defaultValue: CGSize = CGSize(width: StateView.minWidth, height: StateView.minHeight)

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct StateView: View {
    
    fileprivate static let minWidth: CGFloat = 80
    fileprivate static let minHeight: CGFloat = 50
    
    @EnvironmentObject private var automat: Automat
    
    @ObservedObject var node: StateNode
            
    var transitionCreation: TransitionCreation
    var isSourceOfTransitionCreation: Bool
    @Binding var targetForTransitionCreation: StateNode?

    @State private var isHovering: Bool = false
    
    private var isSelected: Bool {
        automat.isStateNodeSelected(id: node.id)
    }
    
    init(node: StateNode, transitionCreation: TransitionCreation, isSourceOfTransitionCreation: Bool, targetForTransitionCreation: Binding<StateNode?>) {
        self.node = node
        self.transitionCreation = transitionCreation
        self.isSourceOfTransitionCreation = isSourceOfTransitionCreation
        self._targetForTransitionCreation = targetForTransitionCreation
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Text(node.name)
                .font(Font.system(size: 14, weight: .medium, design: .default))
                .lineLimit(1)
                .foregroundColor(.white)
                .frame(minWidth: 4, minHeight: 20)
                .overlay(nameTextField())
                .padding(.horizontal, 30)
                .padding(.vertical, 20)

        }
        .frame(minWidth: StateView.minWidth, minHeight: StateView.minHeight)
        .onHover(perform: handleHover)
        .background(GeometryReader { geometry in
            background()
                .preference(key: StateViewSizeKey.self, value: geometry.size)
                .zIndex(0)
        })
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        .position(node.position)
        .onPreferenceChange(StateViewSizeKey.self) { size in
            node.updateSize(size)
        }
    }

    // MARK: - Subviews
    
    private func background() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(isSelected ? Color.yellow : Color.black.opacity(0.2), lineWidth: 3)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .foregroundColor(evaluateNodeColor()))
    }
    
    private func evaluateNodeColor() -> Color {
        if transitionCreation.isActive, isHovering {
            return Color.pink
        } else if transitionCreation.isActive, isSourceOfTransitionCreation {
            return Color.pink
        } else {
            return Color(.systemBlue)
        }
    }
    
    private func nameTextField() -> some View {
        NodeTextField(text: $node.name, nodeID: node.id)
            .font(Font.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.clear)
            .textFieldStyle(PlainTextFieldStyle())
            .onChange(of: node.name) { _ in
                automat.objectWillChange.send()
            }
    }
    
    // MARK: - Hovering
    
    private func handleHover(isHovering: Bool) {
        self.isHovering = isHovering
        if isHovering, transitionCreation.isActive {
            targetForTransitionCreation = node
        } else if !isHovering, targetForTransitionCreation == node {
            targetForTransitionCreation = nil
        }
    }
}
