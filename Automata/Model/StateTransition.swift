//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

typealias StateTransitionID = UUID

class StateTransition: Identifiable, ObservableObject, Codable {

    let id: StateTransitionID
    
    @Published var event: String
    
    let fromNode: StateNodeID
    let toNode: StateNodeID
    
    init(id: StateTransitionID, from fromNode: StateNodeID, to toNode: StateNodeID, dueTo event: String? = nil) {
        self.id = id
        self.event = event ?? "Transition"
        self.fromNode = fromNode
        self.toNode = toNode
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case event
        case fromNode
        case toNode
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(StateNodeID.self, forKey: .id)
        event = try container.decode(String.self, forKey: .event)
        fromNode = try container.decode(StateNodeID.self, forKey: .fromNode)
        toNode = try container.decode(StateNodeID.self, forKey: .toNode)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(event, forKey: .event)
        try container.encode(fromNode, forKey: .fromNode)
        try container.encode(toNode, forKey: .toNode)
    }

}

extension StateTransition: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension StateTransition: Equatable {
    static func == (lhs: StateTransition, rhs: StateTransition) -> Bool {
        lhs.id == rhs.id
    }
}
