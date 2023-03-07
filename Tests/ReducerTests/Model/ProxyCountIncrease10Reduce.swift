//
//  ProxyCountIncrease10Reduce.swift
//  
//
//  Created by JSilver on 2023/03/07.
//

import Reducer

class ProxyCountIncrease10Reduce: ProxyReduce<CountIncreaseReduce> {
    override func mutate(state: State, action: Action) async throws {
        switch action {
        case .increase:
            try await Task.sleep(nanoseconds: 100_000_000)
            mutator?(.increase)
        }
    }
    
    override func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .increase:
            state.count += 10
            return state
        }
    }
}
