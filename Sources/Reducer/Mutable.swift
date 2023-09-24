//
//  Mutable.swift
//  
//
//  Created by JSilver on 2023/03/31.
//

import Combine

@MainActor
public protocol Mutable<Mutation, State>: AnyObject {
    associatedtype Mutation
    associatedtype State
    
    var state: State { get }
    
    func mutate(_ mutation: Mutation)
}

public extension Mutable {
    func callAsFunction(_ mutation: Mutation) {
        mutate(mutation)
    }
}

open class Mutator<Mutation, State>: Mutable {
    // MARK: - Propery
    private let _state: () -> State
    public var state: State { _state() }
    
    private let _mutate: (Mutation) -> Void
    
    // MARK: - Initializer
    public init<M: Mutable>(_ mutator: M, initialState: State) where M.Mutation == Mutation, M.State == State {
        self._state = { [weak mutator] in mutator?.state ?? initialState }
        
        self._mutate = { [weak mutator] mutation in mutator?.mutate(mutation)}
    }
    
    // MARK: - Lifecycle
    open func mutate(_ mutation: Mutation) {
        _mutate(mutation)
    }
    
    // MARK: - Public
    
    // MARK: - Private
}
