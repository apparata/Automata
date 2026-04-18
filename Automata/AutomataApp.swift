//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox
import AttributionsUI
import Sparkle

@main
struct AutomataApp: App {

    @AppStorage(\AppSettings.colorMode) private var colorMode

    @Environment(\.scenePhase) var scenePhase

    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    var body: some Scene {
        DocumentWindow()
            // This has to be here to work, or menu won't trigger a change
            .onChange(of: colorMode) { theme in
                Self.applyColorMode(theme)
            }
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    Self.applyColorMode(colorMode)
                }
            }
            .commands {
                CheckForUpdatesCommand(updater: updaterController.updater)
            }

        SettingsWindow()

        HelpWindow()

        AboutWindow(developedBy: "Apparata AB",
                    attributionsWindowID: AttributionsWindow.windowID)

        AttributionsWindow([
                ("Splash", .mit(year: "2018", holder: "John Sundell")),
                ("Sparkle", .mit(year: "2006-2017", holder: "Andy Matuschak and the Sparkle Project Contributors"))
            ],
            header: "The following software may be included in this product.")
    }
    
    private static func applyColorMode(_ colorMode: ColorMode) {
        switch colorMode {
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .system: NSApp.appearance = nil
        }
    }
}
