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
    
    @ObservedObject private var node: StateNode
            
    private var transitionCreation: TransitionCreation
    private var isSourceOfTransitionCreation: Bool
    private var isTargetOfTransitionCreation: Bool

    @State private var isHovering: Bool = false
    
    private var isSelected: Bool {
        automat.isStateNodeSelected(id: node.id)
    }
    
    private var isInitialState: Bool {
        automat.isInitialStateNode(id: node.id)
    }
    
    init(node: StateNode, transitionCreation: TransitionCreation) {
        self.node = node
        self.transitionCreation = transitionCreation
        isSourceOfTransitionCreation = transitionCreation.fromNodeID == node.id
        isTargetOfTransitionCreation = transitionCreation.toNodeID == node.id
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
        .background(
            GeometryReader { geometry in
                background()
                    .preference(key: StateViewSizeKey.self, value: geometry.size)
                    .zIndex(0)
            }
            .onPreferenceChange(StateViewSizeKey.self) { size in
                node.updateSize(size)
            }
        )
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
        .shadow(color: glowColor(), radius: 12, x: 0, y: 2)
        .position(node.position)
    }

    // MARK: - Subviews
    
    private func background() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(isSelected ? Color.yellow : Color.black.opacity(0.2), lineWidth: 3)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .foregroundColor(evaluateNodeColor()))
    }
    
    private func glowColor() -> Color {
        (isSelected ? Color.yellow.opacity(0.3) : evaluateNodeColor().opacity(0.1))
    }
    
    private func evaluateNodeColor() -> Color {
        if transitionCreation.isActive, isTargetOfTransitionCreation {
            return .pink
        } else if transitionCreation.isActive, isSourceOfTransitionCreation {
            return .pink
        } else if isInitialState {
            return .systemGreen
        } else {
            return .systemBlue
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
}
