//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import AppKit

typealias StateNodeID = UUID

class StateNode: Identifiable, ObservableObject, Codable {

    var id: StateNodeID

    weak var automat: Automat?
    
    @Published var name: String
    @Published var position: CGPoint
    
    var outgoingTransitions: [StateTransitionID] = []
    var incomingTransitions: [StateTransitionID] = []
    
    init(id: StateNodeID, name: String, position: CGPoint, automat: Automat) {
        self.id = id
        self.name = name
        self.position = position
        self.automat = automat
    }
    
    func addOutgoingTransition(_ transitionID: StateTransitionID) {
        outgoingTransitions.append(transitionID)
    }
    
    func removeOutgoingTransition(_ transitionID: StateTransitionID) {
        outgoingTransitions.removeFirst { transitionID == $0 }
    }
    
    func addIncomingTransition(_ transitionID: StateTransitionID) {
        incomingTransitions.append(transitionID)
    }

    func removeIncomingTransition(_ transitionID: StateTransitionID) {
        incomingTransitions.removeFirst { transitionID == $0 }
    }

    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case position
        case outgoingTransitions
        case incomingTransitions
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(StateNodeID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        position = try container.decode(CGPoint.self, forKey: .position)
        outgoingTransitions = try container.decode([StateTransitionID].self, forKey: .outgoingTransitions)
        incomingTransitions = try container.decode([StateTransitionID].self, forKey: .incomingTransitions)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(position, forKey: .position)
        try container.encode(outgoingTransitions, forKey: .outgoingTransitions)
        try container.encode(incomingTransitions, forKey: .incomingTransitions)
    }
}


// MARK: - Hashable

extension StateNode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Equatable

extension StateNode: Equatable {
    static func == (lhs: StateNode, rhs: StateNode) -> Bool {
        lhs.id == rhs.id
    }
}
