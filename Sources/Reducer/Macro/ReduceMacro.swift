//
//  ReduceMacro.swift
//
//
//  Created by JSilver on 2023/06/09.
//

@attached(member, names: named(mutator))
@attached(extension)
public macro Reduce() = #externalMacro(module: "Macro", type: "ReduceMacro")
