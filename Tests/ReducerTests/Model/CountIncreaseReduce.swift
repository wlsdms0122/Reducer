//
//  CountIncreaseReduce.swift
//  
//
//  Created by JSilver on 2023/03/07.
//

import Reducer

@Reduce
@MainActor
class CountIncreaseReduce {
    enum Action {
        case increase
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
    func mutate(action: Action) async throws {
        switch action {
        case .increase:
            // Increase count after waiting 0.1 sec.
            try await Task.sleep(nanoseconds: 10_000_000)
            mutate(.increase)
        }
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
