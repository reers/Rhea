import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros
import RheaTimeMacroExpansion

public struct WriteTimeToSectionMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try RheaMacroExpansion.expandRhea(of: node, in: context)
    }
}

public struct RheaLoad: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try RheaMacroExpansion.expandFixedTimeWrapper(of: node, in: context, time: "load")
    }
}

public struct RheaPremain: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try RheaMacroExpansion.expandFixedTimeWrapper(of: node, in: context, time: "premain")
    }
}

public struct RheaAppDidFinishLaunching: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try RheaMacroExpansion.expandFixedTimeWrapper(
            of: node,
            in: context,
            time: "appDidFinishLaunching"
        )
    }
}

@main
struct RheaTimePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WriteTimeToSectionMacro.self,
        RheaLoad.self,
        RheaPremain.self,
        RheaAppDidFinishLaunching.self
    ]
}
