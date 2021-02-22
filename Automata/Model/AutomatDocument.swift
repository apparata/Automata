//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import CollectionKit

extension UTType {
    static let automatDocument = UTType(exportedAs: "se.apparata.tools.Automata.automat")
}

class AutomatDocument: ReferenceFileDocument {
        
    var automat: Automat
    private var subscription: AnyCancellable?
        
    init() {
        automat = Automat()
        subscription = automat.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }

    // MARK: - Document Support
    
    static var readableContentTypes: [UTType] { [.automatDocument] }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        automat = try JSONDecoder().decode(Automat.self, from: data)
    }
    
    func snapshot(contentType: UTType) throws -> Automat {
        // Create a copy to prevent user edits from changing
        // the data being serialized.
        return automat.snapshot()
    }
    
    func fileWrapper(snapshot: Automat, configuration: WriteConfiguration) throws -> FileWrapper {
        log(debug: "💾 Saving...")
        let data = try JSONEncoder().encode(automat)
        return .init(regularFileWithContents: data)
    }
}
