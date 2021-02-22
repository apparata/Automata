//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI

struct ContentView: View {
        
    @ObservedObject var automat: Automat
    
    var body: some View {
        Canvas(automat: automat)
    }
}
