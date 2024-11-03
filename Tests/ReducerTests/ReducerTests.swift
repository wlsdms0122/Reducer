//
//  Reducer.swift
//
//
//  Created by JSilver on 2023/03/07.
//

import XCTest
@testable import Reducer
import Combine

@MainActor
final class ReducerTests: XCTestCase {
    // MARK: - Property
    
    // MARK: - Lifecycle
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    // MARK: - Test
    func test_that_count_increases_when_receiving_increase_action() async throws {
        // Given
        let reducer = Reducer(
            CountIncreaseReduce(initialState: .init(
                count: 0
            ))
        )
        
        // When
        Task {
            reducer.action(.increase)
            reducer.action(.increase)
        }
        
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 1, 2])
    }
    
    func test_that_count_does_not_mutate_when_receiving_same_action_twice() async throws {
        // Given
        let reducer = Reducer(
            CountSetReduce(initialState: .init(
                count: 0
            ))
        )
        
        // When
        Task {
            reducer.action(.increase)
            reducer.action(.increase)
        }
        
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 1])
    }
    
    func test_that_all_action_cancelled_when_reducer_deinit() async throws {
        // Given
        var reducer: Reducer<CountIncreaseReduce>? = Reducer(
            CountIncreaseReduce(initialState: .init(
                count: 0
            ))
        )
        
        let state = reducer!.$state
        
        // When
        Task {
            reducer?.action(.increase)
            reducer = nil
        }
        
        let result = try await wait(
            state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0])
    }
    
    func test_that_count_increases_when_mutate_in_start() async throws {
        // Given
        let reducer = Reducer(TimerReduce(
            initialState: .init(count: 0)
        ))
        
        // When
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertGreaterThan(result.last ?? 0, 0)
    }
    
    func test_that_count_increases_when_await_mutate_in_start() async throws {
        // Given
        let reducer = Reducer(AwaitStartReduce(
            initialState: .init(count: 0)
        ))
        
        // When
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 1])
    }
    
    func test_that_reducer_should_be_able_to_assign_proxy_reduce() async throws {
        // Given
        var reducer = Reducer(CountIncreaseReduce(
            initialState: .init(count: 0)
        ))
        
        reducer = Reducer<CountIncreaseReduce>(proxy: .init(
            initialState: .init(count: 0),
            mutate: { state, action, mutate in
                switch action {
                case .increase:
                    try await Task.sleep(nanoseconds: 10_000_000)
                    mutate(.increase)
                }
            },
            reduce: { state, mutation in
                var state = state
                
                switch mutation {
                case .increase:
                    state.count += 10
                    return state
                }
            }
        ))
        
        // When
        Task {
            reducer.action(.increase)
        }
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 10])
    }
    
    func test_that_initial_count_is_100_when_proxy_set_initial_count() async throws {
        // Given
        let reducer = Reducer<CountIncreaseReduce>(proxy: .init(
            initialState: .init(
                count: 100
            )
        ))
        
        // When
        let result = try await wait(
            reducer.$state.map(\.count),
            count: 1
        )
        
        // Then
        XCTAssertEqual(result, [100])
    }
    
    func test_that_count_increases_when_proxy_receiving_increase_action() async throws {
        // Given
        let reducer = Reducer<CountIncreaseReduce>(proxy: .init(
            initialState: .init(count: 0),
            mutate: { state, action, mutate in
                switch action {
                case .increase:
                    try await Task.sleep(nanoseconds: 10_000_000)
                    mutate(.increase)
                }
            },
            reduce: { state, mutation in
                var state = state
                
                switch mutation {
                case .increase:
                    state.count += 1
                    return state
                }
            }
        ))
        
        // When
        Task {
            reducer.action(.increase)
        }
        
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 1])
    }
    
    func test_that_count_increases_10_when_proxy_receiving_increase_action() async throws {
        // Given
        let reducer = Reducer<CountIncreaseReduce>(proxy: .init(
            initialState: .init(count: 0),
            mutate: { state, action, mutate in
                switch action {
                case .increase:
                    try await Task.sleep(nanoseconds: 10_000_000)
                    mutate(.increase)
                }
            },
            reduce: { state, mutation in
                var state = state
                
                switch mutation {
                case .increase:
                    state.count += 10
                    return state
                }
            }
        ))
        
        // When
        Task {
            reducer.action(.increase)
            reducer.action(.increase)
        }
        
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 10, 20])
    }
    
    func test_that_count_does_not_mutate_when_proxy_same_action_twice() async throws {
        // Given
        let reducer = Reducer<CountIncreaseReduce>(proxy: .init(
            initialState: .init(count: 0),
            mutate: { state, action, mutate in
                switch action {
                case .increase:
                    try await Task.sleep(nanoseconds: 10_000_000)
                    mutate(.increase)
                }
            },
            reduce: { state, mutation in
                var state = state
                
                switch mutation {
                case .increase:
                    state.count += 1
                    return state
                }
            },
            shouldCancel: { current, upcoming in
                current == upcoming
            }
        ))
        
        // When
        Task {
            reducer.action(.increase)
            reducer.action(.increase)
        }
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 1])
    }
    
    func test_that_count_increases_when_proxy_mutate_in_start() async throws {
        // Given
        var cancellable: AnyCancellable? = nil
        let reducer = Reducer<TimerReduce>(proxy: .init(
            initialState: .init(count: 0),
            start: { mutate in
                cancellable = Timer.publish(every: 0.1, on: .main, in: .default)
                    .autoconnect()
                    .sink { _ in mutate(.increase) }
            },
            reduce: { state, mutation in
                var state = state
                
                switch mutation {
                case .increase:
                    state.count += 1
                    return state
                }
            }
        ))
        
        // When
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertGreaterThan(result.last ?? 0, 0)
    }
    
    func test_that_reducer_can_assign_proxy_inherited_reduce() async throws {
        // Given
        let reducer = Reducer<CountIncreaseReduce>(
            proxy: ProxyCountIncrease10Reduce(initialState: .init(
                count: 0
            ))
        )
        
        // When
        Task {
            reducer.action(.increase)
        }
        let result = try await wait(
            reducer.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 10])
    }
    
    func test_that_count_increases_when_error_is_thrown_in_mutation() async throws {
        // Given
        let sut = Reducer(ErrorReduce())
        
        // When
        Task {
            sut.action(.occurError(TestError("increase count")))
        }
        
        let result = try await wait(
            sut.$state.map(\.count),
            timeout: 1
        )
        
        // Then
        XCTAssertEqual(result, [0, 1])
    }
}
