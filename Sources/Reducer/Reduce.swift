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
    typealias Mutate = (Mutation) -> Void
    
    var mutator: (any Mutator<Mutation, State>)? { get set }
    var initialState: State { get }
    
    func start(with mutator: any Mutator<Mutation, State>) async throws
    
    func mutate(state: State, action: Action) async throws
    func reduce(state: State, mutation: Mutation) -> State
    func shouldCancel(_ current: ActionItem, _ upcoming: ActionItem) -> Bool
}

public extension Reduce {
    var currentState: State { mutator?.state ?? initialState }
    
    func start(with mutator: any Mutator<Mutation, State>) async throws {

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
    public var mutator: (any Mutator<Mutation, State>)? {
        didSet {
            _setMutator?(mutator)
        }
    }
    public var initialState: State
    
    private let _setMutator: (((any Mutator<Mutation, State>)?) -> Void)?
    
    private let _start: ((any Mutator<Mutation, State>) async throws -> Void)?
    private let _mutate: ((State, Action, @escaping Mutate) async throws -> Void)?
    private let _reduce: ((State, Mutation) -> State)?
    private let _shouldCancel: ((ActionItem, ActionItem) -> Bool)?
    
    // MARK: - Initalizer
    public init(
        initialState: State,
        setMutator: (((any Mutator<Mutation, State>)?) -> Void)? = nil,
        start: ((any Mutator<Mutation, State>) async throws -> Void)? = nil,
        mutate: ((State, Action, @escaping Mutate) async throws -> Void)? = nil,
        reduce: ((State, Mutation) -> State)? = nil,
        shouldCancel: (((state: State, action: Action), (state: State, action: Action)) -> Bool)? = nil
    ) {
        self.initialState = initialState
        
        self._setMutator = setMutator
        
        self._start = start
        self._mutate = mutate
        self._reduce = reduce
        self._shouldCancel = shouldCancel
    }
    
    convenience init(_ reduce: R) {
        self.init(
            initialState: reduce.initialState,
            setMutator: { mutator in
                reduce.mutator = mutator
            },
            start: { mutator in
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
    open func start(with mutator: any Mutator<Mutation, State>) async throws {
        self.mutator = mutator
        
        weak var weakMutator = mutator
        try await _start?(weakMutator!)
    }
    
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
    
    // MARK: - Public
    
    // MARK: - Private
}
