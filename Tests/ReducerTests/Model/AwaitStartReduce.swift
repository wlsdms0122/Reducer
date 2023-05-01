//
//  AwaitStartReduce.swift
//  
//
//  Created by JSilver on 2023/03/31.
//

import Foundation
import Reducer

class AwaitStartReduce: Reduce {
    enum Action {
        case empty
    }

    enum Mutation {
        case increase
    }

    struct State {
        var count: Int
    }

    // MARK: - Property
    var mutator: Mutator<Mutation, State>?
    var initialState: State

    // MARK: - Initializer
    init(initialState: State) {
        self.initialState = initialState
    }

    // MARK: - Lifecycle
    func start(with mutator: Mutator<Mutation, State>) async throws {
        try await Task.sleep(nanoseconds: 10_000_000)
        mutator.mutate(.increase)
    }
    
    func mutate(state: State, action: Action) async throws {
        
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state

        switch mutation {
        case .increase:
            state.count += 1
            return state
        }
    }
}
