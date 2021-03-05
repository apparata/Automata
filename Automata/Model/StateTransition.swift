//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation

typealias StateTransitionID = UUID
typealias TransitionEventID = UUID

class StateTransition: Identifiable, ObservableObject, Codable {

    let id: StateTransitionID
        
    class Event: Identifiable, ObservableObject, Codable {
        let id: TransitionEventID
        @Published var name: String
        @Published var outgoing: Bool
        
        init(id: TransitionEventID = UUID(), name: String, outgoing: Bool) {
            self.id = id
            self.name = name
            self.outgoing = outgoing
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case outgoing
        }
        
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(StateNodeID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            outgoing = try container.decode(Bool.self, forKey: .outgoing)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(outgoing, forKey: .outgoing)
        }
    }
    
    @Published var events: [Event]
    
    let fromNode: StateNodeID
    let toNode: StateNodeID
    
    var isLoop: Bool {
        fromNode == toNode
    }
    
    init(id: StateTransitionID, from fromNode: StateNodeID, to toNode: StateNodeID, dueTo event: Event? = nil) {
        self.id = id
        self.events = [event ?? Event(name: "New Event", outgoing: true)]
        self.fromNode = fromNode
        self.toNode = toNode
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case events
        case fromNode
        case toNode
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(StateNodeID.self, forKey: .id)
        events = try container.decode([Event].self, forKey: .events)
        fromNode = try container.decode(StateNodeID.self, forKey: .fromNode)
        toNode = try container.decode(StateNodeID.self, forKey: .toNode)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(events, forKey: .events)
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
