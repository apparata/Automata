//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

extension Color {
    static let state = color("State")
    static let initialState = color("Initial State")
    static let endState = color("End State")
    static let transientState = color("Transient State")
    static let selectedState = color("Selected State")
    static let transition = color("Transition")
    static let transientTransition = color("Transient Transition")
    static let areaSelection = color("Area Selection")
}

private func color(_ name: String) -> Color {
    Color("Color/\(name)")
}
