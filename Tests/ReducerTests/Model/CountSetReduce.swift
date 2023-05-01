//
//  CountSetReduce.swift
//  
//
//  Created by JSilver on 2023/03/08.
//

import Reducer

class CountSetReduce: Reduce {
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
    var mutator: Mutator<Mutation, State>?
    var initialState: State

    // MARK: - Initializer
    init(initialState: State) {
        self.initialState = initialState
    }

    // MARK: - Lifecycle
    func mutate(state: State, action: Action) async throws {
        switch action {
        case .increase:
            // Increase count after waiting 0.1 sec.
            try await Task.sleep(nanoseconds: 10_000_000)
            mutate(.setCount(state.count + 1))
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

    func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool {
        // Cancel previous action when same action occured.
        current.action == upcoming.action
    }
}
