//
//  ReduceMacro.swift
//
//
//  Created by JSilver on 2023/06/09.
//

@attached(member, names: named(mutator))
@attached(extension, conformances: Reduce)
public macro Reduce() = #externalMacro(module: "ReducerMacro", type: "ReduceMacro")
