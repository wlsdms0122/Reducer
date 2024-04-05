//
//  ReduceMacroTests.swift
//
//
//  Created by JSilver on 2023/06/09.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import ReducerMacro

let testMacros: [String: Macro.Type] = [
    "Reduce": ReduceMacro.self,
]

final class ReduceMacroTests: XCTestCase {
    // MARK: - Property
    
    // MARK: - Lifecycle
    override func setUp() {
        
    }
    
    override func tearDown() {
        
    }
    
    // MARK: - Test
    func test_that_reduce_macro_expand_source() {
        assertMacroExpansion(
            """
            @Reduce
            class Test {
            
            }
            """,
            expandedSource: """
            class Test {

                var mutator: Mutator<Mutation, State>?

            }

            extension Test: Reduce {
            }
            """,
            macros: testMacros
        )
    }
}
