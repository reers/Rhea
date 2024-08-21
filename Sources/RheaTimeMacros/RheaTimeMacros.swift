import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public enum MacroExpansionError: Error {
    case invalidArguments
}

public struct WriteSectionMacro: ExpressionMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        guard let closure = node.trailingClosure else {
            throw MacroExpansionError.invalidArguments
        }
        let argumentList = node.arguments
        
        var time: String = ""
        var priority: String = ""
        var repeatable: String = ""
        
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
            default:
                break
            }
        }
        
        let funcName = context.makeUniqueName("rheaFunc").text
        let infoName = context.makeUniqueName("rhea").text
        
        let expansionString = """
            @_used
            @_section("__DATA,__rheatime")
            let \(infoName): RheaRegisterInfo = ("rhea.\(time).\(priority).\(repeatable)", \(funcName))
            let \(funcName): @convention(c) (RheaContext) -> Void = { context in
                \(closure.statements)
            }
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
