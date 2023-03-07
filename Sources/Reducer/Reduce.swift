//
//  Reduce.swift
//  
//
//  Created by JSilver on 2023/03/07.
//

import Foundation

// MARK: - Mutator
@MainActor
public protocol Mutator<Mutation>: AnyObject {
    associatedtype Mutation
    
    func mutate(_ mutation: Mutation)
}

public extension Mutator {
    func callAsFunction(_ mutation: Mutation) {
        mutate(mutation)
    }
}

// MARK: - Reduce
@MainActor
public protocol Reduce: AnyObject {
    associatedtype Action
    associatedtype Mutation
    associatedtype State
    
    typealias ActionItem = (state: State, action: Action)
    typealias Mutate = (Mutation) -> Void
    
    var mutator: (any Mutator<Mutation>)? { get set }
    var initialState: State { get }
    
    func mutate(state: State, action: Action) async throws
    func reduce(state: State, mutation: Mutation) -> State
    func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool
}

public extension Reduce {
    func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool {
        false
    }
    
    func mutate(_ mutation: Mutation) {
        mutator?(mutation)
    }
}

extension Reduce {
    func callAsFunction(state: State, mutation: Mutation) -> State {
        reduce(state: state, mutation: mutation)
    }
}

// MARK: - ProxyReduce
open class ProxyReduce<R: Reduce>: Reduce {
    public typealias Action = R.Action
    public typealias Mutation = R.Mutation
    public typealias State = R.State
    
    // MARK: - Property
    public weak var mutator: (any Mutator<Mutation>)? {
        didSet {
            reduce?.mutator = mutator
        }
    }
    public var initialState: State
    
    private let reduce: R?
    private let _mutate: ((State, Action, @escaping Mutate) async throws -> Void)?
    private let _reduce: ((State, Mutation) -> State)?
    private let _shouldCancel: ((ActionItem, ActionItem) -> Bool)?
    
    // MARK: - Initalizer
    public init(_ reduce: R) {
        self.initialState = reduce.initialState
        self.reduce = reduce
        
        self._mutate = { state, action, _ in
            try await reduce.mutate(state: state, action: action)
        }
        self._reduce = { state, mutation in
            reduce.reduce(state: state, mutation: mutation)
        }
        self._shouldCancel = { current, upcoming in
            reduce.shouldCancel(current, upcoming)
        }
    }
    
    public init(
        initialState: State,
        mutate: ((State, Action, @escaping Mutate) async throws -> Void)? = nil,
        reduce: ((State, Mutation) -> State)? = nil,
        shouldCancel: (((state: State, action: Action), (state: State, action: Action)) -> Bool)? = nil
    ) {
        self.initialState = initialState
        self.reduce = nil
        
        self._mutate = mutate
        self._reduce = reduce
        self._shouldCancel = shouldCancel
    }
    
    // MARK: - Public
    open func mutate(state: State, action: Action) async throws {
        try await _mutate?(
            state,
            action
        ) { [weak self] in
            self?.mutate($0)
        }
    }
    
    open func reduce(state: State, mutation: Mutation) -> State {
        _reduce?(state, mutation) ?? state
    }
    
    open func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool {
        _shouldCancel?(current, upcoming) ?? false
    }
}
