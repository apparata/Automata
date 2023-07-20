//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    
    let name: String
    let version: String
    let build: String
    let copyright: String?
    let developerName: String
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Image(nsImage: NSApp?.applicationIconImage ?? NSImage())
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 4)
                    .padding()
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(name)
                            .font(.title)
                            .bold()
                        Spacer()
                        Group {
                            Text("Version \(version)") + Text(" (\(build))")
                        }.foregroundColor(.secondary)
                    }
                    Divider()
                        .padding(.top, -8)
                    Text("Developed by")
                        .bold()
                        .padding(.bottom, 2)
                    Text(developerName)
                        .padding(.bottom, 12)
                    Spacer()
                    if let copyright {
                        Text(copyright)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }.padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 30))
            }
            HStack {
                Spacer()
                Button {
                    openWindow(id: AttributionsWindow.windowID)
                } label: {
                    Text("Attributions")
                }
            }.padding()
                .background(Color(.sRGB, white: 0.0, opacity: 0.1))
        }
    }
}
