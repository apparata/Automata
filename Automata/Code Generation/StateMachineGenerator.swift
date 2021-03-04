//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import TextToolbox

func generateStateMachine(name: String, automat: Automat) -> String {
    
    let nameString = name.camelCase.uppercasingFirst
    
    // MARK: States
    
    let stateNameTuples = automat.stateNodes.map { state in
        (state.id, state.name.camelCase.lowercasingFirst)
    }
    
    let initialState = automat.initialState?.name.camelCase.lowercasingFirst ?? stateNameTuples.first?.1 ?? "exampleState"
    
    let groupedStateNames = Dictionary(grouping: stateNameTuples.map(\.1), by: { $0 })
    
    let statesString: String

    let stateNamesByID = Dictionary(stateNameTuples) { first, _ in first }
    
    if stateNameTuples.isEmpty {
        statesString = #"#warning("There are no states yet.")"#
    } else {
        statesString = automat.stateNodes.map { state in
            let stateName = stateNamesByID[state.id]!
            let warning: String
            if groupedStateNames[stateName]!.count > 1 {
                warning = #" ; #warning("Duplicate state")"#
            } else {
                warning = ""
            }
            return "        case \(stateName)\(warning)\n"
        }.sorted().joined().trimmed()
    }
    
    // MARK: Events
    
    let eventCases = automat.stateTransitions.flatMap { transition in
        transition.events.map { event in
            event.name.camelCase.lowercasingFirst
        }
    }.unique.sorted().map { eventName in
        "        case \(eventName)\n"
    }

    let eventsString: String
    if eventCases.isEmpty {
        eventsString = #"#warning("There are no events yet.")"#
    } else {
        eventsString = eventCases.joined().trimmed()
    }
    
    let exampleEvent = automat.stateTransitions.first?.events.first?.name.camelCase.lowercasingFirst.trimmed() ?? "exampleEvent"
        
    // MARK: Transitions
    
    var transitions: [String] = []

    for transition in automat.stateTransitions {
        let fromNode = stateNamesByID[transition.fromNode]!
        let toNode = stateNamesByID[transition.toNode]!

        for event in transition.events {
            let eventName = event.name.camelCase.lowercasingFirst
            if event.outgoing {
                transitions.append("        case (.\(fromNode), .\(eventName)): return .\(toNode)\n")
            } else {
                transitions.append("        case (.\(toNode), .\(eventName)): return .\(fromNode)\n")
            }
        }
    }
    
    let transitionsString: String
    if transitions.isEmpty {
        transitionsString = #"#warning("There are no transitions yet.")"#.trimmed()
    } else {
        transitionsString = transitions.joined().trimmed()
    }
    
    // MARK: Template
    
    return """
/// Requires StateMachine.swift from https://github.com/apparata/Constructs

import Foundation
import Constructs

/// Example:
///
/// ```
/// let stateMachine = StateMachine(initialState: .\(initialState))
/// let delegate = \(nameString)Delegate()
/// stateMachine.delegate = delegate
/// stateMachine.fireEvent(.\(exampleEvent))
/// ```
class \(nameString)Delegate: StateMachineDelegate {
 
    enum State {
        \(statesString)
    }
    
    enum Event {
        \(eventsString)
    }
    
    /// Returns state to transition to from the current state given an event.
    /// Returns nil to not trigger a transition.
    /// Returns the from state for a loopback transition to itself.
    func stateToTransitionTo(from state: State, dueTo event: Event) -> State? {
        switch (state, event) {
        \(transitionsString)
        default:
            return nil
        }
    }
    
    func willTransition(from state: State, to newState: State, dueTo event: Event) {
        switch (state, event, newState) {
            // Insert your pre-transition side effect code here.
        default:
            break
        }
    }
    
    func didTransition(from state: State, to newState: State, dueTo event: Event) {
        switch (state, event, newState) {
            // Insert your post-transition side effect code here.
        default:
            break
        }
    }
}
"""
}
