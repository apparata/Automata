//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI
import SwiftUIToolbox

enum ColorMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

struct AppSettings: AppStorageDefaults {
    var colorMode: ColorMode { .dark }
}

struct ColorSchemeCommands: Commands {
        
    @AppStorage(\AppSettings.colorMode) private var colorMode
    
    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            Picker("Color Mode", selection: $colorMode) {
                ForEach(ColorMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                        .tag(mode.rawValue)
                }
            }
            .pickerStyle(.inline)
        }
    }
}
