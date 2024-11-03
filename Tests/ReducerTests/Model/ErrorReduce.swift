//
//  ErrorReduce.swift
//  Reducer
//
//  Created by JSilver on 11/3/24.
//

import Foundation
import Reducer

@Reduce
@MainActor
class ErrorReduce {
    enum Action {
        case occurError(any Error)
    }
    
    enum Mutation {
        case setCount(Int)
    }
    
    struct State {
        var count: Int
    }
    
    let initialState: State
    
    init() {
        self.initialState = State(
            count: 0
        )
    }
    
    func error(_ error: any Error, action: Action) async {
        mutate(.setCount(currentState.count + 1))
    }
    
    func mutate(action: Action) async throws {
        switch action {
        case let .occurError(error):
            throw error
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
}
