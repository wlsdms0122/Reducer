//
//  ReduceMacro.swift
//
//
//  Created by JSilver on 2023/06/09.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ReduceMacro: ConformanceMacro, MemberMacro {
    public static func expansion<
        Declaration: DeclGroupSyntax,
        Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingConformancesOf declaration: Declaration,
        in context: Context
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [("Reduce", nil)]
    }
    
    public static func expansion<
        Declaration: DeclGroupSyntax,
        Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingMembersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        let mutatorSyntax = DeclSyntax("""
        var mutator: Mutator<Mutation, State>?
        """)
        
        return [
            mutatorSyntax
        ]
    }
}
