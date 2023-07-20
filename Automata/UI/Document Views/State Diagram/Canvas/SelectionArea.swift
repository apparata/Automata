//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct SelectionArea: View {
    
    let frame: CGRect
    
    var body: some View {
        Rectangle()
            .strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1)
            .background(Color.yellow.opacity(0.1))
            .position(frame.center)
            .frame(width: frame.width, height: frame.height)
            .allowsHitTesting(false)
    }
}
