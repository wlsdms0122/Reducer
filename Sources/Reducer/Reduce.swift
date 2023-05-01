//
//  Reduce.swift
//  
//
//  Created by JSilver on 2023/03/07.
//

import Combine

@MainActor
public protocol Reduce: AnyObject {
    associatedtype Action
    associatedtype Mutation
    associatedtype State
    
    typealias ActionItem = (state: State, action: Action)
    
    var mutator: Mutator<Mutation, State>? { get set }
    var initialState: State { get }
    
    func start(with mutator: Mutator<Mutation, State>) async throws
    
    func mutate(state: State, action: Action) async throws
    func reduce(state: State, mutation: Mutation) -> State
    func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool
}

public extension Reduce {
    var currentState: State { mutator?.state ?? initialState }
    
    func start(with mutator: Mutator<Mutation, State>) async throws {

    }
    
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

open class ProxyReduce<R: Reduce>: Reduce {
    public typealias Action = R.Action
    public typealias Mutation = R.Mutation
    public typealias State = R.State
    
    // MARK: - Property
    /// Mutator in reducer of reduce.
    ///
    /// Before version 1.3.0 of `Reducer`, a crash may occur on iOS 15 when using constrained existential type.
    /// The exact situation is that a closure with constrained existential type is defined as a parameter with the `async` keyword and built with package.
    
    /// The error message is as follows:
    /// ```
    /// dyld[56497]: Symbol not found: (_swift_getExtendedExistentialTypeMetadata)
    ///   Referenced from: '/private/var/containers/Bundle/Application/8919658D-110E-4089-8C34-40AF606B7B8D/crashTest.app/crashTest'
    ///   Expected in: '/usr/lib/swift/libswiftCore.dylib'
    /// ```
    ///
    /// To fix this, replace the constrainted existential type with a generic class.
    public var mutator: Mutator<Mutation, State>?
    public var initialState: State
    
    private let _start: ((Mutator<Mutation, State>) async throws -> Void)?
    private let _mutate: ((State, Action, Mutator<Mutation, State>) async throws -> Void)?
    private let _reduce: ((State, Mutation) -> State)?
    private let _shouldCancel: ((ActionItem, ActionItem) -> Bool)?
    
    // MARK: - Initalizer
    public init(
        initialState: State,
        start: ((Mutator<Mutation, State>) async throws -> Void)? = nil,
        mutate: ((State, Action, Mutator<Mutation, State>) async throws -> Void)? = nil,
        reduce: ((State, Mutation) -> State)? = nil,
        shouldCancel: (((state: State, action: Action), (state: State, action: Action)) -> Bool)? = nil
    ) {
        self.initialState = initialState
        
        self._start = start
        self._mutate = mutate
        self._reduce = reduce
        self._shouldCancel = shouldCancel
    }
    
    convenience init(_ reduce: R) {
        self.init(
            initialState: reduce.initialState,
            start: { mutator in
                reduce.mutator = mutator
                try await reduce.start(with: mutator)
            },
            mutate: { state, action, _ in
                try await reduce.mutate(state: state, action: action)
            },
            reduce: { state, mutation in
                reduce.reduce(state: state, mutation: mutation)
            },
            shouldCancel: { current, upcoming in
                reduce.shouldCancel(current, upcoming)
            }
        )
    }
    
    // MARK: - Lifecycle
    open func start(with mutator: Mutator<Mutation, State>) async throws {
        self.mutator = mutator
        try await _start?(mutator)
    }
    
    open func mutate(state: State, action: Action) async throws {
        guard let mutator else { return }
        try await _mutate?(state, action, mutator)
    }
    
    open func reduce(state: State, mutation: Mutation) -> State {
        _reduce?(state, mutation) ?? state
    }
    
    open func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool {
        _shouldCancel?(current, upcoming) ?? false
    }
    
    // MARK: - Public
    
    // MARK: - Private
}
