//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

extension String {
    
    var uppercasingFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }

    var lowercasingFirst: String {
        return prefix(1).lowercased() + dropFirst()
    }

    var camelCase: String {
        guard !isEmpty else {
            return ""
        }

        let parts = self.components(separatedBy: CharacterSet.alphanumerics.inverted)

        let first = String(describing: parts[0]).lowercasingFirst
        let rest = parts.dropFirst().map { String($0).uppercasingFirst }

        return ([first] + rest).joined(separator: "")
    }
}

extension Array where Element == String {
    
    var joinedCamelCased: String {
        
        guard let firstPart = first?.lowercasingFirst else {
            return ""
        }
        let rest = dropFirst().map { $0.uppercasingFirst }
        
        return ([firstPart] + rest).joined(separator: "")
    }
}
