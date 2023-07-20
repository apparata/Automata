//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import Splash
import Cocoa


public extension Splash.Theme {
    
    static var automatDark: Splash.Theme {
        return Splash.Theme(
            font: Font(size: 13),
            plainTextColor: NSColor(
                red: 0.66,
                green: 0.74,
                blue: 0.74,
                alpha: 1
            ),
            tokenColors: [
                .keyword: Splash.Color(red: 0.91, green: 0.2, blue: 0.54, alpha: 1),
                .string: Splash.Color(red: 0.98, green: 0.39, blue: 0.12, alpha: 1),
                .type: Splash.Color(red: 0.51, green: 0.51, blue: 0.79, alpha: 1),
                .call: Splash.Color(red: 0.2, green: 0.56, blue: 0.9, alpha: 1),
                .number: Splash.Color(red: 0.86, green: 0.44, blue: 0.34, alpha: 1),
                .comment: Splash.Color(red: 0.12, green: 0.50, blue: 0.38, alpha: 1),
                .property: Splash.Color(red: 0.13, green: 0.67, blue: 0.62, alpha: 1),
                .dotAccess: Splash.Color(red: 0.57, green: 0.7, blue: 0, alpha: 1),
                .preprocessing: Splash.Color(red: 0.71, green: 0.54, blue: 0, alpha: 1)
            ],
            backgroundColor: Splash.Color(
                red: 0.098,
                green: 0.098,
                blue: 0.098,
                alpha: 1
            )
        )
    }
    
    static var automatLight: Theme {
        return Theme(
            font: Font(size: 13),
            plainTextColor: NSColor(srgbRed: 0.2, green: 0.2, blue: 0.2, alpha: 1),
            tokenColors: [
                .keyword: NSColor(srgbRed: 0.706, green: 0.0, blue: 0.384, alpha: 1),
                .string: NSColor(srgbRed: 0.729, green: 0.0, blue: 0.067, alpha: 1),
                .type: NSColor(srgbRed: 0.267, green: 0.537, blue: 0.576, alpha: 1),
                .call: NSColor(srgbRed: 0.267, green: 0.537, blue: 0.576, alpha: 1),
                .number: NSColor(srgbRed: 0.0, green: 0.043, blue: 1.0, alpha: 1),
                .comment: NSColor(srgbRed: 0, green: 0.502, blue: 0, alpha: 1),
                .property: NSColor(srgbRed: 0.267, green: 0.537, blue: 0.576, alpha: 1),
                .dotAccess: NSColor(srgbRed: 0.267, green: 0.537, blue: 0.576, alpha: 1),
                .preprocessing: NSColor(srgbRed: 0.431, green: 0.125, blue: 0.051, alpha: 1)
            ],
            backgroundColor: NSColor(srgbRed: 0.96, green: 0.96, blue: 0.96, alpha: 1)
        )
    }
}
