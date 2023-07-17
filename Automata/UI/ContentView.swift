//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Cocoa
import SwiftUI

struct ContentView: View {
        
    @EnvironmentObject private var automat: Automat
        
    @Environment(\.undoManager) private var undoManager
    
    @AppStorage("appTheme") var appTheme: String = "system"
    
    @State private var isCodeVisible: Bool = false
    
    var body: some View {
        HSplitView(visible: isCodeVisible ? .both : .primary) {
            Canvas()
                .onAppear {
                    applyTheme()
                }
                .overlay(alignment: .bottomLeading) {
                    CanvasHelp()
                        .padding()
                }
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        SwiftCode(generateStateMachine(name: "My State Machine", automat: automat))
                            .padding()
                        Spacer()
                    }
                }
            }
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
        }
        .onChange(of: undoManager, perform: automat.updateUndoManager)
        .toolbar {
            /*ToolbarItem(placement: ToolbarItemPlacement.navigation) {
                Button(action: {
                    print("Stuff")
                }) {
                    Image(systemName: "chevron.left")
                }.help("Back")
            }*/

            ToolbarItem {
                Toggle(isOn: $isCodeVisible) {
                    Image(systemName: "uiwindow.split.2x1")
                }
                .toggleStyle(.button)
            }
        }
    }
    
    private func applyTheme() {
        switch appTheme {
            case "dark":
                NSApp.appearance = NSAppearance(named: .darkAqua)
            case "light":
                NSApp.appearance = NSAppearance(named: .aqua)
            default:
                NSApp.appearance = nil
        }
    }
}
