//
//  TaskBagTests.swift
//
//
//  Created by jsilver on 11/5/23.
//

import XCTest
@testable import Reducer
import Combine

final class TaskBagTests: XCTestCase {
    // MARK: - Property
    
    // MARK: - Lifecycle
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    // MARK: - Test
    func test_that_task_bag_remove_complete_task() async throws {
        // Given
        let taskBag = TaskBag<Int>()
        
        taskBag.store(.init(
            1,
            with: Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        ))
        taskBag.store(.init(
            2,
            with: Task {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        ))
        
        let count = taskBag.items.count
        
        // When
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Then
        XCTAssertEqual(count, 2)
        XCTAssertEqual(taskBag.items.count, 1)
    }
    
    func test_that_task_bag_cancel_all_task_when_deinit() async throws {
        // Given
        let expectation = expectation(description: "")
        
        var taskBag: TaskBag? = TaskBag<Int>()
        
        // When
        taskBag?.store(.init(
            1,
            with: Task {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    expectation.fulfill()
                }
            }
        ))
        
        taskBag = nil
        
        // Then
        await fulfillment(of: [expectation], timeout: 3)
    }
}
