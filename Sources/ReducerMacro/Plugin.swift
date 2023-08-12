//
//  Plugin.swift
//
//
//  Created by JSilver on 2023/06/09.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ReduceMacro.self
    ]
}
