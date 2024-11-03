//
//  TestError.swift
//  Reducer
//
//  Created by JSilver on 11/3/24.
//

import Foundation

struct TestError: Error {
    let description: String
    
    init(_ description: String) {
        self.description = description
    }
}
