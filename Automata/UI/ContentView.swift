//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Cocoa
import SwiftUI
import Splash

struct ContentView: View {
        
    let url: URL?
    
    @EnvironmentObject private var automat: Automat
        
    @Environment(\.undoManager) private var undoManager
    
    @AppStorage("appTheme") var appTheme: String = "system"
    
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    
    @State private var isCodeVisible: Bool = false
    
    @State private var flashCopiedIndicator: Bool = false
    
    @State private var isLicenseExpanded: Bool = false
    
    private var codeTheme: Splash.Theme {
        colorScheme == .light ? .automatLight : .automatDark
    }
    
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
                                    .tint(.primary)
                                Text("License for generated code")
                                    .foregroundColor(.primary)
                            }
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                        
                        if isLicenseExpanded {
                            SwiftCode(licenseForGeneratedCode, theme: codeTheme)
                        }
                        
                        SwiftCode(generateStateMachine(url: url, automat: automat), theme: codeTheme)
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color(codeTheme.backgroundColor))
            .overlay(alignment: .bottomTrailing) {
                HStack(spacing: 8) {
                    if flashCopiedIndicator {
                        Text("Copied!")
                            .foregroundStyle(.primary)
                    }
                    Button {
                        let code = licenseForGeneratedCode + "\n"
                            + generateStateMachine(url: url, automat: automat)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(code, forType: .string)
                        withAnimation(.smoothSpring) {
                            flashCopiedIndicator = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            withAnimation(.smoothSpring) {
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
        .background(Color(codeTheme.backgroundColor))
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
                Toggle(isOn: $isCodeVisible.animation(.smoothSpring)) {
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
