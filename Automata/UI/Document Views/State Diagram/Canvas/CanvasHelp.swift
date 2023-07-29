//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct CanvasHelp: View {
    
    @State private var isExpanded: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack {
                QuickReference()
            }
            .frame(width: 500, height: 360)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.05), lineWidth: 1))
            .scaleEffect(isExpanded ? 1 : 0.01, anchor: .bottomLeading)
            .offset(isExpanded ? CGSize(width: -4, height: 4) :  CGSize(width: 5, height: -5))
            Button {
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 23, initialVelocity: 5)) {
                    isExpanded.toggle()
                }
            } label: {
                let backgroundColor: Color = colorScheme == .dark ? .black : .white
                ZStack {
                    Image(systemName: "questionmark")
                        .font(.system(size: 12))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 1)
                        .frame(width: 22, height: 22)
                        .background(backgroundColor)
                        .clipShape(Circle())
                    if isExpanded {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.bottom, 1)
                            .frame(width: 21, height: 21)
                            .background(backgroundColor)
                            .clipShape(Circle())
                    }
                }
                .rotationEffect(isExpanded ? Angle(degrees: 180) : Angle(degrees: 0))
            }
            .buttonStyle(.plain)
        }
    }
}

struct QuickReference: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Quick Reference")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            Grid(horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Image(systemName: "cursorarrow.click.2")
                        .imageScale(.large)
                        .fontWeight(.semibold)
                        .gridColumnAlignment(.center)
                    Text("Double-click to add a state.")
                        .gridColumnAlignment(.leading)

                }
                Group {
                    Divider()
                    GridRow {
                        HStack(spacing: 2) {
                            Image(systemName: "command")
                                .imageScale(.medium)
                                .fontWeight(.semibold)
                            Image(systemName: "cursorarrow.motionlines.click")
                                .imageScale(.large)
                                .fontWeight(.semibold)
                        }
                        Text("Cmd + drag from a state to create a transition.")
                    }
                }
                Group {
                    Divider()
                    GridRow {
                        HStack(spacing: 2) {
                            Image(systemName: "shift")
                                .imageScale(.medium)
                                .fontWeight(.semibold)
                            Image(systemName: "command")
                                .imageScale(.medium)
                                .fontWeight(.semibold)
                            Image(systemName: "cursorarrow.motionlines.click")
                                .imageScale(.large)
                                .fontWeight(.semibold)
                        }
                        Text("Shift + Cmd + drag from state to create transition and state.")
                    }
                }
                Group {
                    Divider()
                    GridRow {
                        Image(systemName: "contextualmenu.and.cursorarrow")
                            .imageScale(.large)
                            .fontWeight(.semibold)
                        Text("States have a context menu with more options.")
                            .gridColumnAlignment(.leading)
                        
                    }
                }
                Group {
                    Divider()
                    GridRow {
                        Image(systemName: "cursorarrow.click")
                            .imageScale(.large)
                            .fontWeight(.semibold)
                        Text("Click an event label to add or edit events for a transition.")
                            .gridColumnAlignment(.leading)
                        
                    }
                }
                Group {
                    Divider()
                    GridRow {
                        Image(systemName: "delete.backward")
                            .imageScale(.large)
                            .fontWeight(.semibold)
                        Text("Press delete to remove selected state(s).")
                            .gridColumnAlignment(.leading)
                    }
                }
                Group {
                    Divider()
                    GridRow {
                        Image(systemName: "rectangle.dashed")
                            .imageScale(.large)
                            .fontWeight(.semibold)
                        Text("Drag to select multiple states in an area.")
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding()
    }
}
