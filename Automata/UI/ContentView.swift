//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Cocoa
import SwiftUI

struct ContentView: View {
        
    let url: URL?
    
    @EnvironmentObject private var automat: Automat
        
    @Environment(\.undoManager) private var undoManager
    
    @AppStorage("appTheme") var appTheme: String = "system"
    
    @State private var isCodeVisible: Bool = false
    
    @State private var flashCopiedIndicator: Bool = false
    
    @State private var isLicenseExpanded: Bool = false
    
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
                        Button {
                            withAnimation {
                                isLicenseExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.forward")
                                    .imageScale(.small)
                                    .fontWeight(.semibold)
                                    .rotationEffect(isLicenseExpanded ? Angle(degrees: 90) : Angle(degrees: 0))
                                Text("License for generated code")
                            }
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                        
                        if isLicenseExpanded {
                            SwiftCode(licenseForGeneratedCode)
                        }
                        
                        SwiftCode(generateStateMachine(url: url, automat: automat))
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 8) {
                    if flashCopiedIndicator {
                        Text("Copied!")
                            .foregroundStyle(.white)
                    }
                    Button {
                        let code = licenseForGeneratedCode + "\n"
                            + generateStateMachine(url: url, automat: automat)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(code, forType: .string)
                        withAnimation(.snappy) {
                            flashCopiedIndicator = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            withAnimation(.snappy) {
                                flashCopiedIndicator = false
                            }
                        }
                    } label: {
                        Label("Copy", systemImage: "square.on.square")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
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
                Toggle(isOn: $isCodeVisible.animation(.snappy)) {
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
