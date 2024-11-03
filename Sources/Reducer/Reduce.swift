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
    
    var mutator: Mutator<Mutation, State>? { get set }
    var initialState: State { get }
    
    func start() async throws
    func error(_ error: any Error, action: Action) async

    func mutate(action: Action) async throws
    func reduce(state: State, mutation: Mutation) -> State
    
    func shouldCancel(_ current: Action, _ upcoming: Action) -> Bool
}

public extension Reduce {
    var currentState: State { mutator?.state ?? initialState }
    
    func start() async throws { }
    
    func error(_ error: any Error, action: Action) async { }
    
    func shouldCancel(_ current: Action, _ upcoming: Action) -> Bool {
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
    private var _mutator: UnsafeMutablePointer<Mutator<Mutation, State>?> = .allocate(capacity: 1)
    public var mutator: Mutator<Mutation, State>? {
        get {
            _mutator.pointee
        }
        set {
            _mutator.pointee = newValue
        }
    }
    private var isMutatorAllocated: Bool = true
    
    public var initialState: State
    
    private let _start: ((@escaping (Mutation) -> Void) async throws -> Void)?
    private let _error: ((@escaping (Mutation) -> Void, any Error, Action) async -> Void)?
    private let _mutate: ((State, Action, @escaping (Mutation) -> Void) async throws -> Void)?
    private let _reduce: ((State, Mutation) -> State)?
    private let _shouldCancel: ((Action, Action) -> Bool)?
    
    // MARK: - Initalizer
    public init( 
        initialState: State,
        start: ((@escaping (Mutation) -> Void) async throws -> Void)? = nil,
        error: ((@escaping (Mutation) -> Void, any Error, Action) async -> Void)? = nil,
        mutate: ((State, Action, @escaping (Mutation) -> Void) async throws -> Void)? = nil,
        reduce: ((State, Mutation) -> State)? = nil,
        shouldCancel: ((Action, Action) -> Bool)? = nil
    ) {
        self.initialState = initialState
        
        self._start = start
        self._error = error
        self._mutate = mutate
        self._reduce = reduce
        self._shouldCancel = shouldCancel
    }
    
    convenience init(_ reduce: R) {
        self.init(
            initialState: reduce.initialState,
            start: { _ in
                try await reduce.start()
            },
            error: { _, error, action in
                await reduce.error(error, action: action)
            },
            mutate: { _, action, _ in
                try await reduce.mutate(action: action)
            },
            reduce: { state, mutation in
                reduce.reduce(state: state, mutation: mutation)
            },
            shouldCancel: { current, upcoming in
                reduce.shouldCancel(current, upcoming)
            }
        )
        
        // Set flag to false to indicate mutator pointer deallocated.
        _mutator.deallocate()
        isMutatorAllocated = false
        
        _mutator = withUnsafeMutablePointer(to: &reduce.mutator) { $0 }
    }
    
    // MARK: - Lifecycle
    open func start() async throws {
        try await _start?({ [weak self] mutation in self?.mutator?(mutation) })
    }
    
    public func error(_ error: any Error, action: Action) async {
        await _error?({ [weak self] mutation in self?.mutator?(mutation) }, error, action)
    }
    
    open func mutate(action: Action) async throws {
        try await _mutate?(currentState, action, { [weak self] mutation in self?.mutator?(mutation) })
    }
    
    open func reduce(state: State, mutation: Mutation) -> State {
        _reduce?(state, mutation) ?? state
    }
    
    open func shouldCancel(_ current: Action, _ upcoming: Action) -> Bool {
        _shouldCancel?(current, upcoming) ?? false
    }
    
    // MARK: - Public
    
    // MARK: - Private
    
    deinit {
        if isMutatorAllocated {
            // Deallocate pointer when mutator allocated.
            _mutator.deallocate()
        }
    }
}
