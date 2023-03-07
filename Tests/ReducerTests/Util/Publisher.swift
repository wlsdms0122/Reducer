//
//  XCTestCase+Publisher.swift
//  
//
//  Created by JSilver on 2023/03/07.
//

import XCTest
import Combine

extension XCTestCase {
    func wait<P: Publisher>(
        _ publisher: P,
        count: Int? = nil,
        timeout: TimeInterval = 5
    ) async throws -> [P.Output] {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                // Collect elements.
                var values: [P.Output] = []
                var isCompleted: Bool = false
                let cancellable = publisher.prefix(count ?? .max)
                    .sink { completion in
                        if case let .failure(error) = completion {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: values)
                        }
                        
                        isCompleted = true
                    } receiveValue: { value in
                        values.append(value)
                    }
                
                // Wait until timed out.
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                
                guard !isCompleted else { return }
                // Cancel publisher when timed out.
                cancellable.cancel()
                // Return collected elements until timed out.
                continuation.resume(returning: values)
            }
        }
    }
}
