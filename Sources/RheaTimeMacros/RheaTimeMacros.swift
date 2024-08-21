import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public enum MacroExpansionError: Error {
    case invalidArguments
}

public struct WriteSectionMacro: ExpressionMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        let argumentList = node.argumentList
        var time: String = ""
        var priority: String = ""
        var repeatable: String = ""
        var functionBody: String = ""
        var signature: String?
        
        for argument in argumentList {
            switch argument.label?.text {
            case "time":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    time = memberAccess.declName.baseName.text
                }
            case "priority":
                if let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self) {
                    priority = intLiteral.literal.text
                }
            case "repeatable":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    repeatable = boolLiteral.literal.text
                }
            case "function":
                if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                    functionBody = closureExpr.statements.description
                    if let sig = closureExpr.signature {
                        signature = sig.description
                    }
                }
            default:
                break
            }
        }
        
//        let uniqueIdentifier = "rheaFunc_\(context.makeUniqueName("rhea"))"
        let funcName = context.makeUniqueName("rheaFunc").text
        let infoName = context.makeUniqueName("rhea").text
        
        let expansionString = """
                @_used
                @_section("__DATA,__rheatime")
                let \(infoName): RheaRegisterInfo = ("rhea.\(time).\(priority).\(repeatable)", { \(signature ?? "context in") \(functionBody)
                })
                """
        return ExprSyntax(stringLiteral: expansionString)
    }
}

@main
struct RheaTimePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WriteSectionMacro.self
    ]
}
