//
//  TimerReduce.swift
//  
//
//  Created by JSilver on 2023/03/31.
//

import Foundation
import Reducer
import Combine

@Reduce
@MainActor
class TimerReduce {
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
    
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Initializer
    init(initialState: State) {
        self.initialState = initialState
    }

    // MARK: - Lifecycle
    func start() async throws {
        cancellableBag.removeAll()
        
        Timer.publish(every: 0.1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in self?.mutate(.increase) }
            .store(in: &cancellableBag)
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
