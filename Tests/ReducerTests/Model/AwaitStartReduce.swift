//
//  AwaitStartReduce.swift
//  
//
//  Created by JSilver on 2023/03/31.
//

import Foundation
import Reducer

@Reduce
@MainActor
class AwaitStartReduce {
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
    let initialState: State

    // MARK: - Initializer
    init(initialState: State) {
        self.initialState = initialState
    }

    // MARK: - Lifecycle
    func start() async throws {
        try await Task.sleep(nanoseconds: 10_000_000)
        mutate(.increase)
    }
    
    func mutate(action: Action) async throws {
        
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
