//
//  Reducer.swift
//
//
//  Created by JSilver on 2023/03/07.
//

import Foundation
import Combine

final class TaskBag<Item> {
    struct TaskItem: Hashable {
        // MARK: - Property
        let item: Item
        let task: Task<Void, Never>
        
        // MARK: - Initalizer
        init(_ item: Item, with task: Task<Void, Never>) {
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
        
        Task {
            await item.task.value
            items.remove(item)
        }
    }
    
    func forEach(_ body: (TaskItem) throws -> Void) rethrows {
        try items.forEach(body)
    }
    
    // MARK: - Private
    
    deinit {
        items.forEach { $0.cancel() }
    }
}

open class Reducer<R: Reduce>: ObservableObject, Mutable {
    public typealias Action = R.Action
    public typealias Mutation = R.Mutation
    public typealias State = R.State
    
    // MARK: - Property
    @Published
    public private(set) var state: State
    
    private let reduce: ProxyReduce<R>
    
    private let taskBag = TaskBag<R.Action>()
    
    // MARK: - Initalizer
    public init(proxy reduce: ProxyReduce<R>) {
        self.state = reduce.initialState
        self.reduce = reduce
        
        reduce.mutator = Mutator(self, initialState: reduce.initialState)
        Task {
            // Start reduce with mutator.
            try? await reduce.start()
        }
    }
    
    public convenience init(_ reduce: R) {
        self.init(proxy: ProxyReduce(reduce))
    }
    
    // MARK: - Lifecycle
    open func mutate(_ mutation: Mutation) {
        // Reduce state from mutation.
        state = reduce(state: state, mutation: mutation)
    }
    
    // MARK: - Public
    open func action(_ action: Action) {
        let reduce = reduce
        
        // Traversing the task and deciding to cancel it.
        taskBag.forEach { task in
            guard reduce.shouldCancel(task.item, action) else { return }
            task.cancel()
        }
        
        // Store task into bag.
        taskBag.store(.init(
            action,
            with: Task { @MainActor in
                // Mutate state from action.
                try? await reduce.mutate(action: action)
            }
        ))
    }
}
