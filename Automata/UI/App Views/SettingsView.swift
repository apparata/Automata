//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("someKindOfSetting") var someKindOfSetting: Bool = false

    var body: some View {
        Toggle(isOn: $someKindOfSetting) {
            Text("Some kind of setting")
        }
        .frame(width: 220, height: 80)
    }
}
