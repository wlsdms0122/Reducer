//
//  ReduceMacro.swift
//
//
//  Created by JSilver on 2023/06/09.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ReduceMacro: ExtensionMacro, MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        let extenstion: DeclSyntax = """
         extension \(type.trimmed): Equatable { }
         """
        
        return [extenstion.cast(ExtensionDeclSyntax.self)]
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
