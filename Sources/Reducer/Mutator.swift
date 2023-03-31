//
//  Mutator.swift
//  
//
//  Created by JSilver on 2023/03/31.
//

import Combine

@MainActor
public protocol Mutator<Mutation, State>: AnyObject {
    associatedtype Mutation
    associatedtype State
    
    var state: State { get }
    var initialState: State { get }
    
    var cancellableBag: Set<AnyCancellable> { get set }
    
    func mutate(_ mutation: Mutation)
}

public extension Mutator {
    func callAsFunction(_ mutation: Mutation) {
        mutate(mutation)
    }
}

final class ProxyMutator<M: Mutator>: Mutator {
    typealias Mutation = M.Mutation
    typealias State = M.State
    
    // MARK: - Propery
    private let _state: () -> State
    var state: State { _state() }
    let initialState: State
    
    private let _cancellableBag: UnsafeMutablePointer<Set<AnyCancellable>>
    var cancellableBag: Set<AnyCancellable> {
        get {
            _cancellableBag.pointee
        }
        set {
            _cancellableBag.pointee = newValue
        }
    }
    
    private let _mutate: ((Mutation) -> Void)?
    
    // MARK: - Initializer
    init(_ mutator: M) {
        let initialState = mutator.initialState
        
        self.initialState = initialState
        self._state = { [weak mutator] in mutator?.state ?? initialState }
        
        self._cancellableBag = withUnsafeMutablePointer(to: &mutator.cancellableBag) { $0 }
        
        self._mutate = { [weak mutator] mutation in mutator?.mutate(mutation)}
    }
    
    // MARK: - Lifecycle
    func mutate(_ mutation: Mutation) {
        _mutate?(mutation)
    }
    
    // MARK: - Public
    
    // MARK: - Private
}
