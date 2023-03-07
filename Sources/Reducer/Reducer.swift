//
//  Reducer.swift
//
//
//  Created by JSilver on 2023/03/07.
//

import Foundation

@MainActor
final class TaskBag<Item> {
    struct TaskItem: Hashable {
        // MARK: - Property
        let item: Item
        let task: Task<Void?, Never>
        
        // MARK: - Initalizer
        init(_ item: Item, with task: Task<Void?, Never>) {
            self.item = item
            self.task = task
        }
        
        // MARK: - Lifecycle
        func hash(into hasher: inout Hasher) {
            hasher.combine(task)
        }
        
        // MARK: - Public
        static func ==(lhs: TaskItem, rhs: TaskItem) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        func cancel() {
            guard !task.isCancelled else { return }
            task.cancel()
        }
        
        // MARK: - Private
    }
    
    // MARK: - Property
    private var items = Set<TaskItem>()
    
    // MARK: - Public
    func store(_ item: TaskItem) {
        items.insert(item)
        
        Task { [weak self] in
            await item.task.value
            self?.remove(item)
        }
    }
    
    func forEach(_ body: (TaskItem) throws -> Void) rethrows {
        try items.forEach(body)
    }
    
    func remove(_ item: TaskItem) {
        items.remove(item)
    }
    
    // MARK: - Private
    
    deinit {
        items.forEach { $0.cancel() }
    }
}

open class Reducer<R: Reduce>: ObservableObject, Mutator {
    public typealias Action = R.Action
    public typealias Mutation = R.Mutation
    public typealias State = R.State
    
    // MARK: - Property
    @Published
    public private(set) var state: State
    
    private var reduce: ProxyReduce<R>
    private let taskBag = TaskBag<R.ActionItem>()
    
    // MARK: - Initalizer
    public init(_ reduce: R) {
        self.state = reduce.initialState
        self.reduce = ProxyReduce(reduce)
        
        reduce.mutator = self
    }
    
    public init(proxy reduce: ProxyReduce<R>) {
        self.state = reduce.initialState
        self.reduce = reduce
        
        reduce.mutator = self
    }
    
    // MARK: - Lifecycle
    public func mutate(_ mutation: Mutation) {
        Task {
            // Reduce state from mutation.
            // Run task on main actor context.
            reduce(mutation: mutation)
        }
    }
    
    // MARK: - Public
    public func action(_ action: Action) {
        let reduce = reduce
        let state = state
        
        taskBag.forEach {
            guard reduce.shouldCancel($0.item, (state, action)) else { return }
            $0.cancel()
        }
        
        // Store task into bag.
        taskBag.store(.init(
            (state, action),
            with: Task {
                // Mutate state from action.
                try? await reduce.mutate(
                    state: state,
                    action: action
                )
            }
        ))
    }
    
    // MARK: - Private
    private func reduce(mutation: Mutation) {
        state = reduce(state: state, mutation: mutation)
    }
}

public extension Reducer {
    convenience init(
        initialState: State,
        mutate: ((State, Action, @escaping R.Mutate) async throws -> Void)? = nil,
        reduce: ((State, Mutation) -> State)? = nil,
        shouldCancel: ((R.ActionItem, R.ActionItem) -> Bool)? = nil
    ) {
        self.init(proxy: .init(
            initialState: initialState,
            mutate: mutate,
            reduce: reduce,
            shouldCancel: shouldCancel
        ))
    }
}
