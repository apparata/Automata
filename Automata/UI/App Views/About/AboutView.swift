//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Cocoa
import SwiftUI

extension AboutView {
    static func present() {
        AboutWindowController().window?.makeKeyAndOrderFront(nil)
    }
}

/// Remember to set the `NSHumanReadableCopyright` in `Info.plist`:
///
/// ```
/// <key>NSHumanReadableCopyright</key>
/// <string>Copyright © 2021 Apparata AB. All rights reserved.</string>
/// ```
struct AboutView: View {
    
    let icon: NSImage
    let name: String
    let version: String
    let build: String
    let copyright: String
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Image(nsImage: icon)
                    .padding([.horizontal])
                    .padding([.top], 12)
                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(name)
                            .font(.title)
                            .bold()
                        Spacer()
                        Text("Version \(version)") + Text(" (\(build))")
                    }
                    Divider()
                        .padding(.top, -8)
                    Text("Developed by")
                        .bold()
                        .padding(.bottom, 2)
                    Text("Martin Johannesson")
                        .padding(.bottom, 12)
                    Spacer()
                    Text(copyright)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }.padding(EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 30))
            }
            HStack {
                Spacer()
                Button(action: {
                    //AttributionsWindowController().window?.makeKeyAndOrderFront(nil)
                }) {
                    Text("Attributions")
                }
            }.padding()
                .background(Color(.sRGB, white: 0.0, opacity: 0.05))
        }
    }
}

class AboutWindowController: NSWindowController {

    convenience init() {
        
        let window = Self.makeWindow()
                
        window.backgroundColor = NSColor.controlBackgroundColor
                
        self.init(window: window)

        let contentView = makeAboutView()
            
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.center()
        window.title = "About Bootstrapp"
        window.contentView = NSHostingView(rootView: contentView)
        window.alwaysOnTop = true
    }
    
    private static func makeWindow() -> NSWindow {
        let contentRect = NSRect(x: 0, y: 0, width: 500, height: 260)
        let styleMask: NSWindow.StyleMask = [
            .titled,
            .closable,
            .fullSizeContentView
        ]
        return NSWindow(contentRect: contentRect,
                        styleMask: styleMask,
                        backing: .buffered,
                        defer: false)
    }

    private func makeAboutView() -> some View {
        
        let icon = NSApp.applicationIconImage ?? NSImage()
        let info = Bundle.main.infoDictionary
        let name = info?["CFBundleName"] as? String ?? "Bootstrapp"
        let version = info?["CFBundleShortVersionString"] as? String ?? "?.?.?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let copyright = info?["NSHumanReadableCopyright"] as? String ?? "Copyright © Apparata AB"
        
        return AboutView(icon: icon,
                         name: name,
                         version: version,
                         build: build,
                         copyright: copyright)
            .frame(width: 500, height: 260)
    }
}

fileprivate extension NSWindow {
    
    var alwaysOnTop: Bool {
        get {
            return level.rawValue >= Int(CGWindowLevelForKey(CGWindowLevelKey.statusWindow))
        }
        set {
            if newValue {
                makeKeyAndOrderFront(nil)
                level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.statusWindow)))
            } else {
                level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
            }
        }
    }
}
