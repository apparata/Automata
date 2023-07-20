//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct GeneralSettingsTab: View {
    
    @AppStorage("appTheme") private var appTheme: String = "dark"
    
    var body: some View {
        Form {
            Section {
                Picker("Color Mode", selection: $appTheme) {
                    Text("System")
                        .tag("system")
                    Text("Dark")
                        .tag("dark")
                    Text("Light")
                        .tag("light")
                }
                .pickerStyle(.radioGroup)
            }
        }
        .padding(20)
    }}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsTab()
    }
}
