//
//  TaskBagTests.swift
//
//
//  Created by jsilver on 11/5/23.
//

import XCTest
@testable import Reducer
import Combine

@MainActor
final class TaskBagTests: XCTestCase {
    // MARK: - Property
    
    // MARK: - Lifecycle
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    // MARK: - Test
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
