import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct WriteTimeToSectionMacro: DeclarationMacro {
    
    public static func expansion(
        of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let argumentList = node.arguments
        var time: String = ""
        var priority: String = "5"
        var repeatable: String = "false"
        var async: String = "false"
        var functionBody: String = ""
        var signature: String?
        
        for argument in argumentList {
            switch argument.label?.text {
            case "time":
                // RheaEvent type
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    time = memberAccess.declName.baseName.text
                }
                // String type
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let hostValue = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text {
                    time = hostValue
                }
            case "priority":
                if let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self) {
                    priority = intLiteral.literal.text
                } else if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    let memberName = memberAccess.declName.baseName.text
                    switch memberName {
                    case "veryLow": priority = "1"
                    case "low": priority = "3"
                    case "high": priority = "7"
                    case "veryHigh": priority = "9"
                    default: priority = "5"
                    }
                }
            case "repeatable":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    repeatable = boolLiteral.literal.text
                }
            case "async":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    async = boolLiteral.literal.text
                }
            case "func":
                if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                    functionBody = closureExpr.statements.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let sig = closureExpr.signature {
                        signature = sig.description
                    }
                }
            default:
                break
            }
        }
        let isGlobal = context.lexicalContext.isEmpty
        let staticString = isGlobal ? "" : "static "
        let infoName = "\(context.makeUniqueName("rhea"))"
        
        let declarationString = """
            @_used 
            @_section("__DATA,__rheatime")
            \(staticString)let \(infoName): RheaRegisterInfo = (
                "rhea.\(time).\(priority).\(repeatable).\(async)",
                { \(signature ?? "context in")
                    \(functionBody)
                }
            )
            """
        return [DeclSyntax(stringLiteral: declarationString)]
    }
}


@main
struct RheaTimePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WriteTimeToSectionMacro.self
    ]
}
