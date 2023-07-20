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
    
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject private var node: StateNode
            
    private let transitionCreation: TransitionCreation
    private let isSourceOfTransitionCreation: Bool
    private let isTargetOfTransitionCreation: Bool

    @State private var isHovering: Bool = false
    
    @EnvironmentObject private var editState: StateEditState
    
    @FocusState private var isFocused: Bool
    
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
        TextField("", text: $node.name)
            .labelsHidden()
            .font(Font.system(size: 14, weight: .medium, design: .default))
            .foregroundColor(.clear)
            .textFieldStyle(.plain)
            .saturation(0)
            .blendMode(colorScheme == .dark ? .screen : .colorBurn)
            .disabled(editState.editingNodeWithID != node.id)
            .focused($isFocused)
            .onSubmit {
                editState.editingNodeWithID = nil
            }
            .onChange(of: node.name) { _ in
                automat.objectWillChange.send()
            }
            .onChange(of: editState.editingNodeWithID) { value in
                isFocused = value == node.id
            }
    }
}
