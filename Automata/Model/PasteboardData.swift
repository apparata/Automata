//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

class PasteboardData: NSObject, NSItemProviderWriting, Codable {
    
    static var writableTypeIdentifiersForItemProvider: [String] = ["se.apparata.tools.Automata.states"]
        
    let data: Automat.DataModel
    
    init(data: Automat.DataModel) {
        self.data = data
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)
        do {
            let encodedData = try JSONEncoder().encode(data)
            completionHandler(encodedData, nil)
        } catch {
            completionHandler(nil, error)
        }
        return progress
    }
}
