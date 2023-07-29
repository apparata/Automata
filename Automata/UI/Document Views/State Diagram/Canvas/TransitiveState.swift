//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct TransitiveState: View {
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.transientState.opacity(0.2), style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round, dash: [8, 8], dashPhase: 10))
            .frame(width: 128.5, height: 60)
    }
}
