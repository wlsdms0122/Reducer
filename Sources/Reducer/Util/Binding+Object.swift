//
//  Binding+Object.swift
//
//
//  Created by JSilver on 2023/02/23.
//

import SwiftUI

public extension Binding {
    static func object<T: ObservableObject>(
        _ object: T,
        path: ReferenceWritableKeyPath<T, Value>
    ) -> Binding<Value> {
        .init(
            get: { object[keyPath: path] },
            set: { object[keyPath: path] = $0 }
        )
    }
    
    static func object<T: ObservableObject>(
        _ object: T,
        path: KeyPath<T, Value>,
        set: @escaping (Value) -> Void
    ) -> Binding<Value> {
        .init(
            get: { object[keyPath: path] },
            set: { set($0) }
        )
    }
}
