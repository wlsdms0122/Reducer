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
    
    var initialState: State { get }
    var state: State { get }
    
    var cancellableBag: Set<AnyCancellable> { get set }
    
    func mutate(_ mutation: Mutation)
}

public extension Mutable {
    func callAsFunction(_ mutation: Mutation) {
        mutate(mutation)
    }
}

open class Mutator<Mutation, State>: Mutable {
    // MARK: - Propery
    public let initialState: State
    
    private let _state: () -> State
    public var state: State { _state() }
    
    private let _cancellableBag: UnsafeMutablePointer<Set<AnyCancellable>>
    public var cancellableBag: Set<AnyCancellable> {
        get { _cancellableBag.pointee }
        set { _cancellableBag.pointee = newValue }
    }
    
    private let _mutate: ((Mutation) -> Void)?
    
    // MARK: - Initializer
    public init<M: Mutable>(_ mutator: M) where M.Mutation == Mutation, M.State == State {
        let initialState = mutator.initialState
        self.initialState = initialState
        
        self._state = { [weak mutator] in mutator?.state ?? initialState }
        
        self._cancellableBag = withUnsafeMutablePointer(to: &mutator.cancellableBag) { $0 }
        
        self._mutate = { [weak mutator] mutation in mutator?.mutate(mutation)}
    }
    
    // MARK: - Lifecycle
    open func mutate(_ mutation: Mutation) {
        _mutate?(mutation)
    }
    
    // MARK: - Public
    
    // MARK: - Private
}
