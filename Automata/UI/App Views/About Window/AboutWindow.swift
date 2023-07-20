//
//  Copyright © 2023 Apparata AB. All rights reserved.
//

import SwiftUI

struct AboutWindow: Scene {

	static let windowID = "about"
	
	var body: some Scene {
		Window("About", id: Self.windowID) {
			AboutView(
				name: Bundle.main.name,
				version: Bundle.main.version,
				build: Bundle.main.buildVersion,
				copyright: Bundle.main.copyright,
				developerName: "Apparata AB")
			.frame(minWidth: 500, maxWidth: 500, minHeight: 260, maxHeight: 260)
		}
		.keyboardShortcut("a", modifiers: [.option, .command])
		.commandsRemoved() // Don't show window in Windows menu
		.defaultPosition(.center)
		.defaultSize(width: 500, height: 260)
		.windowResizability(.contentSize)
		.windowStyle(.hiddenTitleBar)
	}
}
