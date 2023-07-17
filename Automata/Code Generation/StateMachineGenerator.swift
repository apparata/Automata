//
//  Copyright © 2021 Apparata AB. All rights reserved.
//

import Foundation
import TextToolbox

func generateStateMachine(url: URL?, automat: Automat) -> String {
    
    let name = url?.deletingPathExtension().lastPathComponent ?? "Untitled"
    
    let nameString = name.camelCase.uppercasingFirst
    
    // MARK: States
    
    let stateNameTuples = automat.stateNodes.map { state in
        (state.id, state.name.camelCase.lowercasingFirst)
    }
        
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
import Foundation

/// Example:
///
/// ```
/// let stateMachine = StateMachine<\(nameString)Delegate>(initialState: .myState)
/// let delegate = \(nameString)Delegate()
/// stateMachine.delegate = delegate
/// stateMachine.fireEvent(.newEvent)
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

// MARK: - Reusable StateMachine

public class StateMachine<Delegate: StateMachineDelegate> {
    
    public private(set) var state: Delegate.State
    
    public weak var delegate: Delegate?
    
    private var fireOnMainQueue: Bool
    
    public init(initialState: Delegate.State, fireOnMainQueue: Bool = false) {
        state = initialState
        self.fireOnMainQueue = fireOnMainQueue
    }
    
    public func fireEvent(_ event: Delegate.Event) {
        if fireOnMainQueue, !Thread.current.isMainThread {
            DispatchQueue.main.sync {
                self.internalFireEvent(event)
            }
        } else {
            internalFireEvent(event)
        }
    }
    
    private func internalFireEvent(_ event: Delegate.Event) {
        if let newState = delegate?.stateToTransitionTo(from: state, dueTo: event) {
            delegate?.willTransition(from: state, to: newState, dueTo: event)
            let oldState = state
            state = newState
            delegate?.didTransition(from: oldState, to: state, dueTo: event)
        }
    }
}

public protocol StateMachineDelegate: AnyObject {
    
    associatedtype State
    associatedtype Event
    
    /// Return state to transition to from the current state given an event.
    /// Return nil to not trigger a transition.
    /// Return the from state for a loopback transition to itself.
    func stateToTransitionTo(from state: State, dueTo event: Event) -> State?
    
    func willTransition(from state: State, to newState: State, dueTo event: Event)
    
    func didTransition(from state: State, to newState: State, dueTo event: Event)
}
"""
}

let licenseForGeneratedCode = """
/// Zero-Clause BSD
/// ===============
///
/// Permission to use, copy, modify, and/or distribute this software for
/// any purpose with or without fee is hereby granted.
///
/// THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL
/// WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
/// OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
/// FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
/// DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
/// AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
/// OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

"""
