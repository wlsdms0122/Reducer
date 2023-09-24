//
//  CountSetReduce.swift
//  
//
//  Created by JSilver on 2023/03/08.
//

import Reducer

@Reduce
@MainActor
class CountSetReduce {
    enum Action {
        case increase
    }

    enum Mutation {
        case setCount(Int)
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
            mutate(.setCount(currentState.count + 1))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state

        switch mutation {
        case let .setCount(count):
            state.count = count
            return state
        }
    }

    func shouldCancel(_ current: Action, _ upcoming: Action) -> Bool {
        // Cancel previous action when same action occured.
        current == upcoming
    }
}
